"""System updates (the Win11 "Windows Update" page).

Sources (SITEMAP section 11), all run through _async with long timeouts:
  distro packages  `pkcon refresh` (PackageKit), then `apt list --upgradable`
                   (format checked against real output: "name/suite NEW arch
                   [upgradable from: OLD]"); install with `pkcon update -y`.
  Flatpak          `flatpak remote-ls --updates --columns=application,version,name`,
                   install with `flatpak update -y --noninteractive`.
  firmware         `fwupdmgr get-updates --json` (JSON schema not verified here:
                   parsed defensively), shown under Advanced options › Optional updates.
History: /var/log/apt/history.log (format checked here), `flatpak history
--columns=time,change,application`, `fwupdmgr get-history --json`.
Restart: org.kde.LogoutPrompt /LogoutPrompt promptReboot
         (plasma-workspace/kcms/region_language/kcmregionandlang.cpp:275-278).
Plasma extras: PlasmaDiscoverUpdates [Global] UseUnattendedUpdates,
               discoverrc [Software] UseOfflineUpdates (discover/kcm/*.kcfg).
"""
from __future__ import annotations

import json
import re
import time
from pathlib import Path

from PySide6.QtCore import Property, QDateTime, Signal, Slot

from .util import dbus, has, kread, kwrite, prop

_UPD_CHECK_MS = 10 * 60 * 1000        # refresh/list can take minutes on slow mirrors
_UPD_INSTALL_MS = 2 * 60 * 60 * 1000  # a large upgrade can take an hour or more
_UPD_APT_LOG = Path("/var/log/apt/history.log")
_UPD_REBOOT_FLAG = Path("/var/run/reboot-required")   # Ubuntu; UNVERIFIED on target
_UPD_APT_LINE = re.compile(r"^(\S+?)/\S+\s+(\S+)\s+\S+\s+\[upgradable from: ([^\]]+)\]")
_UPD_PAUSE_WEEKS = [0, 1, 2, 3, 4, 5]


def _upd_fw_releases(data) -> list:
    """Best-effort walk of `fwupdmgr --json` output -> [{name, version}]."""
    out = []
    devices = data.get("Devices", []) if isinstance(data, dict) else []
    for d in devices if isinstance(devices, list) else []:
        if not isinstance(d, dict):
            continue
        rels = d.get("Releases") or []
        if rels and isinstance(rels, list) and isinstance(rels[0], dict):
            out.append({"name": str(d.get("Name", "Firmware")),
                        "version": str(rels[0].get("Version", "")), "source": "Firmware"})
    return out


class UpdatesMixin:
    updatesChanged = Signal()
    updatesHistoryChanged = Signal()

    def _init_updates(self):
        self._upd_state = "idle"          # idle|checking|available|uptodate|installing|restart|error
        self._upd_list = []               # [{name, version, source}]
        self._upd_fw = []
        self._upd_msg = ""
        self._upd_last = str(self._settings.value("updLastChecked", "") or "")
        self._upd_paused = int(self._settings.value("updPausedUntil", 0) or 0)
        self._upd_auto = False
        self._upd_offline = False
        self._upd_history = []
        self._upd_pending = 0
        self._upd_partial = []

    updatesState = prop("upd_state", str, updatesChanged)
    updatesList = prop("upd_list", "QVariantList", updatesChanged)
    firmwareUpdates = prop("upd_fw", "QVariantList", updatesChanged)
    updatesMessage = prop("upd_msg", str, updatesChanged)
    updatesLastChecked = prop("upd_last", str, updatesChanged)
    updatesAutomatic = prop("upd_auto", bool, updatesChanged)
    updatesOffline = prop("upd_offline", bool, updatesChanged)
    updatesHistory = prop("upd_history", "QVariantList", updatesHistoryChanged)

    @Property(str, notify=updatesChanged)
    def updatesPausedUntil(self) -> str:
        if self._upd_paused <= time.time():
            return ""
        return QDateTime.fromSecsSinceEpoch(self._upd_paused).toString("MMMM d, yyyy")

    # ---------------------------------------------------- settings
    @Slot()
    def refreshUpdates(self):
        self._upd_auto = kread("PlasmaDiscoverUpdates", "Global", "UseUnattendedUpdates", "false") == "true"
        self._upd_offline = kread("discoverrc", "Software", "UseOfflineUpdates", "false") == "true"
        if self._upd_state not in ("checking", "installing") and _UPD_REBOOT_FLAG.exists():
            self._upd_state = "restart"
        self.updatesChanged.emit()

    @Slot(bool)
    def setUpdatesAutomatic(self, on: bool):
        self._upd_auto = on
        self.updatesChanged.emit()
        kwrite("PlasmaDiscoverUpdates", "Global", "UseUnattendedUpdates", "true" if on else "false", "bool")

    @Slot(bool)
    def setUpdatesOffline(self, on: bool):
        self._upd_offline = on
        self.updatesChanged.emit()
        kwrite("discoverrc", "Software", "UseOfflineUpdates", "true" if on else "false", "bool")

    @Slot(int)
    def pauseUpdates(self, weeks: int):
        """Win11 'Pause updates'. Only pauses checks made by this app (PARTIAL)."""
        self._upd_paused = int(time.time() + weeks * 7 * 86400) if weeks > 0 else 0
        self._settings.setValue("updPausedUntil", self._upd_paused)
        self.updatesChanged.emit()

    # ---------------------------------------------------- check
    @Slot()
    def checkForUpdates(self):
        if self._upd_state in ("checking", "installing"):
            return
        self._upd_state, self._upd_msg = "checking", "Checking for updates…"
        self._upd_partial, self._upd_fw = [], []
        self.updatesChanged.emit()
        steps = []
        if has("apt"):
            steps.append(self._upd_check_packages)
        if has("flatpak"):
            steps.append(self._upd_check_flatpak)
        if has("fwupdmgr"):
            steps.append(self._upd_check_firmware)
        self._upd_pending = len(steps)
        if not steps:
            return self._upd_check_done()
        for step in steps:
            step()

    def _upd_step_done(self):
        self._upd_pending -= 1
        if self._upd_pending <= 0:
            self._upd_check_done()

    def _upd_check_packages(self):
        def listed(ok, out):
            for line in out.splitlines():
                m = _UPD_APT_LINE.match(line.strip())
                if m:
                    self._upd_partial.append({"name": m.group(1), "version": m.group(2),
                                              "source": "System package"})
            self._upd_step_done()

        def refreshed(_ok, _out):   # a failed refresh still leaves the last cache usable
            self._async(["apt", "list", "--upgradable"], listed, _UPD_CHECK_MS)

        if has("pkcon"):
            self._async(["pkcon", "-p", "refresh"], refreshed, _UPD_CHECK_MS)
        else:
            refreshed(False, "")

    def _upd_check_flatpak(self):
        def listed(ok, out):
            for line in out.splitlines():
                f = line.split("\t")
                if len(f) >= 2 and f[0] and f[0] != "Application ID":
                    name = f[2] if len(f) > 2 and f[2] else f[0]
                    self._upd_partial.append({"name": name, "version": f[1], "source": "Flatpak"})
            self._upd_step_done()

        self._async(["flatpak", "remote-ls", "--updates", "--columns=application,version,name"],
                    listed, _UPD_CHECK_MS)

    def _upd_check_firmware(self):
        def listed(ok, out):
            try:
                self._upd_fw = _upd_fw_releases(json.loads(out)) if out.strip() else []
            except ValueError:
                self._upd_fw = []
            self._upd_step_done()

        self._async(["fwupdmgr", "get-updates", "--json"], listed, _UPD_CHECK_MS)

    def _upd_check_done(self):
        self._upd_list = sorted(self._upd_partial, key=lambda u: (u["source"], u["name"].lower()))
        self._upd_last = QDateTime.currentDateTime().toString("dddd, h:mm AP")
        self._settings.setValue("updLastChecked", self._upd_last)
        if _UPD_REBOOT_FLAG.exists() and not self._upd_list:
            self._upd_state, self._upd_msg = "restart", "A restart is required to finish installing updates"
        elif self._upd_list:
            n = len(self._upd_list)
            self._upd_state, self._upd_msg = "available", f"{n} update{'s' if n != 1 else ''} available"
        else:
            self._upd_state, self._upd_msg = "uptodate", "You're up to date"
        self.updatesChanged.emit()

    # ---------------------------------------------------- install
    @Slot()
    def installUpdates(self):
        if self._upd_state in ("checking", "installing") or not self._upd_list:
            return
        sources = {u["source"] for u in self._upd_list}
        steps = []
        if "System package" in sources and has("pkcon"):
            steps.append(["pkcon", "-p", "-y", "update"])
        if "Flatpak" in sources:
            steps.append(["flatpak", "update", "-y", "--noninteractive"])
        self._upd_run_steps(steps, "Installing updates…")

    @Slot()
    def installFirmwareUpdates(self):
        if self._upd_state in ("checking", "installing") or not self._upd_fw:
            return
        # --json "disables all interactive prompts" (fwupdmgr --help)
        self._upd_run_steps([["fwupdmgr", "update", "--json"]], "Installing firmware updates…")

    def _upd_run_steps(self, steps, msg):
        if not steps:
            return
        self._upd_state, self._upd_msg = "installing", msg
        self.updatesChanged.emit()
        def next_step(ok, _out=""):
            if not ok:
                return finish(False)
            if not steps:
                return finish(True)
            self._async(steps.pop(0), next_step, _UPD_INSTALL_MS)

        def finish(all_ok):
            if not all_ok:
                self._upd_state, self._upd_msg = "error", "Some updates couldn't be installed. Try again later."
                self.updatesChanged.emit()
                return
            self._upd_list = []
            if _UPD_REBOOT_FLAG.exists():
                self._upd_state, self._upd_msg = "restart", "A restart is required to finish installing updates"
            else:
                self._upd_state, self._upd_msg = "uptodate", "You're up to date"
            self.updatesChanged.emit()

        self._async(steps.pop(0), next_step, _UPD_INSTALL_MS)

    @Slot()
    def restartForUpdates(self):
        dbus("org.kde.LogoutPrompt", "/LogoutPrompt", "org.kde.LogoutPrompt.promptReboot")

    # ---------------------------------------------------- history
    @Slot()
    def refreshUpdateHistory(self):
        items = self._upd_apt_history()
        self._upd_history = items
        self.updatesHistoryChanged.emit()

        def flat(ok, out):
            for line in out.splitlines() if ok else []:
                f = line.split("\t")
                if len(f) >= 3 and f[1] in ("update", "install"):
                    self._upd_history.append({"kind": "Other updates", "name": f[2],
                                              "detail": f"Flatpak {f[1]}", "date": f[0]})
            self.updatesHistoryChanged.emit()

        def fw(ok, out):
            try:
                rel = _upd_fw_releases(json.loads(out)) if ok and out.strip() else []
            except ValueError:
                rel = []
            for r in rel:
                self._upd_history.append({"kind": "Driver updates", "name": r["name"],
                                          "detail": "Version " + r["version"], "date": ""})
            self.updatesHistoryChanged.emit()

        if has("flatpak"):
            self._async(["flatpak", "history", "--columns=time,change,application"], flat, 30000)
        if has("fwupdmgr"):
            self._async(["fwupdmgr", "get-history", "--json"], fw, 30000)

    @staticmethod
    def _upd_apt_history() -> list:
        """Last 50 package changes from apt's log (format seen on Ubuntu 24.04)."""
        try:
            text = _UPD_APT_LOG.read_text(errors="replace")
        except OSError:
            return []
        out, date = [], ""
        for line in text.splitlines():
            if line.startswith("Start-Date:"):
                date = line.split(":", 1)[1].strip()
            elif line.split(":", 1)[0] in ("Upgrade", "Install", "Remove", "Reinstall"):
                action, rest = line.split(":", 1)
                for pkg in re.findall(r"([^\s,]+?):\S+ \(([^)]*)\)", rest):
                    out.append({"kind": "Quality updates" if action == "Upgrade" else "Other updates",
                                "name": pkg[0],
                                "detail": f"{action} · " + pkg[1].replace(", ", " → "), "date": date})
        return list(reversed(out))[:50]
