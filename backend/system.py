"""System: display, night light, brightness, sound, power & battery,
storage, about (device + OS specs, rename PC)."""
from __future__ import annotations

import json
import os
import re
import shutil
import socket
from pathlib import Path

from PySide6.QtCore import Property, QTimer, Signal, Slot

from .util import ANSI, dbus, has, kread, kwin_reconfigure, kwrite, prop, run, spawn

SCALES = [1.0, 1.25, 1.5, 1.75, 2.0]
ROT_TO_INDEX = {1: 0, 2: 1, 4: 2, 8: 3}          # kscreen: none, left, inverted, right
INDEX_TO_ROT = ["normal", "left", "inverted", "right"]


class SystemMixin:
    nightLightChanged = Signal()
    hostChanged = Signal()
    aboutChanged = Signal()
    outputsChanged = Signal()
    brightnessChanged = Signal()
    soundChanged = Signal()
    powerChanged = Signal()

    def _init_system(self):
        self._night = kread("kwinrc", "NightColor", "Active", "false") == "true"
        self._plasma_version = ""
        self._raw_outputs: dict[str, dict] = {}
        self._outputs = self._read_outputs()
        self._bright, self._bright_max = self._read_brightness()
        self._bright_timer = QTimer(self, singleShot=True, interval=60)
        self._bright_timer.timeout.connect(self._apply_brightness)
        self._sinks, self._sources = [], []
        self._sink_idx = self._source_idx = -1
        self._out_vol = self._in_vol = 0
        self._out_mute = self._in_mute = False
        self._bat_present, self._bat_pct, self._bat_status = False, 0, ""
        self._profiles, self._profile_idx = [], -1
        self._async(["plasmashell", "--version"], self._on_plasma_version)

    nightLight = prop("night", bool, nightLightChanged)
    plasmaVersion = prop("plasma_version", str, aboutChanged)
    outputs = prop("outputs", "QVariantList", outputsChanged)

    def _on_plasma_version(self, ok: bool, out: str):
        self._plasma_version = out.split()[-1] if ok and out.split() else ""
        self.aboutChanged.emit()

    @Slot(bool)
    def setNightLight(self, on: bool):
        self._night = on
        self.nightLightChanged.emit()
        kwrite("kwinrc", "NightColor", "Active", "true" if on else "false", "bool")
        kwin_reconfigure()

    # ---------------------------------------------------- Display (kscreen-doctor)
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

    # ---------------------------------------------------- rename PC
    @Slot(str)
    def renameHost(self, name: str):
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,62}", name):
            return
        self._async(["pkexec", "hostnamectl", "set-hostname", name],
                    lambda *_: self.hostChanged.emit(), timeout_ms=120000)


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
