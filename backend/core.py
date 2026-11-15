"""Core plumbing shared by all sections: async processes, debounced
commands, polling, KCM / command hand-off. Owned by the main agent."""
from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import QProcess, QSettings, QTimer, Slot
from PySide6.QtGui import QIcon

from .util import has, kread, run, spawn


class CoreMixin:
    def _init_core(self):
        self._settings = QSettings()
        self._kcms: set[str] | None = None
        self._icon_base = kread("kdeglobals", "Icons", "Theme", "breeze").removesuffix("-dark") or "breeze"

        # Coalesce rapid slider changes into one command per key
        self._pending = {}
        self._debounce = QTimer(self, singleShot=True, interval=50)
        self._debounce.timeout.connect(self._flush_pending)

        # Sections register cheap async status checks here (see _poll_tick)
        self._pollers = []
        self._poll = QTimer(self, interval=5000)
        self._poll.timeout.connect(self._poll_tick)

    def _start_core(self):
        """Called after every section has initialised."""
        self._poll.start()
        self._poll_tick()

    # ---------------------------------------------------- async process helper
    def _async(self, args, callback=None, timeout_ms: int = 8000):
        """Run args without blocking the GUI. callback(ok: bool, stdout: str)."""
        if not has(args[0]):
            if callback:
                callback(False, "")
            return
        p = QProcess(self)
        state = {"done": False}

        def finished(code, _status):
            state["done"] = True
            try:
                out = bytes(p.readAllStandardOutput()).decode(errors="replace")
                p.deleteLater()
            except RuntimeError:   # QProcess already destroyed (app is closing)
                return
            if callback:
                callback(code == 0, out)

        def kill():
            if not state["done"]:
                try:
                    p.kill()
                except RuntimeError:
                    pass

        p.finished.connect(finished)
        p.start(args[0], [str(a) for a in args[1:]])
        QTimer.singleShot(timeout_ms, kill)

    # ---------------------------------------------------- debounced commands
    def _later(self, key: str, args: list):
        """Run args ~50 ms from now; a newer call with the same key replaces it."""
        self._pending[key] = args
        self._debounce.start()

    def _flush_pending(self):
        for args in self._pending.values():
            spawn(args)
        self._pending.clear()

    # ---------------------------------------------------- polling
    def _poll_tick(self):
        for fn in self._pollers:
            fn()

    # ---------------------------------------------------- icon theme (used by IconProvider)
    def icon_theme(self, dark: bool) -> str:
        if not dark:
            return self._icon_base
        want = self._icon_base + "-dark"
        for d in QIcon.themeSearchPaths():
            if Path(d, want).is_dir():
                return want
        return self._icon_base

    # ---------------------------------------------------- hand-offs (temporary fallback)
    @Slot(str)
    def openKcm(self, name: str):
        if self._kcms is None:
            listing = run(["kcmshell6", "--list"])
            self._kcms = {line.split()[0] for line in listing.splitlines() if line.strip()}
        if name in self._kcms:
            spawn(["kcmshell6", name])
        else:
            spawn(["systemsettings", name])

    @Slot("QVariantList")
    def runCommand(self, args):
        spawn([str(a) for a in args])

    @Slot(str)
    def copyText(self, text: str):
        from PySide6.QtGui import QGuiApplication
        QGuiApplication.clipboard().setText(text)
