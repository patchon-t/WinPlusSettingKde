"""Backend for WinPlusSettingKde.

Talks to KDE Plasma 6 through the tools Plasma already ships:
kreadconfig6 / kwriteconfig6, plasma-apply-*, kscreen-doctor, dbus-send,
bluetoothctl, nmcli and kcmshell6. Nothing here needs root except renaming
the PC (done through pkexec).
"""
from __future__ import annotations

import json
import os
import pwd
import re
import shutil
import socket
import subprocess
from pathlib import Path

from PySide6.QtCore import (QObject, Property, QProcess, QSettings, QSize, Qt,
                            QTimer, QUrl, Signal, Slot)
from PySide6.QtGui import QIcon, QPixmap
from PySide6.QtQuick import QQuickImageProvider

try:
    from PySide6.QtQml import QQmlImageProviderBase
    PIXMAP = QQmlImageProviderBase.ImageType.Pixmap
except (ImportError, AttributeError):
    PIXMAP = QQuickImageProvider.ImageType.Pixmap

HOME = Path.home()
ROOT = Path(__file__).resolve().parent
ICON_DIR = ROOT / "qml" / "icons"
ANSI = re.compile(r"\x1b\[[0-9;]*m")
IMG_EXT = {".jpg", ".jpeg", ".png", ".webp", ".avif"}
SCALES = [1.0, 1.25, 1.5, 1.75, 2.0]
ROT_TO_INDEX = {1: 0, 2: 1, 4: 2, 8: 3}          # kscreen: none, left, inverted, right
INDEX_TO_ROT = ["normal", "left", "inverted", "right"]


# ---------------------------------------------------------------- helpers
def has(cmd: str) -> bool:
    return shutil.which(cmd) is not None


def run(args, timeout: float = 4.0) -> str:
    """Run a command synchronously, return stdout ('' on any failure)."""
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


def kread(file: str, group: str, key: str, default: str = "") -> str:
    if not has("kreadconfig6"):
        return default
    return run(["kreadconfig6", "--file", file, "--group", group,
                "--key", key, "--default", default]) or default


def kwrite(file: str, group: str, key: str, value: str, kind: str | None = None):
    args = ["kwriteconfig6", "--file", file, "--group", group, "--key", key]
    if kind:
        args += ["--type", kind]
    run(args + [value])


def dbus(dest: str, path: str, method: str, *args: str, reply: bool = False):
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


# ---------------------------------------------------------------- backend
class Backend(QObject):
    darkChanged = Signal()
    accentChanged = Signal()
    accentAutoChanged = Signal()
    recentAccentsChanged = Signal()
    blurChanged = Signal()
    nightLightChanged = Signal()
    bluetoothChanged = Signal()
    networkChanged = Signal()
    hostChanged = Signal()
    aboutChanged = Signal()
    wallpaperChanged = Signal()
    outputsChanged = Signal()
    brightnessChanged = Signal()

    def __init__(self):
        super().__init__()
        self._settings = QSettings()
        self._dark = self._read_dark()
        self._accent = self._read_accent()
        self._accent_auto = kread("kdeglobals", "General", "accentColorFromWallpaper", "false") == "true"
        self._recent = [str(c) for c in (self._settings.value("recentAccents", [], type=list) or [])]
        self._blur = kread("kwinrc", "Plugins", "blurEnabled", "true") == "true"
        self._night = kread("kwinrc", "NightColor", "Active", "false") == "true"
        self._bt_on, self._bt_avail = False, False
        self._net_type, self._net_name = "", ""
        self._plasma_version = ""
        self._wallpaper = self._read_wallpaper()
        self._wallpapers = self._scan_wallpapers()
        if not self._wallpaper and self._wallpapers:
            self._wallpaper = self._wallpapers[0]["path"]
        self._raw_outputs: dict[str, dict] = {}
        self._outputs = self._read_outputs()
        self._bright, self._bright_max = self._read_brightness()
        self._icon_base = kread("kdeglobals", "Icons", "Theme", "breeze").removesuffix("-dark") or "breeze"
        self._kcms: set[str] | None = None

        self._bright_timer = QTimer(self, singleShot=True, interval=60)
        self._bright_timer.timeout.connect(self._apply_brightness)

        # Bluetooth / network can change behind our back -> poll asynchronously
        self._poll = QTimer(self, interval=5000)
        self._poll.timeout.connect(self._poll_tick)
        self._poll.start()
        self._poll_tick()
        self._async(["plasmashell", "--version"], self._on_plasma_version)

    # ---------------------------------------------------- async process helper
    def _async(self, args, callback=None, timeout_ms: int = 8000):
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

    # ---------------------------------------------------- readers
    def _read_dark(self) -> bool:
        bg = kread("kdeglobals", "Colors:Window", "BackgroundNormal", "")
        try:
            r, g, b = (int(x) for x in bg.split(",")[:3])
            return 0.299 * r + 0.587 * g + 0.114 * b < 128
        except ValueError:
            return "dark" in kread("kdeglobals", "General", "ColorScheme", "").lower()

    def _read_accent(self) -> str:
        acc = kread("kdeglobals", "General", "AccentColor", "")
        if not acc:
            acc = kread("kdeglobals", "Colors:View", "DecorationFocus", "")
        return rgb_to_hex(acc, "#0067c0")

    def _read_wallpaper(self) -> str:
        """Current desktop wallpaper as a local image path ('' if unknown)."""
        f = HOME / ".config" / "plasma-org.kde.plasma.desktop-appletsrc"
        try:
            txt = f.read_text(errors="replace")
        except OSError:
            return ""
        for value in re.findall(r"^Image=(.+)$", txt, re.M):
            value = value.strip()
            if value.startswith("file:"):
                value = QUrl(value).toLocalFile()          # handles %20 etc.
            p = Path(value)
            if not p.is_absolute():                        # package name, e.g. "Next"
                for root in (HOME / ".local/share/wallpapers", Path("/usr/share/wallpapers")):
                    if (root / value).exists():
                        p = root / value
                        break
            if p.is_dir():
                img = best_image(p)
                if img:
                    return str(img)
            elif p.is_file():
                return str(p)
        return ""

    def _scan_wallpapers(self) -> list:
        out = []
        for root in (Path("/usr/share/wallpapers"), HOME / ".local/share/wallpapers"):
            if not root.is_dir():
                continue
            for entry in sorted(root.iterdir()):
                if entry.is_dir():
                    img = best_image(entry)
                    if not img:
                        continue
                    shot = entry / "contents" / "screenshot.png"
                    thumb = shot if shot.exists() else img
                    out.append({"name": entry.name, "path": str(img), "thumb": file_url(str(thumb))})
                elif entry.suffix.lower() in IMG_EXT:
                    out.append({"name": entry.stem, "path": str(entry), "thumb": file_url(str(entry))})
        # Put the current wallpaper first so the Home grid shows it selected
        out.sort(key=lambda w: w["path"] != self._wallpaper)
        return out

    def _read_outputs(self) -> list:
        raw = run(["kscreen-doctor", "-j"])
        if not raw:
            return []
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            return []
        text = ANSI.sub("", run(["kscreen-doctor", "-o"]))
        connected = [o for o in data.get("outputs", []) if o.get("connected")]
        connected.sort(key=lambda o: o.get("priority") or 99)

        def size_of(m):
            s = m.get("size") or {}
            return int(s.get("width", 0)), int(s.get("height", 0))

        outs, self._raw_outputs = [], {}
        for n, o in enumerate(connected, 1):
            name = o.get("name", f"output{n}")
            modes = o.get("modes") or []
            cur_id = str(o.get("currentModeId", ""))
            cur = next((m for m in modes if str(m.get("id")) == cur_id), modes[0] if modes else {})
            pref_ids = {str(i) for i in (o.get("preferredModes") or [])}
            pref_sizes = {size_of(m) for m in modes if str(m.get("id")) in pref_ids}
            sizes = sorted({size_of(m) for m in modes}, key=lambda s: s[0] * s[1], reverse=True)
            cw, ch = size_of(cur)
            rates = sorted({round(float(m.get("refreshRate", 0)), 2) for m in modes
                            if size_of(m) == (cw, ch)}, reverse=True)
            cur_rate = round(float(cur.get("refreshRate", 0)), 2)
            scale = float(o.get("scale") or 1.0)
            rot = int(o.get("rotation") or 1)
            lw, lh = (ch, cw) if rot in (2, 8) else (cw, ch)
            pos = o.get("pos") or {}
            res_keys = [f"{w}x{h}" for w, h in sizes]
            hdr = self._hdr_state(text, name)
            self._raw_outputs[name] = {"modes": modes, "size": (cw, ch), "rate": cur_rate}
            outs.append({
                "name": name,
                "label": str(n),
                "enabled": bool(o.get("enabled")),
                "x": pos.get("x", 0), "y": pos.get("y", 0),
                "w": max(lw / scale, 1), "h": max(lh / scale, 1),
                "scale": scale,
                "scaleIndex": min(range(len(SCALES)), key=lambda i: abs(SCALES[i] - scale)),
                "rotationIndex": ROT_TO_INDEX.get(rot, 0),
                "resolutions": [f"{w} × {h}" + ("  (Recommended)" if (w, h) in pref_sizes else "")
                                for w, h in sizes],
                "resolutionKeys": res_keys,
                "resIndex": res_keys.index(f"{cw}x{ch}") if f"{cw}x{ch}" in res_keys else 0,
                "rates": [f"{r:g} Hz" for r in rates],
                "rateValues": rates,
                "rateIndex": rates.index(cur_rate) if cur_rate in rates else 0,
                "hdrSupported": hdr in ("enabled", "disabled"),
                "hdr": hdr == "enabled",
            })
        return outs

    @staticmethod
    def _hdr_state(text: str, name: str) -> str:
        m = re.search(rf"Output:\s*\d+\s+{re.escape(name)}\b(.*?)(?=\nOutput:|\Z)", text, re.S)
        if not m:
            return ""
        h = re.search(r"HDR:\s*(\w+)", m.group(1))
        return h.group(1).lower() if h else ""

    def _read_brightness(self):
        svc = "org.kde.Solid.PowerManagement"
        path = "/org/kde/Solid/PowerManagement/Actions/BrightnessControl"
        iface = "org.kde.Solid.PowerManagement.Actions.BrightnessControl"
        cur = re.search(r"int32\s+(-?\d+)", dbus(svc, path, iface + ".brightness", reply=True) or "")
        mx = re.search(r"int32\s+(-?\d+)", dbus(svc, path, iface + ".brightnessMax", reply=True) or "")
        if cur and mx and int(mx.group(1)) > 0:
            return int(cur.group(1)), int(mx.group(1))
        return -1, 0

    # ---------------------------------------------------- polling
    def _poll_tick(self):
        self._async(["bluetoothctl", "show"], self._on_bt, timeout_ms=3000)
        self._async(["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"], self._on_net, timeout_ms=3000)

    def _on_bt(self, ok: bool, out: str):
        avail = ok and "Controller" in out
        on = avail and re.search(r"Powered:\s*yes", out) is not None
        if (avail, on) != (self._bt_avail, self._bt_on):
            self._bt_avail, self._bt_on = avail, on
            self.bluetoothChanged.emit()

    def _on_net(self, ok: bool, out: str):
        typ, name = "", ""
        for line in out.splitlines():
            parts = line.split(":", 2)
            if len(parts) == 3 and parts[1] == "connected" and parts[0] in ("ethernet", "wifi"):
                typ, name = parts[0], parts[2].replace("\\:", ":")
                break
        if (typ, name) != (self._net_type, self._net_name):
            self._net_type, self._net_name = typ, name
            self.networkChanged.emit()

    def _on_plasma_version(self, ok: bool, out: str):
        self._plasma_version = out.split()[-1] if ok and out.split() else ""
        self.aboutChanged.emit()

    # ---------------------------------------------------- properties
    def _p(name, typ, notify=None):  # noqa: N805 - tiny property factory
        attr = "_" + name
        if notify is None:
            return Property(typ, lambda self: getattr(self, attr), constant=True)
        return Property(typ, lambda self: getattr(self, attr), notify=notify)

    dark = _p("dark", bool, darkChanged)
    accent = _p("accent", str, accentChanged)
    accentAuto = _p("accent_auto", bool, accentAutoChanged)
    recentAccents = _p("recent", "QVariantList", recentAccentsChanged)
    blur = _p("blur", bool, blurChanged)
    nightLight = _p("night", bool, nightLightChanged)
    bluetoothOn = _p("bt_on", bool, bluetoothChanged)
    bluetoothAvailable = _p("bt_avail", bool, bluetoothChanged)
    networkType = _p("net_type", str, networkChanged)
    networkName = _p("net_name", str, networkChanged)
    plasmaVersion = _p("plasma_version", str, aboutChanged)
    wallpaper = _p("wallpaper", str, wallpaperChanged)
    wallpapers = _p("wallpapers", "QVariantList", wallpaperChanged)
    outputs = _p("outputs", "QVariantList", outputsChanged)
    del _p

    @Property(str, notify=wallpaperChanged)
    def wallpaperUrl(self):
        return file_url(self._wallpaper)

    @Property(str, notify=hostChanged)
    def hostname(self):
        return socket.gethostname()

    @Property(str, constant=True)
    def deviceModel(self):
        def rd(n):
            try:
                return Path(f"/sys/class/dmi/id/{n}").read_text().strip()
            except OSError:
                return ""
        junk = {"", "to be filled by o.e.m.", "system product name", "default string"}
        parts = [p for p in (rd("sys_vendor"), rd("product_name")) if p.lower() not in junk]
        return " ".join(parts)

    @Property(str, constant=True)
    def userLogin(self):
        return pwd.getpwuid(os.getuid()).pw_name

    @Property(str, constant=True)
    def userName(self):
        pw = pwd.getpwuid(os.getuid())
        return (pw.pw_gecos.split(",")[0] or pw.pw_name).strip()

    @Property(str, constant=True)
    def avatar(self):
        login = pwd.getpwuid(os.getuid()).pw_name
        for p in (HOME / ".face.icon", HOME / ".face",
                  Path("/var/lib/AccountsService/icons") / login):
            if p.is_file():
                return file_url(str(p))
        return ""

    @Property(str, constant=True)
    def osName(self):
        try:
            for line in Path("/etc/os-release").read_text().splitlines():
                if line.startswith("PRETTY_NAME="):
                    return line.split("=", 1)[1].strip().strip('"')
        except OSError:
            pass
        return "Linux"

    @Property(str, constant=True)
    def kernel(self):
        return os.uname().release

    @Property(int, notify=outputsChanged)
    def displayModeIndex(self):
        enabled = [i for i, o in enumerate(self._outputs) if o["enabled"]]
        if len(self._outputs) > 1 and len(enabled) == 1:
            return enabled[0] + 1
        return 0

    @Property(bool, notify=brightnessChanged)
    def brightnessAvailable(self):
        return self._bright_max > 0

    @Property(int, notify=brightnessChanged)
    def brightness(self):
        return round(self._bright * 100 / self._bright_max) if self._bright_max else 0

    @Property(float, constant=True)
    def storageRatio(self):
        u = shutil.disk_usage("/")
        return u.used / u.total if u.total else 0.0

    @Property(str, constant=True)
    def storageText(self):
        u = shutil.disk_usage("/")
        gb = 1024 ** 3
        return f"{u.used / gb:.0f} GB used of {u.total / gb:.0f} GB"

    # ---------------------------------------------------- icon theme (used by IconProvider)
    def icon_theme(self, dark: bool) -> str:
        if not dark:
            return self._icon_base
        want = self._icon_base + "-dark"
        for d in QIcon.themeSearchPaths():
            if Path(d, want).is_dir():
                return want
        return self._icon_base

    # ---------------------------------------------------- appearance slots
    @Slot(bool)
    def setDark(self, dark: bool):
        if dark == self._dark:
            return
        self._dark = dark
        self.darkChanged.emit()
        self._async(["plasma-apply-colorscheme", "BreezeDark" if dark else "BreezeLight"],
                    lambda *_: self._refresh_accent())

    def _refresh_accent(self):
        acc = self._read_accent()
        if acc != self._accent:
            self._accent = acc
            self.accentChanged.emit()

    @Slot(str)
    def setAccent(self, color: str):
        color = "#" + color.lstrip("#")[-6:].lower()  # drop alpha if QML sent #aarrggbb
        self._accent = color
        self.accentChanged.emit()
        if self._accent_auto:
            self.setAccentAuto(False)
        self._async(["plasma-apply-colorscheme", "--accent-color", color])
        self._recent = [color] + [c for c in self._recent if c != color][:4]
        self._settings.setValue("recentAccents", self._recent)
        self.recentAccentsChanged.emit()

    @Slot(bool)
    def setAccentAuto(self, auto: bool):
        self._accent_auto = auto
        self.accentAutoChanged.emit()
        kwrite("kdeglobals", "General", "accentColorFromWallpaper", "true" if auto else "false", "bool")

    @Slot(bool)
    def setBlur(self, on: bool):
        self._blur = on
        self.blurChanged.emit()
        kwrite("kwinrc", "Plugins", "blurEnabled", "true" if on else "false", "bool")
        kwrite("kwinrc", "Plugins", "contrastEnabled", "true" if on else "false", "bool")
        kwin_reconfigure()

    @Slot(bool)
    def setNightLight(self, on: bool):
        self._night = on
        self.nightLightChanged.emit()
        kwrite("kwinrc", "NightColor", "Active", "true" if on else "false", "bool")
        kwin_reconfigure()

    @Slot(str)
    def setWallpaper(self, path: str):
        self._wallpaper = path
        self.wallpaperChanged.emit()
        self._async(["plasma-apply-wallpaperimage", path])

    # ---------------------------------------------------- devices / system
    @Slot(bool)
    def setBluetooth(self, on: bool):
        self._bt_on = on
        self.bluetoothChanged.emit()
        self._async(["bluetoothctl", "power", "on" if on else "off"], lambda *_: self._poll_tick())

    @Slot(str)
    def renameHost(self, name: str):
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,62}", name):
            return
        self._async(["pkexec", "hostnamectl", "set-hostname", name],
                    lambda *_: self.hostChanged.emit(), timeout_ms=120000)

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

    # ---------------------------------------------------- display slots
    def _kscreen(self, *ops: str):
        self._async(["kscreen-doctor", *ops], lambda *_: self.reloadOutputs())

    @Slot()
    def reloadOutputs(self):
        self._outputs = self._read_outputs()
        self.outputsChanged.emit()

    def _mode_id(self, name: str, size: tuple, rate: float | None):
        raw = self._raw_outputs.get(name)
        if not raw:
            return None
        cands = [m for m in raw["modes"]
                 if ((m.get("size") or {}).get("width"), (m.get("size") or {}).get("height")) == size]
        if not cands:
            return None
        target = raw["rate"] if rate is None else rate
        best = min(cands, key=lambda m: abs(float(m.get("refreshRate", 0)) - target))
        return str(best.get("id"))

    @Slot(str, str)
    def setResolution(self, name: str, key: str):
        w, h = (int(v) for v in key.split("x"))
        mid = self._mode_id(name, (w, h), None)
        if mid:
            self._kscreen(f"output.{name}.mode.{mid}")

    @Slot(str, float)
    def setRefresh(self, name: str, rate: float):
        raw = self._raw_outputs.get(name)
        mid = raw and self._mode_id(name, raw["size"], rate)
        if mid:
            self._kscreen(f"output.{name}.mode.{mid}")

    @Slot(str, float)
    def setScale(self, name: str, scale: float):
        self._kscreen(f"output.{name}.scale.{scale:g}")

    @Slot(str, int)
    def setRotation(self, name: str, index: int):
        self._kscreen(f"output.{name}.rotation.{INDEX_TO_ROT[index]}")

    @Slot(str, bool)
    def setHdr(self, name: str, on: bool):
        self._kscreen(f"output.{name}.hdr.{'enable' if on else 'disable'}")

    @Slot(int)
    def setDisplayMode(self, index: int):
        names = [o["name"] for o in self._outputs]
        if index == 0:
            self._kscreen(*[f"output.{n}.enable" for n in names])
        elif 0 < index <= len(names):
            keep = names[index - 1]
            self._kscreen(f"output.{keep}.enable",
                          *[f"output.{n}.disable" for n in names if n != keep])

    @Slot()
    def identifyDisplays(self):
        dbus("org.kde.kscreen.osdService", "/org/kde/kscreen/osdService",
             "org.kde.kscreen.osdService.showOutputIdentifier")

    @Slot(int)
    def setBrightness(self, percent: int):
        if not self._bright_max:
            return
        self._bright = round(percent * self._bright_max / 100)
        self.brightnessChanged.emit()
        self._bright_timer.start()

    def _apply_brightness(self):
        dbus("org.kde.Solid.PowerManagement",
             "/org/kde/Solid/PowerManagement/Actions/BrightnessControl",
             "org.kde.Solid.PowerManagement.Actions.BrightnessControl.setBrightness",
             f"int32:{self._bright}")


# ---------------------------------------------------------------- icons
CACHE_DIR = HOME / ".cache" / "WinPlusSettingKde" / "icons"


class IconProvider(QQuickImageProvider):
    """image://icon/<name>[|fallback...]?<d|l>

    name = "fl:<stem>[@rrggbb]"  bundled Fluent SVG from qml/icons/<stem>.svg.
           *_color icons keep their own colors; mono icons get the tint, or the
           theme text color (dark/light) when no tint is given.
    name = anything else          looked up in the system icon theme.
    """

    def __init__(self, backend: Backend):
        super().__init__(PIXMAP)
        self._b = backend
        CACHE_DIR.mkdir(parents=True, exist_ok=True)

    def _fluent(self, spec: str, dark: bool) -> QIcon:
        stem, _, tint = spec.partition("@")
        src = ICON_DIR / f"{stem}.svg"
        if not src.exists():
            return QIcon()
        if stem.endswith("_color"):
            return QIcon(str(src))
        color = "#" + tint if tint else ("#ffffff" if dark else "#1b1b1b")
        out = CACHE_DIR / f"{stem}-{color[1:]}.svg"
        if not out.exists():
            svg = src.read_text().replace("<svg ", f'<svg fill="{color}" ', 1)
            out.write_text(svg)
        return QIcon(str(out))

    def requestPixmap(self, id_: str, size: QSize, requested: QSize) -> QPixmap:
        names, _, mode = id_.partition("?")
        dark = mode == "d"
        px = requested.width() if requested.width() > 0 else 32
        for name in names.split("|"):
            if name.startswith("fl:"):
                icon = self._fluent(name[3:], dark)
            else:
                QIcon.setThemeName(self._b.icon_theme(dark))
                icon = QIcon.fromTheme(name)
            if not icon.isNull():
                return icon.pixmap(QSize(px, px))
        pm = QPixmap(px, px)
        pm.fill(Qt.transparent)
        return pm
