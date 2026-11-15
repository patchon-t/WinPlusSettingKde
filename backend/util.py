"""Shared helpers for every backend mixin.

Plain functions only (no Qt state). Anything that needs the Backend
instance (async processes, debounced commands) lives in core.py.
"""
from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path

from PySide6.QtCore import Property, QUrl

HOME = Path.home()
ROOT = Path(__file__).resolve().parent.parent
ICON_DIR = ROOT / "qml" / "icons"
ANSI = re.compile(r"\x1b\[[0-9;]*m")
IMG_EXT = {".jpg", ".jpeg", ".png", ".webp", ".avif"}


def has(cmd: str) -> bool:
    return shutil.which(cmd) is not None


def run(args, timeout: float = 4.0) -> str:
    """Run a command synchronously, return stdout ('' on any failure).
    Only for fast, local commands. Anything that can hang -> Backend._async."""
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    except (FileNotFoundError, PermissionError, subprocess.TimeoutExpired):
        return ""
    return r.stdout.strip() if r.returncode == 0 else ""


def spawn(args) -> bool:
    """Fire and forget (detached, survives this app closing)."""
    try:
        subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)
        return True
    except (FileNotFoundError, PermissionError):
        return False


def _groups(group: str) -> list:
    out = []
    for g in group.split("/"):          # "AC/Display" -> --group AC --group Display
        out += ["--group", g]
    return out


def kread(file: str, group: str, key: str, default: str = "") -> str:
    if not has("kreadconfig6"):
        return default
    return run(["kreadconfig6", "--file", file, *_groups(group),
                "--key", key, "--default", default]) or default


def kwrite(file: str, group: str, key: str, value: str, kind: str | None = None):
    args = ["kwriteconfig6", "--file", file, *_groups(group), "--key", key]
    if kind:
        args += ["--type", kind]
    run(args + [value])


def dbus(dest: str, path: str, method: str, *args: str, reply: bool = False):
    """dbus-send on the session bus. reply=True -> returns printed reply text."""
    cmd = ["dbus-send", "--session", f"--dest={dest}"]
    cmd.append("--print-reply" if reply else "--type=method_call")
    cmd += [path, method, *args]
    return run(cmd) if reply else spawn(cmd)


def kwin_reconfigure():
    dbus("org.kde.KWin", "/KWin", "org.kde.KWin.reconfigure")


def rgb_to_hex(s: str, default: str) -> str:
    try:
        r, g, b = (int(x) for x in s.split(",")[:3])
        return f"#{r:02x}{g:02x}{b:02x}"
    except ValueError:
        return default


def file_url(p: str) -> str:
    return QUrl.fromLocalFile(p).toString() if p else ""


def best_image(pkg: Path) -> Path | None:
    """Pick the largest image inside a Plasma wallpaper package."""
    imgs = [p for p in (pkg / "contents" / "images").glob("*") if p.suffix.lower() in IMG_EXT]
    if not imgs:
        return None

    def area(p: Path) -> int:
        m = re.match(r"(\d+)x(\d+)", p.stem)
        return int(m.group(1)) * int(m.group(2)) if m else 0

    return max(imgs, key=area)


def prop(name: str, typ, notify=None):
    """Read-only Qt Property backed by self._<name>.
    Use in a mixin class body:  foo = prop("foo", bool, fooChanged)"""
    attr = "_" + name
    if notify is None:
        return Property(typ, lambda self: getattr(self, attr), constant=True)
    return Property(typ, lambda self: getattr(self, attr), notify=notify)
