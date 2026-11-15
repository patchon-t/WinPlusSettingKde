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
    soundChanged = Signal()
    bluetoothDevicesChanged = Signal()
    wifiChanged = Signal()
    wifiResult = Signal(bool, str)      # ok, message (shown to the user)
    powerChanged = Signal()
    timeChanged = Signal()

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
        # state for the native pages (filled by their refresh slots)
        self._sinks, self._sources = [], []
        self._sink_idx = self._source_idx = -1
        self._out_vol = self._in_vol = 0
        self._out_mute = self._in_mute = False
        self._bt_devices = []
        self._wifi_on, self._wifi_list, self._wifi_iface, self._wifi_known = False, [], "", set()
        self._wifi_busy = False
        self._bat_present, self._bat_pct, self._bat_status = False, 0, ""
        self._profiles, self._profile_idx = [], -1
        self._timezone, self._ntp, self._timezones = "", False, []

        # Coalesce rapid slider changes into one command per key
        self._pending = {}
        self._debounce = QTimer(self, singleShot=True, interval=50)
        self._debounce.timeout.connect(self._flush_pending)

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


    # ======================================================== native pages
    def _later(self, key: str, args: list):
        self._pending[key] = args
        self._debounce.start()

    def _flush_pending(self):
        for args in self._pending.values():
            spawn(args)
        self._pending.clear()

    # ---------------------------------------------------- Sound (PipeWire/Pulse via pactl)
    @Slot()
    def refreshSound(self):
        def devices(kind):
            raw = run(["pactl", "-f", "json", "list", kind])
            try:
                items = json.loads(raw) if raw else []
            except json.JSONDecodeError:
                items = []
            out = []
            for d in items:
                name = d.get("name", "")
                if not name or name.endswith(".monitor"):
                    continue
                out.append({"name": name, "desc": d.get("description") or name})
            return out

        def vol(kind):
            m = re.search(r"(\d+)%", run(["pactl", f"get-{kind}-volume", f"@DEFAULT_{kind.upper()}@"]))
            return int(m.group(1)) if m else 0

        self._sinks, self._sources = devices("sinks"), devices("sources")
        dsink, dsrc = run(["pactl", "get-default-sink"]), run(["pactl", "get-default-source"])
        self._sink_idx = next((i for i, d in enumerate(self._sinks) if d["name"] == dsink), -1)
        self._source_idx = next((i for i, d in enumerate(self._sources) if d["name"] == dsrc), -1)
        self._out_vol, self._in_vol = vol("sink"), vol("source")
        self._out_mute = run(["pactl", "get-sink-mute", "@DEFAULT_SINK@"]).endswith("yes")
        self._in_mute = run(["pactl", "get-source-mute", "@DEFAULT_SOURCE@"]).endswith("yes")
        self.soundChanged.emit()

    sinks = Property("QVariantList", lambda s: [d["desc"] for d in s._sinks], notify=soundChanged)
    sources = Property("QVariantList", lambda s: [d["desc"] for d in s._sources], notify=soundChanged)
    sinkIndex = Property(int, lambda s: s._sink_idx, notify=soundChanged)
    sourceIndex = Property(int, lambda s: s._source_idx, notify=soundChanged)
    outputVolume = Property(int, lambda s: s._out_vol, notify=soundChanged)
    inputVolume = Property(int, lambda s: s._in_vol, notify=soundChanged)
    outputMuted = Property(bool, lambda s: s._out_mute, notify=soundChanged)
    inputMuted = Property(bool, lambda s: s._in_mute, notify=soundChanged)
    soundAvailable = Property(bool, lambda s: has("pactl"), constant=True)

    @Slot(int)
    def setOutputDevice(self, i: int):
        if 0 <= i < len(self._sinks):
            self._async(["pactl", "set-default-sink", self._sinks[i]["name"]], lambda *_: self.refreshSound())

    @Slot(int)
    def setInputDevice(self, i: int):
        if 0 <= i < len(self._sources):
            self._async(["pactl", "set-default-source", self._sources[i]["name"]], lambda *_: self.refreshSound())

    @Slot(int)
    def setOutputVolume(self, v: int):
        self._out_vol = v
        self.soundChanged.emit()
        self._later("outvol", ["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{v}%"])

    @Slot(int)
    def setInputVolume(self, v: int):
        self._in_vol = v
        self.soundChanged.emit()
        self._later("invol", ["pactl", "set-source-volume", "@DEFAULT_SOURCE@", f"{v}%"])

    @Slot(bool)
    def setOutputMuted(self, m: bool):
        self._out_mute = m
        self.soundChanged.emit()
        spawn(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "1" if m else "0"])

    @Slot(bool)
    def setInputMuted(self, m: bool):
        self._in_mute = m
        self.soundChanged.emit()
        spawn(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "1" if m else "0"])

    # ---------------------------------------------------- Bluetooth devices (bluetoothctl)
    @staticmethod
    def _parse_bt(out: str) -> list:
        res = []
        for line in out.splitlines():
            m = re.match(r"Device\s+([0-9A-F:]{17})\s+(.*)", line.strip())
            if m:
                res.append((m.group(1), m.group(2).strip()))
        return res

    @Slot()
    def refreshBluetoothDevices(self):
        def got_paired(_ok, out):
            paired = self._parse_bt(out)

            def got_connected(_ok2, out2):
                conn = {mac for mac, _ in self._parse_bt(out2)}
                self._bt_devices = [{"mac": m, "name": n, "connected": m in conn}
                                    for m, n in sorted(paired, key=lambda d: (d[0] not in conn, d[1].lower()))]
                self.bluetoothDevicesChanged.emit()

            self._async(["bluetoothctl", "devices", "Connected"], got_connected, 4000)

        self._async(["bluetoothctl", "devices", "Paired"], got_paired, 4000)

    bluetoothDevices = Property("QVariantList", lambda s: s._bt_devices, notify=bluetoothDevicesChanged)

    def _bt_action(self, *args):
        self._async(["bluetoothctl", *args], lambda *_: self.refreshBluetoothDevices(), 20000)

    @Slot(str)
    def bluetoothConnect(self, mac: str):
        self._bt_action("connect", mac)

    @Slot(str)
    def bluetoothDisconnect(self, mac: str):
        self._bt_action("disconnect", mac)

    @Slot(str)
    def bluetoothRemove(self, mac: str):
        self._bt_action("remove", mac)

    # ---------------------------------------------------- Wi-Fi (NetworkManager via nmcli)
    @staticmethod
    def _nm_fields(line: str) -> list:
        return [f.replace("\\:", ":") for f in re.split(r"(?<!\\):", line)]

    @Slot()
    def refreshWifi(self):
        self._scan_wifi(False)

    @Slot()
    def rescanWifi(self):
        self._scan_wifi(True)

    def _scan_wifi(self, rescan: bool):
        def got_radio(_ok, out):
            self._wifi_on = out.strip() == "enabled"
            self.wifiChanged.emit()

        def got_devs(_ok, out):
            for line in out.splitlines():
                f = self._nm_fields(line)
                if len(f) >= 2 and f[1] == "wifi":
                    self._wifi_iface = f[0]
                    break

        def got_known(_ok, out):
            self._wifi_known = {f[0] for f in map(self._nm_fields, out.splitlines())
                                if len(f) >= 2 and f[1] == "802-11-wireless"}

        def got_list(_ok, out):
            best = {}
            for line in out.splitlines():
                f = self._nm_fields(line)
                if len(f) < 4 or not f[1]:
                    continue
                ssid = f[1]
                net = {"ssid": ssid, "signal": int(f[2] or 0), "secure": bool(f[3].strip()) and f[3] != "--",
                       "active": f[0] == "*", "known": ssid in self._wifi_known}
                old = best.get(ssid)
                if not old or net["active"] or (not old["active"] and net["signal"] > old["signal"]):
                    best[ssid] = net
            self._wifi_list = sorted(best.values(), key=lambda n: (not n["active"], -n["signal"]))
            self.wifiChanged.emit()

        self._async(["nmcli", "-t", "-f", "WIFI", "radio"], got_radio, 3000)
        self._async(["nmcli", "-t", "-f", "DEVICE,TYPE", "device"], got_devs, 3000)
        self._async(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"], got_known, 3000)
        self._async(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list",
                     "--rescan", "yes" if rescan else "no"], got_list, 20000)

    wifiEnabled = Property(bool, lambda s: s._wifi_on, notify=wifiChanged)
    wifiNetworks = Property("QVariantList", lambda s: s._wifi_list, notify=wifiChanged)
    wifiBusy = Property(bool, lambda s: s._wifi_busy, notify=wifiChanged)

    @Slot(bool)
    def setWifiEnabled(self, on: bool):
        self._wifi_on = on
        self.wifiChanged.emit()
        self._async(["nmcli", "radio", "wifi", "on" if on else "off"],
                    lambda *_: QTimer.singleShot(1500, self.refreshWifi))

    @Slot(str, str)
    def wifiConnect(self, ssid: str, password: str):
        if ssid in self._wifi_known and not password:
            args = ["nmcli", "connection", "up", "id", ssid]
        else:
            args = ["nmcli", "device", "wifi", "connect", ssid]
            if password:
                args += ["password", password]
        self._wifi_busy = True
        self.wifiChanged.emit()

        def done(ok, out):
            self._wifi_busy = False
            self.wifiResult.emit(ok, f"Connected to {ssid}" if ok else
                                 f"Couldn't connect to {ssid}. Check the password and try again.")
            self.refreshWifi()
            self._poll_tick()

        self._async(args, done, 45000)

    @Slot()
    def wifiDisconnect(self):
        if self._wifi_iface:
            self._async(["nmcli", "device", "disconnect", self._wifi_iface],
                        lambda *_: (self.refreshWifi(), self._poll_tick()))

    @Slot(str)
    def wifiForget(self, ssid: str):
        self._async(["nmcli", "connection", "delete", "id", ssid], lambda *_: self.refreshWifi())

    # ---------------------------------------------------- Power & battery
    PROFILE_LABELS = {"power-saver": "Best power efficiency", "balanced": "Balanced",
                      "performance": "Best performance"}

    @Slot()
    def refreshPower(self):
        bats = sorted(Path("/sys/class/power_supply").glob("BAT*"))
        self._bat_present = bool(bats)
        if bats:
            try:
                self._bat_pct = int((bats[0] / "capacity").read_text().strip())
                self._bat_status = (bats[0] / "status").read_text().strip()
            except (OSError, ValueError):
                self._bat_present = False
        listing = run(["powerprofilesctl", "list"])
        found = re.findall(r"^\*?\s*([a-z-]+):\s*$", listing, re.M)
        order = ["power-saver", "balanced", "performance"]
        self._profiles = [p for p in order if p in found]
        cur = run(["powerprofilesctl", "get"])
        self._profile_idx = self._profiles.index(cur) if cur in self._profiles else -1
        self.powerChanged.emit()

    batteryPresent = Property(bool, lambda s: s._bat_present, notify=powerChanged)
    batteryPercent = Property(int, lambda s: s._bat_pct, notify=powerChanged)
    batteryStatus = Property(str, lambda s: s._bat_status, notify=powerChanged)
    powerProfiles = Property("QVariantList", lambda s: [s.PROFILE_LABELS[p] for p in s._profiles],
                             notify=powerChanged)
    powerProfileIndex = Property(int, lambda s: s._profile_idx, notify=powerChanged)

    @Slot(int)
    def setPowerProfile(self, i: int):
        if 0 <= i < len(self._profiles):
            self._profile_idx = i
            self.powerChanged.emit()
            self._async(["powerprofilesctl", "set", self._profiles[i]], lambda *_: self.refreshPower())

    # Screen off / sleep timeouts in PowerDevil (Plasma 6 powerdevilrc layout)
    TIMEOUTS_MIN = [1, 2, 3, 5, 10, 15, 20, 25, 30, 45, 60, 120, 180, 240, 300, 0]  # 0 = never

    @Slot(str, str, result=int)
    def powerTimeoutIndex(self, profile: str, what: str) -> int:
        group, enabled_key, sec_key = self._timeout_keys(profile, what)
        if what == "screen":
            if kread("powerdevilrc", group, enabled_key, "true") == "false":
                return len(self.TIMEOUTS_MIN) - 1
            default = "300" if profile == "Battery" else "600"
        else:
            if kread("powerdevilrc", group, enabled_key, "1") == "0":
                return len(self.TIMEOUTS_MIN) - 1
            default = "600" if profile == "Battery" else "900"
        try:
            minutes = int(kread("powerdevilrc", group, sec_key, default)) // 60
        except ValueError:
            minutes = 10
        return min(range(len(self.TIMEOUTS_MIN) - 1), key=lambda i: abs(self.TIMEOUTS_MIN[i] - minutes))

    @staticmethod
    def _timeout_keys(profile: str, what: str):
        if what == "screen":
            return f"{profile}/Display", "TurnOffDisplayWhenIdle", "TurnOffDisplayIdleTimeoutSec"
        return f"{profile}/SuspendAndShutdown", "AutoSuspendAction", "AutoSuspendIdleTimeoutSec"

    @Slot(str, str, int)
    def setPowerTimeout(self, profile: str, what: str, index: int):
        group, enabled_key, sec_key = self._timeout_keys(profile, what)
        minutes = self.TIMEOUTS_MIN[index]
        if what == "screen":
            kwrite("powerdevilrc", group, enabled_key, "false" if minutes == 0 else "true", "bool")
        else:
            kwrite("powerdevilrc", group, enabled_key, "0" if minutes == 0 else "1")
        if minutes:
            kwrite("powerdevilrc", group, sec_key, str(minutes * 60))
        dbus("org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement",
             "org.kde.Solid.PowerManagement.refreshStatus")

    # ---------------------------------------------------- Date & time (timedatectl)
    @Slot()
    def refreshTime(self):
        info = dict(line.split("=", 1) for line in run(["timedatectl", "show"]).splitlines() if "=" in line)
        self._timezone = info.get("Timezone", "")
        self._ntp = info.get("NTP", "no") == "yes"
        if not self._timezones:
            self._timezones = run(["timedatectl", "list-timezones"]).splitlines()
        self.timeChanged.emit()

    timezone = Property(str, lambda s: s._timezone, notify=timeChanged)
    timezones = Property("QVariantList", lambda s: s._timezones, notify=timeChanged)
    autoTime = Property(bool, lambda s: s._ntp, notify=timeChanged)

    @Slot(str)
    def setTimezone(self, tz: str):
        self._async(["timedatectl", "set-timezone", tz], lambda *_: self.refreshTime(), 120000)

    @Slot(bool)
    def setAutoTime(self, on: bool):
        self._ntp = on
        self.timeChanged.emit()
        self._async(["timedatectl", "set-ntp", "true" if on else "false"], lambda *_: self.refreshTime(), 120000)

    # ---------------------------------------------------- About
    @Property("QVariantList", constant=True)
    def deviceSpecs(self):
        def cpu():
            try:
                for line in Path("/proc/cpuinfo").read_text().splitlines():
                    if line.startswith("model name"):
                        return re.sub(r"\s+", " ", line.split(":", 1)[1]).strip()
            except OSError:
                pass
            return os.uname().machine

        def ram():
            try:
                kb = int(re.search(r"MemTotal:\s+(\d+)", Path("/proc/meminfo").read_text()).group(1))
                return f"{kb / 1024 / 1024:.1f} GB"
            except (OSError, AttributeError):
                return ""

        arch = os.uname().machine
        return [
            {"k": "Device name", "v": socket.gethostname()},
            {"k": "Model", "v": self.deviceModel},
            {"k": "Processor", "v": cpu()},
            {"k": "Installed RAM", "v": ram()},
            {"k": "System type", "v": f"64-bit operating system, {arch} processor" if arch.endswith("64")
                                    else f"{arch} processor"},
        ]

    @Property("QVariantList", notify=aboutChanged)
    def osSpecs(self):
        from PySide6 import __version__ as pyside_version
        from PySide6.QtCore import qVersion
        return [
            {"k": "Edition", "v": self.osName},
            {"k": "KDE Plasma", "v": self._plasma_version or "unknown"},
            {"k": "Kernel", "v": os.uname().release},
            {"k": "Graphics platform", "v": os.environ.get("XDG_SESSION_TYPE", "").capitalize() or "unknown"},
            {"k": "Qt", "v": f"{qVersion()} (PySide6 {pyside_version})"},
        ]

    @Slot(str)
    def copyText(self, text: str):
        from PySide6.QtGui import QGuiApplication
        QGuiApplication.clipboard().setText(text)


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
