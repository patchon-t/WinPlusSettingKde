"""System: display, sound, notifications, focus, power & battery, storage,
nearby sharing, multitasking, clipboard, remote desktop, for developers, about."""
from __future__ import annotations

import json
import os
import re
import shutil
import socket
import time
from datetime import datetime
from pathlib import Path

from PySide6.QtCore import Property, QTimer, Signal, Slot

from .util import ANSI, HOME, dbus, has, kread, kwin_reconfigure, kwrite, prop, run, spawn

SCALES = [1.0, 1.25, 1.5, 1.75, 2.0]
ROT_TO_INDEX = {1: 0, 2: 1, 4: 2, 8: 3}          # kscreen: none, left, inverted, right
INDEX_TO_ROT = ["normal", "left", "inverted", "right"]
VRR_NAMES = ["never", "automatic", "always"]       # combo order
VRR_FROM_ENUM = {0: 0, 2: 1, 1: 2}                 # libkscreen enum -> combo index


def _sys_unescape(v: str) -> str:
    return (v.replace("\\s", " ").replace("\\t", "\t").replace("\\n", "\n")
             .replace("\\r", "\r").replace("\\\\", "\\"))


def sys_parse_ini(path: Path) -> dict:
    """Tiny KConfig reader: {"Group" or "A/B": {key: value}} (locale keys dropped)."""
    out: dict = {}
    try:
        text = path.read_text(errors="replace")
    except OSError:
        return out
    group = ""
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith(";"):
            continue
        if line.startswith("[") and line.endswith("]"):
            group = "/".join(re.findall(r"\[([^\]]*)\]", line))
            out.setdefault(group, {})
            continue
        if "=" in line:
            k, v = line.split("=", 1)
            k = k.strip()
            if "[" in k:
                if re.search(r"\[\$[a-z]+\]$", k):
                    k = k[:k.index("[")]
                else:
                    continue            # localized key
            out.setdefault(group, {})[k] = _sys_unescape(v.strip())
    return out


def sys_find_key(obj, key):
    """Find `key` in nested busctl --json output; unwrap {"type","data"} variants."""
    if isinstance(obj, dict):
        if key in obj:
            v = obj[key]
            return v["data"] if isinstance(v, dict) and "data" in v else v
        for v in obj.values():
            r = sys_find_key(v, key)
            if r is not None:
                return r
    elif isinstance(obj, list):
        for v in obj:
            r = sys_find_key(v, key)
            if r is not None:
                return r
    return None


def sys_strings(obj) -> list:
    if isinstance(obj, str):
        return [obj]
    out: list = []
    if isinstance(obj, list):
        for v in obj:
            out += sys_strings(v)
    elif isinstance(obj, dict):
        if "data" in obj:
            return sys_strings(obj["data"])
    return out


class SystemMixin:
    nightLightChanged = Signal()
    hostChanged = Signal()
    aboutChanged = Signal()
    outputsChanged = Signal()
    brightnessChanged = Signal()
    soundChanged = Signal()
    powerChanged = Signal()
    sysCfgChanged = Signal()
    sysNightChanged = Signal()
    sysNotifAppsChanged = Signal()
    sysStorageChanged = Signal()
    sysMiscChanged = Signal()

    def _init_system(self):
        self._sys_ini_cache: dict = {}
        self._sys_over: dict = {}
        self._sys_cfg_rev = 0
        self._night = self.sysCfg("kwinrc", "NightColor", "Active", "false") == "true"
        self._plasma_version = ""
        self._raw_outputs: dict[str, dict] = {}
        self._outputs: list = []
        self._bright, self._bright_max = -1, 0
        self._sys_displays: list = []
        self._bright_timer = QTimer(self, singleShot=True, interval=60)
        self._bright_timer.timeout.connect(self._apply_brightness)
        self._sinks, self._sources = [], []
        self._sink_idx = self._source_idx = -1
        self._out_vol = self._in_vol = 0
        self._out_mute = self._in_mute = False
        self._sys_init_sound()
        self._bat_present, self._bat_pct, self._bat_status = False, 0, ""
        self._profiles, self._profile_idx = [], -1
        self._sys_night_status = ""
        self._sys_notif_apps: list = []
        self._sys_init_storage()
        self._sys_init_misc()
        self._async(["plasmashell", "--version"], self._on_plasma_version)
        QTimer.singleShot(0, self.reloadOutputs)
        QTimer.singleShot(0, self.sysRefreshBrightness)

    nightLight = prop("night", bool, nightLightChanged)
    plasmaVersion = prop("plasma_version", str, aboutChanged)
    outputs = prop("outputs", "QVariantList", outputsChanged)
    sysNightStatus = prop("sys_night_status", str, sysNightChanged)
    sysDisplays = prop("sys_displays", "QVariantList", brightnessChanged)

    def _on_plasma_version(self, ok: bool, out: str):
        self._plasma_version = out.split()[-1] if ok and out.split() else ""
        self.aboutChanged.emit()

    # ---------------------------------------------------- generic KConfig access
    # QML pattern:  checked: { Backend.sysCfgRev; return Backend.sysCfg(f, g, k, d) === "true" }
    @Property(int, notify=sysCfgChanged)
    def sysCfgRev(self):
        return self._sys_cfg_rev

    def _sys_bump(self):
        self._sys_cfg_rev += 1
        self.sysCfgChanged.emit()

    def _sys_conf_dirs(self) -> list:
        dirs = [Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config")]
        dirs += [Path(d) for d in (os.environ.get("XDG_CONFIG_DIRS") or "/etc/xdg").split(":") if d]
        return dirs

    def _sys_ini(self, file: str) -> dict:
        merged: dict = {}
        for d in reversed(self._sys_conf_dirs()):          # user file wins
            p = d / file
            try:
                mt = p.stat().st_mtime_ns
            except OSError:
                continue
            hit = self._sys_ini_cache.get(str(p))
            if not hit or hit[0] != mt:
                hit = (mt, sys_parse_ini(p))
                self._sys_ini_cache[str(p)] = hit
            for g, kv in hit[1].items():
                merged.setdefault(g, {}).update(kv)
        return merged

    @Slot(str, str, str, str, result=str)
    def sysCfg(self, file: str, group: str, key: str, default: str = "") -> str:
        k = (file, group, key)
        if k in self._sys_over:
            v = self._sys_over[k]
            return default if v is None else v
        return self._sys_ini(file).get(group, {}).get(key, default)

    @Slot(str, str, str, str)
    @Slot(str, str, str, str, str)
    @Slot(str, str, str, str, str, bool)
    def sysCfgSet(self, file: str, group: str, key: str, value: str, kind: str = "",
                  reconfigure: bool = False):
        k = (file, group, key)
        self._sys_over[k] = value
        self._sys_bump()
        args = ["kwriteconfig6", "--file", file]
        for g in group.split("/"):
            args += ["--group", g]
        args += ["--key", key]
        if kind:
            args += ["--type", kind]
        args += ["--notify", value]

        def done(ok, _out):
            if self._sys_over.get(k) == value:
                self._sys_over.pop(k, None)
            if reconfigure:
                kwin_reconfigure()
            self._sys_bump()
        self._async(args, done)

    @Slot(str, str, str)
    def sysCfgDel(self, file: str, group: str, key: str):
        k = (file, group, key)
        self._sys_over[k] = None
        self._sys_bump()
        args = ["kwriteconfig6", "--file", file]
        for g in group.split("/"):
            args += ["--group", g]
        args += ["--key", key, "--delete", "--notify"]

        def done(ok, _out):
            if k in self._sys_over and self._sys_over[k] is None:
                self._sys_over.pop(k, None)
            self._sys_bump()
        self._async(args, done)

    @Slot()
    def sysCfgReload(self):
        self._sys_over.clear()
        self._sys_ini_cache.clear()
        self._sys_bump()

    @Slot()
    def sysKwinReconfigure(self):
        kwin_reconfigure()

    @Slot("QVariantList")
    def sysLaunch(self, args):
        spawn([str(a) for a in args])

    # ---------------------------------------------------- Night light
    @Slot(bool)
    def setNightLight(self, on: bool):
        self._night = on
        self.nightLightChanged.emit()
        self.sysCfgSet("kwinrc", "NightColor", "Active", "true" if on else "false", "bool", True)
        QTimer.singleShot(600, self.sysRefreshNightLight)

    @Slot(bool)
    def sysNightTurnOn(self, on: bool):
        """Win11 'Turn on now' / 'Turn off now' = constant mode on/off."""
        self._night = on
        self.nightLightChanged.emit()
        if on:
            self.sysCfgSet("kwinrc", "NightColor", "Mode", "Constant", "")
        self.sysCfgSet("kwinrc", "NightColor", "Active", "true" if on else "false", "bool", True)
        QTimer.singleShot(600, self.sysRefreshNightLight)

    @Slot(bool)
    def sysNightSchedule(self, on: bool):
        self.sysCfgSet("kwinrc", "NightColor", "Mode", "DarkLight" if on else "Constant", "", True)
        QTimer.singleShot(600, self.sysRefreshNightLight)

    @Slot(int)
    def sysNightPreview(self, kelvin: int):
        self._later("sysnl", ["dbus-send", "--session", "--dest=org.kde.KWin", "--type=method_call",
                              "/org/kde/KWin/NightLight", "org.kde.KWin.NightLight.preview",
                              f"uint32:{int(kelvin)}"])

    @Slot(int)
    def sysNightCommit(self, kelvin: int):
        self.sysCfgSet("kwinrc", "NightColor", "NightTemperature", str(int(kelvin)), "", True)
        dbus("org.kde.KWin", "/org/kde/KWin/NightLight", "org.kde.KWin.NightLight.stopPreview")
        QTimer.singleShot(600, self.sysRefreshNightLight)

    @Slot()
    def sysRefreshNightLight(self):
        self._night = self.sysCfg("kwinrc", "NightColor", "Active", "false") == "true"
        self.nightLightChanged.emit()
        props = ["running", "daylight", "currentTemperature", "scheduledTransitionDateTime"]

        def done(ok, out):
            vals = [ln.split()[-1] for ln in out.splitlines() if ln.strip()]
            if not ok or len(vals) < 4:
                self._sys_night_status = ""
            else:
                running, daylight = vals[0] == "true", vals[1] == "true"
                try:
                    ts = int(vals[3])
                except ValueError:
                    ts = 0
                when = ""
                if ts > 0:
                    when = datetime.fromtimestamp(ts if ts < 10**11 else ts / 1000).strftime("%I:%M %p").lstrip("0")
                if not self._night:
                    self._sys_night_status = "Night light is off"
                elif running and when:
                    self._sys_night_status = f"Night light is on and will turn off at {when}" if not daylight \
                        else f"Night light will turn on at {when}"
                elif running:
                    self._sys_night_status = "Night light is on"
                elif when:
                    self._sys_night_status = f"Night light will turn on at {when}"
                else:
                    self._sys_night_status = "Night light is on"
            self.sysNightChanged.emit()
        self._async(["busctl", "--user", "get-property", "org.kde.KWin", "/org/kde/KWin/NightLight",
                     "org.kde.KWin.NightLight", *props], done)

    # ---------------------------------------------------- Display (kscreen-doctor)
    @Slot()
    def reloadOutputs(self):
        def got_json(ok, raw):
            if not ok or not raw.strip():
                self._outputs, self._raw_outputs = [], {}
                self.outputsChanged.emit()
                return
            self._async(["kscreen-doctor", "-o"], lambda ok2, txt: self._sys_on_outputs(raw, ANSI.sub("", txt)))
        self._async(["kscreen-doctor", "-j"], got_json, 8000)

    def _sys_on_outputs(self, raw: str, text: str):
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            return
        self._outputs = self._build_outputs(data, text)
        self.outputsChanged.emit()

    def _build_outputs(self, data: dict, text: str) -> list:
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
            block = self._sys_out_block(text, name)
            hdr = self._hdr_state(text, name)
            near = min(range(len(SCALES)), key=lambda i: abs(SCALES[i] - scale))
            self._raw_outputs[name] = {"modes": modes, "size": (cw, ch), "rate": cur_rate}
            abm = re.search(r"Adaptive backlight modulation:\s*supported, set to (\d)", block)
            tradeoff = re.search(r"Color power preference:\s*(prefer accuracy|prefer efficiency)", block)
            src = re.search(r"Color profile source:\s*(\w+)", block)
            outs.append({
                "name": name,
                "label": str(n),
                "title": f"Display {n}",
                "enabled": bool(o.get("enabled")),
                "x": pos.get("x", 0), "y": pos.get("y", 0),
                "w": max(lw / scale, 1), "h": max(lh / scale, 1),
                "scale": scale,
                "scaleIndex": near,
                "scaleCustom": abs(SCALES[near] - scale) > 0.001,
                "scalePercent": round(scale * 100),
                "rotationIndex": ROT_TO_INDEX.get(rot, 0),
                "resolutions": [f"{w} × {h}" + ("  (Recommended)" if (w, h) in pref_sizes else "")
                                for w, h in sizes],
                "resolutionKeys": res_keys,
                "resIndex": res_keys.index(f"{cw}x{ch}") if f"{cw}x{ch}" in res_keys else 0,
                "rates": [f"{r:g} Hz" for r in rates],
                "rateValues": rates,
                "rateIndex": rates.index(cur_rate) if cur_rate in rates else 0,
                "curW": cw, "curH": ch, "curRate": cur_rate,
                "hdrSupported": hdr in ("enabled", "disabled") or "hdr" in o,
                "hdr": bool(o.get("hdr")) if "hdr" in o else hdr == "enabled",
                "sdrSupported": "sdr-brightness" in o,
                "sdrBrightness": int(o.get("sdr-brightness") or 200),
                "wcgSupported": "wcg" in o,
                "wcg": bool(o.get("wcg")),
                "vrrSupported": "vrrPolicy" in o,
                "vrrIndex": VRR_FROM_ENUM.get(int(o.get("vrrPolicy", 0)), 0),
                "rgbSupported": "rgbRange" in o,
                "rgbIndex": int(o.get("rgbRange", 0)),
                "bpcSupported": "maxBpc" in o,
                "maxBpc": int(o.get("maxBpc", 0)),
                "iccSupported": "iccProfilePath" in o,
                "iccPath": o.get("iccProfilePath") or "",
                "colorSource": src.group(1) if src else "",
                "tradeoff": "accuracy" if tradeoff and tradeoff.group(1) == "prefer accuracy"
                            else ("efficiency" if tradeoff else ""),
                "abmSupported": bool(abm),
                "abm": int(abm.group(1)) if abm else 0,
                "priority": int(o.get("priority") or 0),
                "isMain": int(o.get("priority") or 0) == 1,
                "replicated": int(o.get("replicationSource") or 0) != 0,
            })
        return outs

    @staticmethod
    def _sys_out_block(text: str, name: str) -> str:
        m = re.search(rf"Output:\s*\d+\s+{re.escape(name)}\b(.*?)(?=\nOutput:|\Z)", text, re.S)
        return m.group(1) if m else ""

    @staticmethod
    def _hdr_state(text: str, name: str) -> str:
        m = re.search(rf"Output:\s*\d+\s+{re.escape(name)}\b(.*?)(?=\nOutput:|\Z)", text, re.S)
        if not m:
            return ""
        h = re.search(r"HDR:\s*(\w+)", m.group(1))
        return h.group(1).lower() if h else ""

    # ---------------------------------------------------- Brightness
    @Slot()
    def sysRefreshBrightness(self):
        """Per-display brightness (internal + DDC/CI) from org.kde.ScreenBrightness;
        falls back to the PowerDevil internal-panel interface."""
        svc = "org.kde.ScreenBrightness"

        def names_done(ok, out):
            names: list = []
            if ok:
                try:
                    names = sys_strings(json.loads(out))
                except json.JSONDecodeError:
                    names = []
            if not names:
                self._sys_displays = []
                self._sys_legacy_brightness()
                return
            pending = {"n": len(names), "items": []}

            def one(nm):
                def got(ok2, out2):
                    pending["n"] -= 1
                    if ok2:
                        try:
                            j = json.loads(out2)
                            mx = sys_find_key(j, "MaxBrightness")
                            cur = sys_find_key(j, "Brightness")
                            if isinstance(mx, int) and mx > 0 and isinstance(cur, int):
                                pending["items"].append({
                                    "path": f"/org/kde/ScreenBrightness/{nm}",
                                    "label": str(sys_find_key(j, "Label") or nm),
                                    "internal": bool(sys_find_key(j, "IsInternal")),
                                    "max": mx, "value": round(cur * 100 / mx)})
                        except (json.JSONDecodeError, TypeError):
                            pass
                    if pending["n"] == 0:
                        self._sys_displays = sorted(pending["items"], key=lambda d: not d["internal"])
                        self.brightnessChanged.emit()
                        if not self._sys_displays:
                            self._sys_legacy_brightness()
                return got
            for nm in names:
                self._async(["busctl", "--user", "--json=short", "call", svc,
                             f"/org/kde/ScreenBrightness/{nm}", "org.freedesktop.DBus.Properties",
                             "GetAll", "s", "org.kde.ScreenBrightness.Display"], one(nm))
        self._async(["busctl", "--user", "--json=short", "get-property", svc, "/org/kde/ScreenBrightness",
                     svc, "DisplaysDBusNames"], names_done)

    def _sys_legacy_brightness(self):
        svc = "org.kde.Solid.PowerManagement"
        path = "/org/kde/Solid/PowerManagement/Actions/BrightnessControl"
        iface = "org.kde.Solid.PowerManagement.Actions.BrightnessControl"

        def cur_done(ok, out):
            m = re.search(r"int32\s+(-?\d+)", out)

            def max_done(ok2, out2):
                mx = re.search(r"int32\s+(-?\d+)", out2)
                if m and mx and int(mx.group(1)) > 0:
                    self._bright, self._bright_max = int(m.group(1)), int(mx.group(1))
                self.brightnessChanged.emit()
            self._async(["dbus-send", "--session", f"--dest={svc}", "--print-reply", path,
                         iface + ".brightnessMax"], max_done)
        self._async(["dbus-send", "--session", f"--dest={svc}", "--print-reply", path,
                     iface + ".brightness"], cur_done)

    @Slot(str, int)
    def sysSetDisplayBrightness(self, path: str, percent: int):
        for d in self._sys_displays:
            if d["path"] == path:
                d["value"] = percent
                self.brightnessChanged.emit()
                self._later("sysbr" + path, [
                    "busctl", "--user", "call", "org.kde.ScreenBrightness", path,
                    "org.kde.ScreenBrightness.Display", "SetBrightness", "iu",
                    str(round(percent * d["max"] / 100)), "0"])
                return

    @Property(bool, notify=brightnessChanged)
    def brightnessAvailable(self):
        return self._bright_max > 0 or bool(self._sys_displays)

    @Property(int, notify=brightnessChanged)
    def brightness(self):
        if self._sys_displays:
            return self._sys_displays[0]["value"]
        return round(self._bright * 100 / self._bright_max) if self._bright_max else 0

    @Slot(int)
    def setBrightness(self, percent: int):
        if self._sys_displays:
            self.sysSetDisplayBrightness(self._sys_displays[0]["path"], percent)
            return
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

    # ---------------------------------------------------- display slots
    def _kscreen(self, *ops: str):
        self._async(["kscreen-doctor", *ops], lambda *_: self.reloadOutputs())

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

    @Slot(str, bool)
    def sysSetWcg(self, name: str, on: bool):
        self._kscreen(f"output.{name}.wcg.{'enable' if on else 'disable'}")

    @Slot(str, int)
    def sysSetSdrBrightness(self, name: str, nits: int):
        self._kscreen(f"output.{name}.sdr-brightness.{max(50, min(10000, nits))}")

    @Slot(str, int)
    def sysSetVrr(self, name: str, index: int):
        self._kscreen(f"output.{name}.vrrpolicy.{VRR_NAMES[index]}")

    @Slot(str, int)
    def sysSetRgbRange(self, name: str, index: int):
        self._kscreen(f"output.{name}.rgbrange.{['automatic', 'full', 'limited'][index]}")

    @Slot(str, int)
    def sysSetMaxBpc(self, name: str, bpc: int):
        self._kscreen(f"output.{name}.maxbpc.{'automatic' if bpc == 0 else bpc}")

    @Slot(str, int)
    def sysSetAbm(self, name: str, level: int):
        self._kscreen(f"output.{name}.abm.{level}")

    @Slot(str, bool)
    def sysSetColorAccuracy(self, name: str, accurate: bool):
        self._kscreen(f"output.{name}.colorPowerTradeoff.{'preferAccuracy' if accurate else 'preferEfficiency'}")

    @Slot(str)
    def sysSetMainDisplay(self, name: str):
        self._kscreen(f"output.{name}.priority.1")

    @Slot(str, int, int)
    def sysSetOutputPosition(self, name: str, x: int, y: int):
        self._kscreen(f"output.{name}.position.{x},{y}")

    @Slot(str, str)
    def sysSetColorProfile(self, name: str, path: str):
        """path '' = standard sRGB, 'edid' = display's own profile, else an ICC file."""
        if path == "":
            self._kscreen(f"output.{name}.colorProfileSource.sRGB")
        elif path == "edid":
            self._kscreen(f"output.{name}.colorProfileSource.EDID")
        else:
            self._kscreen(f"output.{name}.iccprofile.{path}", f"output.{name}.colorProfileSource.ICC")

    @Slot(result="QVariantList")
    def sysIccProfiles(self):
        """ICC files from the standard colour-profile directories."""
        dirs = [HOME / ".local/share/icc", HOME / ".local/share/color/icc",
                Path("/usr/share/color/icc"), Path("/usr/local/share/color/icc")]
        found = []
        for d in dirs:
            if d.is_dir():
                for p in sorted(d.rglob("*")):
                    if p.suffix.lower() in (".icc", ".icm"):
                        found.append({"name": p.stem, "path": str(p)})
        return found

    @Property(int, notify=outputsChanged)
    def displayModeIndex(self):
        enabled = [i for i, o in enumerate(self._outputs) if o["enabled"]]
        if len(self._outputs) > 1 and len(enabled) == 1:
            return enabled[0] + 2
        if any(o["replicated"] for o in self._outputs):
            return 1
        return 0

    @Slot(int)
    def setDisplayMode(self, index: int):
        names = [o["name"] for o in self._outputs]
        if not names:
            return
        if index == 0:
            self._kscreen(*[f"output.{n}.enable" for n in names],
                          *[f"output.{n}.mirror.none" for n in names])
        elif index == 1:
            main = names[0]
            self._kscreen(*[f"output.{n}.enable" for n in names],
                          *[f"output.{n}.mirror.{main}" for n in names[1:]])
        elif index - 2 < len(names):
            keep = names[index - 2]
            self._kscreen(f"output.{keep}.enable", f"output.{keep}.mirror.none",
                          *[f"output.{n}.disable" for n in names if n != keep])

    @Slot()
    def identifyDisplays(self):
        dbus("org.kde.KWin", "/org/kde/KWin/Effect/OutputLocator1",
             "org.kde.KWin.Effect.OutputLocator1.show")

    # ---------------------------------------------------- misc device facts (used by Home/About)
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

    @Property(float, constant=True)
    def storageRatio(self):
        u = shutil.disk_usage("/")
        return u.used / u.total if u.total else 0.0

    @Property(str, constant=True)
    def storageText(self):
        u = shutil.disk_usage("/")
        gb = 1024 ** 3
        return f"{u.used / gb:.0f} GB used of {u.total / gb:.0f} GB"

    @Slot(str)
    def renameHost(self, name: str):
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,62}", name):
            return
        self._async(["pkexec", "hostnamectl", "set-hostname", name],
                    lambda *_: self.hostChanged.emit(), timeout_ms=120000)

    # ---------------------------------------------------- Sound (PipeWire/Pulse via pactl)
    def _sys_init_sound(self):
        self._sys_snd_raw = {"sinks": [], "sources": [], "cards": [], "sink-inputs": [], "source-outputs": []}
        self._sys_def_sink = self._sys_def_source = ""
        self._sys_apps: list = []
        self._sys_cards: list = []
        self._sys_sink_devs: list = []
        self._sys_source_devs: list = []

    @staticmethod
    def _sys_json_list(out: str) -> list:
        try:
            data = json.loads(out) if out.strip() else []
        except json.JSONDecodeError:
            return []
        return data if isinstance(data, list) else []

    @staticmethod
    def _sys_channels(d: dict) -> dict:
        """{channel name: percent} from a pactl JSON device / stream."""
        res = {}
        for ch, v in (d.get("volume") or {}).items():
            if not isinstance(v, dict):
                continue
            pct = str(v.get("value_percent", "")).rstrip("%")
            try:
                res[ch] = int(pct)
            except ValueError:
                try:
                    res[ch] = round(int(v.get("value", 0)) * 100 / 65536)
                except (TypeError, ValueError):
                    res[ch] = 0
        return res

    def _sys_dev(self, kind: str, d: dict) -> dict:
        chans = self._sys_channels(d)
        vals = list(chans.values())
        avg = round(sum(vals) / len(vals)) if vals else 0
        left = next((v for k, v in chans.items() if "left" in k), None)
        right = next((v for k, v in chans.items() if "right" in k), None)
        balance = 0
        if left is not None and right is not None and max(left, right) > 0:
            balance = round((right - left) * 100 / max(left, right))
        ports = [p for p in (d.get("ports") or []) if p.get("availability") != "not available"]
        names = [p.get("name", "") for p in ports]
        active = d.get("active_port") or ""
        name = d.get("name", "")
        return {
            "kind": kind, "name": name, "index": d.get("index", -1),
            "desc": d.get("description") or name,
            "volume": min(avg, 150), "mute": bool(d.get("mute")),
            "balance": balance, "canBalance": left is not None and right is not None,
            "channels": list(chans.keys()),
            "ports": [p.get("description") or p.get("name", "") for p in ports],
            "portNames": names, "portIndex": names.index(active) if active in names else -1,
            "card": self._sys_card_for(name),
        }

    def _sys_card_for(self, dev_name: str) -> str:
        """Card that owns a sink/source (matched by the shared bus/address part of the name)."""
        tail = dev_name.split(".", 1)[1] if "." in dev_name else dev_name
        best = ""
        for c in self._sys_snd_raw["cards"]:
            cn = c.get("name", "")
            ctail = cn.split(".", 1)[1] if "." in cn else cn
            if ctail and tail.startswith(ctail) and len(ctail) > len(best):
                best = cn
        return best

    def _sys_snd_rebuild(self):
        raw = self._sys_snd_raw
        old_state = (self._sinks, self._sources, self._sys_cards)
        self._sys_cards = []
        for c in raw["cards"]:
            profs = c.get("profiles") or {}
            usable = [(p.get("priority", 0), n) for n, p in profs.items()
                      if n != "off" and p.get("available", True) not in (False, "no")]
            self._sys_cards.append({
                "name": c.get("name", ""), "desc": (c.get("properties") or {}).get("device.description")
                or c.get("description") or c.get("name", ""),
                "disabled": c.get("active_profile") == "off",
                "best": max(usable)[1] if usable else ""})
        self._sinks = [self._sys_dev("sink", d) for d in raw["sinks"]
                       if d.get("name") and not d["name"].endswith(".monitor")]
        self._sources = [self._sys_dev("source", d) for d in raw["sources"]
                         if d.get("name") and not d["name"].endswith(".monitor")]
        for lst, dflt in ((self._sinks, self._sys_def_sink), (self._sources, self._sys_def_source)):
            for d in lst:
                d["isDefault"] = d["name"] == dflt
        self._sink_idx = next((i for i, d in enumerate(self._sinks) if d["isDefault"]), -1)
        self._source_idx = next((i for i, d in enumerate(self._sources) if d["isDefault"]), -1)
        self._out_vol = self._sinks[self._sink_idx]["volume"] if self._sink_idx >= 0 else 0
        self._in_vol = self._sources[self._source_idx]["volume"] if self._source_idx >= 0 else 0
        self._out_mute = self._sinks[self._sink_idx]["mute"] if self._sink_idx >= 0 else False
        self._in_mute = self._sources[self._source_idx]["mute"] if self._source_idx >= 0 else False
        self._sys_sink_devs, self._sys_source_devs = self._sinks, self._sources
        if old_state != (self._sinks, self._sources, self._sys_cards):
            self.soundChanged.emit()

    @Slot()
    def refreshSound(self):
        def store(key):
            def cb(ok, out):
                self._sys_snd_raw[key] = self._sys_json_list(out) if ok else []
                self._sys_snd_rebuild()
            return cb

        def dflt(attr):
            def cb(ok, out):
                setattr(self, attr, out.strip() if ok else "")
                self._sys_snd_rebuild()
            return cb
        self._async(["pactl", "-f", "json", "list", "cards"], store("cards"))
        self._async(["pactl", "-f", "json", "list", "sinks"], store("sinks"))
        self._async(["pactl", "-f", "json", "list", "sources"], store("sources"))
        self._async(["pactl", "get-default-sink"], dflt("_sys_def_sink"))
        self._async(["pactl", "get-default-source"], dflt("_sys_def_source"))

    sinks = Property("QVariantList", lambda s: [d["desc"] for d in s._sinks], notify=soundChanged)
    sources = Property("QVariantList", lambda s: [d["desc"] for d in s._sources], notify=soundChanged)
    sinkIndex = Property(int, lambda s: s._sink_idx, notify=soundChanged)
    sourceIndex = Property(int, lambda s: s._source_idx, notify=soundChanged)
    outputVolume = Property(int, lambda s: s._out_vol, notify=soundChanged)
    inputVolume = Property(int, lambda s: s._in_vol, notify=soundChanged)
    outputMuted = Property(bool, lambda s: s._out_mute, notify=soundChanged)
    inputMuted = Property(bool, lambda s: s._in_mute, notify=soundChanged)
    soundAvailable = Property(bool, lambda s: has("pactl"), constant=True)
    sysSinkDevices = Property("QVariantList", lambda s: s._sys_sink_devs, notify=soundChanged)
    sysSourceDevices = Property("QVariantList", lambda s: s._sys_source_devs, notify=soundChanged)
    sysSoundCards = Property("QVariantList", lambda s: s._sys_cards, notify=soundChanged)
    sysMixerApps = Property("QVariantList", lambda s: s._sys_apps, notify=soundChanged)

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

    # --- per-device (device properties page)
    @staticmethod
    def _sys_balance_args(dev: dict, pct: int, balance: int) -> list:
        left = round(pct * (1 - max(0, balance) / 100))
        right = round(pct * (1 + min(0, balance) / 100))
        out = []
        for ch in dev.get("channels") or [""]:
            out.append(f"{left if 'left' in ch else right if 'right' in ch else pct}%")
        return out or [f"{pct}%"]

    def _sys_find_dev(self, kind: str, name: str):
        lst = self._sinks if kind == "sink" else self._sources
        return next((d for d in lst if d["name"] == name), None)

    @Slot(str, str, int, int)
    def sysSetDeviceVolume(self, kind: str, name: str, pct: int, balance: int):
        dev = self._sys_find_dev(kind, name)
        if not dev:
            return
        dev["volume"], dev["balance"] = pct, balance
        self.soundChanged.emit()
        self._later(f"sysdv{kind}{name}", ["pactl", f"set-{kind}-volume", name,
                                           *self._sys_balance_args(dev, pct, balance)])

    @Slot(str, str, bool)
    def sysSetDeviceMute(self, kind: str, name: str, mute: bool):
        dev = self._sys_find_dev(kind, name)
        if dev:
            dev["mute"] = mute
            self.soundChanged.emit()
        spawn(["pactl", f"set-{kind}-mute", name, "1" if mute else "0"])

    @Slot(str, str, int)
    def sysSetDevicePort(self, kind: str, name: str, port_index: int):
        dev = self._sys_find_dev(kind, name)
        if dev and 0 <= port_index < len(dev["portNames"]):
            self._async(["pactl", f"set-{kind}-port", name, dev["portNames"][port_index]],
                        lambda *_: self.refreshSound())

    @Slot(str, str)
    def sysMakeDefault(self, kind: str, name: str):
        self._async(["pactl", f"set-default-{kind}", name], lambda *_: self.refreshSound())

    @Slot(str)
    def sysDisableCard(self, card: str):
        if card:
            self._async(["pactl", "set-card-profile", card, "off"], lambda *_: self.refreshSound())

    @Slot(str)
    def sysEnableCard(self, card: str):
        best = next((c["best"] for c in self._sys_cards if c["name"] == card), "")
        if best:
            self._async(["pactl", "set-card-profile", card, best], lambda *_: self.refreshSound())

    # --- volume mixer
    @Slot()
    def sysRefreshMixer(self):
        def store(key):
            def cb(ok, out):
                self._sys_snd_raw[key] = self._sys_json_list(out) if ok else []
                self._sys_mixer_rebuild()
            return cb
        self.refreshSound()
        self._async(["pactl", "-f", "json", "list", "sink-inputs"], store("sink-inputs"))
        self._async(["pactl", "-f", "json", "list", "source-outputs"], store("source-outputs"))

    def _sys_mixer_rebuild(self):
        apps = []
        for kind, key, devkey, devs in (("out", "sink-inputs", "sink", self._sinks),
                                        ("in", "source-outputs", "source", self._sources)):
            idx_by_dev = {}
            for i, d in enumerate(devs):
                idx_by_dev[d["index"]] = i
            for s in self._sys_snd_raw[key]:
                pr = s.get("properties") or {}
                name = pr.get("application.name") or pr.get("media.name") or ""
                if not name or pr.get("media.name") == "Peak detect" or pr.get("application.id") == "org.PulseAudio.pavucontrol":
                    continue
                ch = self._sys_channels(s)
                avg = round(sum(ch.values()) / len(ch)) if ch else 0
                apps.append({
                    "kind": kind, "index": s.get("index", -1), "name": name,
                    "icon": pr.get("application.icon_name") or "",
                    "desc": pr.get("media.name") or "",
                    "volume": min(avg, 150), "mute": bool(s.get("mute")),
                    "device": idx_by_dev.get(s.get(devkey), -1)})
        if apps != self._sys_apps:
            self._sys_apps = apps
            self.soundChanged.emit()

    @Slot(str, int, int)
    def sysSetAppVolume(self, kind: str, index: int, pct: int):
        sub = "sink-input" if kind == "out" else "source-output"
        for a in self._sys_apps:
            if a["kind"] == kind and a["index"] == index:
                a["volume"] = pct          # no emit: would rebuild the slider being dragged
        self._later(f"sysapp{kind}{index}", ["pactl", f"set-{sub}-volume", str(index), f"{pct}%"])

    @Slot(str, int, bool)
    def sysSetAppMute(self, kind: str, index: int, mute: bool):
        sub = "sink-input" if kind == "out" else "source-output"
        for a in self._sys_apps:
            if a["kind"] == kind and a["index"] == index:
                a["mute"] = mute
        self.soundChanged.emit()
        spawn(["pactl", f"set-{sub}-mute", str(index), "1" if mute else "0"])

    @Slot(str, int, int)
    def sysMoveApp(self, kind: str, index: int, device: int):
        devs = self._sinks if kind == "out" else self._sources
        if 0 <= device < len(devs):
            sub = "move-sink-input" if kind == "out" else "move-source-output"
            self._async(["pactl", sub, str(index), devs[device]["name"]],
                        lambda *_: self.sysRefreshMixer())

    # ---------------------------------------------------- Notifications / Do not disturb / Focus
    NOTIF_RC = "plasmanotifyrc"

    def _sys_until(self):
        """DND end as naive local datetime, or None."""
        raw = self.sysCfg(self.NOTIF_RC, "DoNotDisturb", "Until", "")
        parts = [p.strip() for p in raw.split(",")] if raw else []
        if len(parts) < 6:
            return None
        try:
            y, mo, d, h, mi = (int(float(p)) for p in parts[:5])
            sec = int(float(parts[5]))
            dt = datetime(y, mo, d, h, mi, sec)
            if len(parts) >= 7:
                from zoneinfo import ZoneInfo
                try:
                    dt = dt.replace(tzinfo=ZoneInfo(parts[6])).astimezone().replace(tzinfo=None)
                except Exception:
                    dt = dt.replace(tzinfo=None)
            return dt
        except (ValueError, OverflowError):
            return None

    @Slot(result=int)
    def sysDndRemaining(self) -> int:
        """Seconds of do-not-disturb left: 0 = off, -1 = until turned off."""
        dt = self._sys_until()
        if dt is None:
            return 0
        left = (dt - datetime.now()).total_seconds()
        if left <= 0:
            return 0
        return -1 if dt.year >= 2900 else int(left)

    @Slot(bool)
    def sysDndSet(self, on: bool):
        if on:
            self.sysCfgSet(self.NOTIF_RC, "DoNotDisturb", "Until", "2999,12,31,0,0,0", "")
        else:
            self.sysCfgDel(self.NOTIF_RC, "DoNotDisturb", "Until")

    @Slot(int)
    def sysFocusStart(self, minutes: int):
        end = datetime.now().timestamp() + minutes * 60
        e = datetime.fromtimestamp(end)
        self.sysCfgSet(self.NOTIF_RC, "DoNotDisturb", "Until",
                       f"{e.year},{e.month},{e.day},{e.hour},{e.minute},{e.second}", "")

    @Slot()
    def sysFocusStop(self):
        self.sysCfgDel(self.NOTIF_RC, "DoNotDisturb", "Until")

    # --- apps and other senders (same discovery as the Plasma notifications KCM:
    #     plasma-workspace/kcms/notifications/sourcesmodel.cpp)
    @staticmethod
    def _sys_data_dirs() -> list:
        home = Path(os.environ.get("XDG_DATA_HOME") or HOME / ".local/share")
        dirs = [home] + [Path(d) for d in (os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share").split(":") if d]
        for extra in (HOME / ".local/share/flatpak/exports/share", Path("/var/lib/flatpak/exports/share")):
            if extra not in dirs:
                dirs.append(extra)
        return dirs

    @staticmethod
    def _sys_desktop_entry(path: Path) -> dict:
        """Name / Icon / flags of the [Desktop Entry] group of a .desktop file."""
        res: dict = {}
        try:
            for line in path.read_text(errors="replace").splitlines():
                line = line.strip()
                if line.startswith("[") and line != "[Desktop Entry]":
                    if res:
                        break
                    continue
                if "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    if k in ("Name", "Icon", "NoDisplay", "X-GNOME-UsesNotifications", "Exec", "Categories"):
                        res.setdefault(k, v.strip())
        except OSError:
            pass
        return res

    @Slot()
    def sysRefreshNotifApps(self):
        apps: dict = {}          # id -> {id, name, icon, kind}
        desktops: dict = {}      # desktop entry name -> parsed (first dir wins)
        for d in self._sys_data_dirs():
            adir = d / "applications"
            if not adir.is_dir():
                continue
            for p in adir.rglob("*.desktop"):
                name = ".".join(p.relative_to(adir).with_suffix("").parts)
                if name not in desktops:
                    desktops[name] = p
        uses = {}
        for name, p in desktops.items():
            try:
                head = p.read_text(errors="replace")
            except OSError:
                continue
            if "X-GNOME-UsesNotifications" not in head:
                continue
            e = self._sys_desktop_entry(p)
            if e.get("X-GNOME-UsesNotifications", "").lower() == "true" and e.get("NoDisplay", "").lower() != "true":
                uses[name] = e

        def add(entry_id, name, icon, kind):
            if entry_id and entry_id not in apps:
                apps[entry_id] = {"id": entry_id, "name": name or entry_id, "icon": icon or "", "kind": kind}

        for d in self._sys_data_dirs():
            for sub in ("knotifications6", "knotifications5"):
                nd = d / sub
                if not nd.is_dir():
                    continue
                for p in sorted(nd.glob("*.notifyrc")):
                    g = sys_parse_ini(p).get("Global", {})
                    de = g.get("DesktopEntry", "")
                    if de:
                        ent = self._sys_desktop_entry(desktops[de]) if de in desktops else {}
                        if ent.get("NoDisplay", "").lower() == "true":
                            continue
                        add(de, ent.get("Name") or g.get("Name"), ent.get("Icon") or g.get("IconName"), "app")
                    else:
                        add("svc:" + p.stem, g.get("Name"), g.get("IconName"), "service")
        for name, e in uses.items():
            add(name, e.get("Name"), e.get("Icon"), "app")
        seen = self._sys_ini(self.NOTIF_RC)
        for grp in seen:
            if grp.startswith("Applications/") and grp.count("/") == 1:
                de = grp.split("/", 1)[1]
                if de in desktops and de not in apps:
                    ent = self._sys_desktop_entry(desktops[de])
                    if ent.get("NoDisplay", "").lower() != "true":
                        add(de, ent.get("Name"), ent.get("Icon"), "app")
        lst = sorted(apps.values(), key=lambda a: (a["kind"] != "app", a["name"].lower()))
        self._sys_notif_apps = lst
        self.sysNotifAppsChanged.emit()

    sysNotifApps = Property("QVariantList", lambda s: s._sys_notif_apps, notify=sysNotifAppsChanged)

    @Slot(str, str, result=str)
    def sysNotifGroup(self, kind: str, app_id: str) -> str:
        """KConfig group of a sender in plasmanotifyrc."""
        if kind == "service":
            return "Services/" + app_id.removeprefix("svc:")
        return "Applications/" + app_id

    @Slot(str, str, bool)
    def sysNotifSetAll(self, kind: str, app_id: str, on: bool):
        g = self.sysNotifGroup(kind, app_id)
        for key in ("ShowPopups", "ShowInHistory"):
            self.sysCfgSet(self.NOTIF_RC, g, key, "true" if on else "false", "bool")

    # ---------------------------------------------------- Power & battery
    PROFILE_LABELS = {"power-saver": "Best power efficiency", "balanced": "Balanced",
                      "performance": "Best performance"}
    PWR_RC = "powerdevilrc"
    PWR_REFRESH = ("org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement",
                   "org.kde.Solid.PowerManagement.refreshStatus")

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
        self.powerChanged.emit()

        def listed(ok, out):
            found = re.findall(r"^\*?\s*([a-z-]+):\s*$", out, re.M) if ok else []
            order = ["power-saver", "balanced", "performance"]
            self._profiles = [p for p in order if p in found]
            self._async(["powerprofilesctl", "get"], got)

        def got(ok, out):
            cur = out.strip() if ok else ""
            self._profile_idx = self._profiles.index(cur) if cur in self._profiles else -1
            self.powerChanged.emit()
        self._async(["powerprofilesctl", "list"], listed)

        if self._bat_present:
            def remaining(ok, out):
                m = re.search(r"uint64\s+(\d+)", out)
                ms = int(m.group(1)) if m and ok else 0
                if ms > 0:
                    mins = ms // 60000
                    h, mn = divmod(mins, 60)
                    self._sys_bat_remaining = (f"{h} hr {mn} min" if h else f"{mn} min")
                else:
                    self._sys_bat_remaining = ""
                self.powerChanged.emit()
            self._async(["dbus-send", "--session", "--dest=org.kde.Solid.PowerManagement", "--print-reply",
                         "/org/kde/Solid/PowerManagement",
                         "org.kde.Solid.PowerManagement.batteryRemainingTime"], remaining)

            def limit(ok, out):
                m = re.search(r"int32\s+(\d+)", out)
                v = int(m.group(1)) if m and ok else 0
                self._sys_charge_limit = v if 0 < v < 100 else 0
                self.powerChanged.emit()
            self._async(["dbus-send", "--session", "--dest=org.kde.Solid.PowerManagement", "--print-reply",
                         "/org/kde/Solid/PowerManagement",
                         "org.kde.Solid.PowerManagement.chargeStopThreshold"], limit)

    batteryPresent = Property(bool, lambda s: s._bat_present, notify=powerChanged)
    batteryPercent = Property(int, lambda s: s._bat_pct, notify=powerChanged)
    batteryStatus = Property(str, lambda s: s._bat_status, notify=powerChanged)
    batteryRemaining = Property(str, lambda s: getattr(s, "_sys_bat_remaining", ""), notify=powerChanged)
    batteryChargeLimit = Property(int, lambda s: getattr(s, "_sys_charge_limit", 0), notify=powerChanged)
    powerProfiles = Property("QVariantList", lambda s: [s.PROFILE_LABELS[p] for p in s._profiles],
                             notify=powerChanged)
    powerProfileIndex = Property(int, lambda s: s._profile_idx, notify=powerChanged)
    powerProfileIds = Property("QVariantList", lambda s: list(s._profiles), notify=powerChanged)

    @Slot(int)
    def setPowerProfile(self, i: int):
        if 0 <= i < len(self._profiles):
            self._profile_idx = i
            self.powerChanged.emit()
            self._async(["powerprofilesctl", "set", self._profiles[i]], lambda *_: self.refreshPower())

    @Slot(str)
    def sysSetPowerProfileId(self, pid: str):
        if pid in self._profiles:
            self.setPowerProfile(self._profiles.index(pid))

    # Screen off / sleep timeouts in PowerDevil (Plasma 6 powerdevilrc layout)
    TIMEOUTS_MIN = [1, 2, 3, 5, 10, 15, 20, 25, 30, 45, 60, 120, 180, 240, 300, 0]  # 0 = never

    @Slot(str, str, result=int)
    def powerTimeoutIndex(self, profile: str, what: str) -> int:
        group, enabled_key, sec_key = self._timeout_keys(profile, what)
        never = len(self.TIMEOUTS_MIN) - 1
        if what == "screen":
            if self.sysCfg(self.PWR_RC, group, enabled_key, "true") == "false":
                return never
            default = {"Battery": "300", "LowBattery": "120"}.get(profile, "600")
        else:
            if self.sysCfg(self.PWR_RC, group, enabled_key, "1") == "0":
                return never
            default = {"Battery": "600", "LowBattery": "300"}.get(profile, "900")
        try:
            minutes = int(self.sysCfg(self.PWR_RC, group, sec_key, default)) // 60
        except ValueError:
            minutes = 10
        return min(range(never), key=lambda i: abs(self.TIMEOUTS_MIN[i] - minutes))

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
            self.sysCfgSet(self.PWR_RC, group, enabled_key, "false" if minutes == 0 else "true", "bool")
        else:
            cur = self.sysCfg(self.PWR_RC, group, enabled_key, "1")
            self.sysCfgSet(self.PWR_RC, group, enabled_key,
                           "0" if minutes == 0 else (cur if cur in ("1", "2") else "1"))
        if minutes:
            self.sysCfgSet(self.PWR_RC, group, sec_key, str(minutes * 60))
        self._sys_power_refresh()

    def _sys_power_refresh(self):
        QTimer.singleShot(400, lambda: dbus(*self.PWR_REFRESH))

    @Slot(str, str, str)
    def sysPowerSet(self, group: str, key: str, value: str):
        """Write a powerdevilrc key and tell PowerDevil to reload (what the KCM does)."""
        self.sysCfgSet(self.PWR_RC, group, key, value, "bool" if value in ("true", "false") else "")
        self._sys_power_refresh()

    @Slot(int)
    def sysSetLowBatteryLevel(self, level: int):
        """Energy saver automatically at N %: low-battery level + energy saver profile."""
        self.sysCfgSet(self.PWR_RC, "BatteryManagement", "BatteryLowLevel", str(level))
        self.sysCfgSet(self.PWR_RC, "LowBattery/Performance", "PowerProfile", "power-saver")
        self._sys_power_refresh()

    @Slot(result=int)
    def sysIdleAction(self) -> int:
        """PowerDevil's single idle action: 1 = Sleep, 2 = Hibernate (0 = never)."""
        for prof in ("AC", "Battery"):
            v = self.sysCfg(self.PWR_RC, f"{prof}/SuspendAndShutdown", "AutoSuspendAction", "1")
            if v in ("1", "2"):
                return int(v)
        return 1

    @Slot(int)
    def sysSetIdleAction(self, action: int):
        for prof in ("AC", "Battery", "LowBattery"):
            g = f"{prof}/SuspendAndShutdown"
            if self.sysCfg(self.PWR_RC, g, "AutoSuspendAction", "1") != "0":
                self.sysCfgSet(self.PWR_RC, g, "AutoSuspendAction", str(action))
        self._sys_power_refresh()

    # ---------------------------------------------------- Storage
    XDG_DIR_KEYS = {"DOCUMENTS": "Documents", "PICTURES": "Pictures", "MUSIC": "Music",
                    "VIDEOS": "Videos", "DOWNLOAD": "Downloads", "DESKTOP": "Desktop"}

    def _sys_init_storage(self):
        self._sys_cats: list = []
        self._sys_temp: list = []
        self._sys_disks: list = []
        self._sys_user_dirs: dict = {}
        self._sys_scanning = False

    sysStorageCats = Property("QVariantList", lambda s: s._sys_cats, notify=sysStorageChanged)
    sysTempItems = Property("QVariantList", lambda s: s._sys_temp, notify=sysStorageChanged)
    sysDisks = Property("QVariantList", lambda s: s._sys_disks, notify=sysStorageChanged)
    sysStorageScanning = Property(bool, lambda s: s._sys_scanning, notify=sysStorageChanged)
    sysUserDirs = Property("QVariantMap", lambda s: s._sys_user_dirs, notify=sysStorageChanged)

    @staticmethod
    def sys_human(n: float) -> str:
        n = float(n)
        for unit in ("bytes", "KB", "MB", "GB", "TB"):
            if n < 1024 or unit == "TB":
                return f"{n:.0f} bytes" if unit == "bytes" else (f"{n:.1f} {unit}" if n < 100 else f"{n:.0f} {unit}")
            n /= 1024
        return ""

    @Slot(int, result=str)
    def sysHumanSize(self, n: int) -> str:
        return self.sys_human(n)

    def _sys_read_user_dirs(self) -> dict:
        """~/.config/user-dirs.dirs  ->  {"DOCUMENTS": "/home/me/Documents", ...}"""
        res = {}
        path = Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config") / "user-dirs.dirs"
        try:
            lines = path.read_text().splitlines()
        except OSError:
            lines = []
        for line in lines:
            m = re.match(r'\s*XDG_([A-Z]+)_DIR="?([^"]*)"?', line)
            if m:
                res[m.group(1)] = m.group(2).replace("$HOME", str(HOME))
        for key, default in self.XDG_DIR_KEYS.items():
            res.setdefault(key, str(HOME / default))
        return res

    @Slot()
    def sysRefreshStorage(self):
        """Size of each category via du (async, one process per category)."""
        self._sys_user_dirs = self._sys_read_user_dirs()
        u = shutil.disk_usage("/")
        cats = [
            ("Apps", "fl:apps_20_regular", ["/var/lib/flatpak", str(HOME / ".local/share/flatpak")]),
            ("Temporary files", "fl:delete_20_regular", [str(HOME / ".cache"), str(HOME / ".local/share/Trash")]),
            ("Documents", "fl:document_20_regular", [self._sys_user_dirs["DOCUMENTS"]]),
            ("Pictures", "fl:image_20_regular", [self._sys_user_dirs["PICTURES"]]),
            ("Music", "fl:headphones_20_regular", [self._sys_user_dirs["MUSIC"]]),
            ("Videos", "fl:desktop_20_regular", [self._sys_user_dirs["VIDEOS"]]),
            ("Downloads", "fl:arrow_download_20_regular", [self._sys_user_dirs["DOWNLOAD"]]),
        ]
        self._sys_cats = [{"name": n, "icon": ic, "bytes": 0, "text": "…", "fraction": 0.0, "paths": p}
                          for n, ic, p in cats]
        self._sys_scanning = True
        self.sysStorageChanged.emit()
        pending = {"n": len(cats)}

        def make_cb(i):
            def cb(ok, out):
                total = 0
                for line in out.splitlines():
                    m = re.match(r"(\d+)\s", line)
                    if m:
                        total += int(m.group(1))
                c = self._sys_cats[i]
                c["bytes"], c["text"] = total, self.sys_human(total)
                c["fraction"] = total / u.total if u.total else 0.0
                pending["n"] -= 1
                if pending["n"] == 0:
                    self._sys_scanning = False
                    other = max(0, u.used - sum(x["bytes"] for x in self._sys_cats))
                    self._sys_cats.append({"name": "Other", "icon": "fl:storage_20_regular", "bytes": other,
                                           "text": self.sys_human(other), "fraction": other / u.total if u.total else 0.0,
                                           "paths": []})
                self.sysStorageChanged.emit()
            return cb
        for i, (_n, _ic, paths) in enumerate(cats):
            existing = [p for p in paths if Path(p).exists()]
            if not existing:
                make_cb(i)(True, "")
                continue
            self._async(["du", "-sxb", *existing], make_cb(i), 120000)

    # --- temporary files
    @Slot()
    def sysRefreshTemp(self):
        items = [
            {"id": "trash", "name": "Trash", "desc": "Files you've deleted",
             "path": str(HOME / ".local/share/Trash"), "bytes": 0, "text": "…"},
            {"id": "thumbs", "name": "Thumbnails", "desc": "Cached previews of your pictures and files",
             "path": str(HOME / ".cache/thumbnails"), "bytes": 0, "text": "…"},
            {"id": "cache", "name": "Temporary app files", "desc": "Cache that apps can rebuild (~/.cache)",
             "path": str(HOME / ".cache"), "bytes": 0, "text": "…"},
        ]
        self._sys_temp = items
        self.sysStorageChanged.emit()

        def make_cb(it):
            def cb(ok, out):
                m = re.match(r"(\d+)\s", out)
                it["bytes"] = int(m.group(1)) if m else 0
                if it["id"] == "cache":
                    thumbs = next(x for x in items if x["id"] == "thumbs")
                    it["bytes"] = max(0, it["bytes"] - thumbs["bytes"])
                it["text"] = self.sys_human(it["bytes"])
                self._sys_temp = list(items)
                self.sysStorageChanged.emit()
            return cb
        # thumbnails first so the cache number can exclude them
        def after_thumbs(ok, out):
            make_cb(items[1])(ok, out)
            for it in (items[0], items[2]):
                if Path(it["path"]).exists():
                    self._async(["du", "-sxb", it["path"]], make_cb(it), 120000)
                else:
                    make_cb(it)(True, "0 x")
        if Path(items[1]["path"]).exists():
            self._async(["du", "-sxb", items[1]["path"]], after_thumbs, 120000)
        else:
            after_thumbs(True, "0 x")

    @Slot("QVariantList")
    def sysRemoveTemp(self, ids):
        """Delete the chosen temporary-file groups (Trash via ktrash6, the rest contents only)."""
        done = lambda *_: self.sysRefreshTemp()          # noqa: E731
        if "trash" in ids:
            self._async(["ktrash6", "--empty"], done, 120000)
        if "thumbs" in ids:
            self._async(["find", str(HOME / ".cache/thumbnails"), "-mindepth", "1", "-delete"], done, 120000)
        if "cache" in ids:
            self._async(["find", str(HOME / ".cache"), "-mindepth", "1", "-not", "-path",
                         str(HOME / ".cache/thumbnails") + "*", "-delete"], done, 120000)

    # --- disks & volumes (read-only)
    @Slot()
    def sysRefreshDisks(self):
        def cb(ok, out):
            disks = []
            try:
                tree = json.loads(out).get("blockdevices", []) if ok else []
            except json.JSONDecodeError:
                tree = []

            def mount_of(n):
                mps = n.get("mountpoints") or [n.get("mountpoint")]
                return next((m for m in mps if m), "")

            def volume(n):
                mp = mount_of(n)
                used = total = 0
                if mp:
                    try:
                        du = shutil.disk_usage(mp)
                        used, total = du.used, du.total
                    except OSError:
                        pass
                size = int(n.get("size") or 0)
                return {"name": n.get("label") or n.get("name", ""), "dev": "/dev/" + n.get("name", ""),
                        "fstype": n.get("fstype") or "", "mount": mp, "size": self.sys_human(size),
                        "used": self.sys_human(used) if total else "", "fraction": used / total if total else 0.0}
            for d in tree:
                if d.get("type") not in ("disk",) or d.get("name", "").startswith(("loop", "zram", "ram")):
                    continue
                vols = [volume(c) for c in d.get("children", []) if c.get("type") in ("part", "crypt", "lvm")]
                if not vols and mount_of(d):
                    vols = [volume(d)]
                disks.append({"name": d.get("name", ""), "model": d.get("model") or "", "size": self.sys_human(int(d.get("size") or 0)),
                              "removable": bool(d.get("rm")), "volumes": vols})
            self._sys_disks = disks
            self.sysStorageChanged.emit()
        self._async(["lsblk", "-b", "-J", "-o", "NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,TYPE,RM,MODEL"], cb)

    # --- where new content is saved (xdg-user-dirs-update --set DIR path)
    @Slot(str, str)
    def sysSetUserDir(self, key: str, path: str):
        if key not in self.XDG_DIR_KEYS or not path.startswith("/"):
            return

        def after(ok, _out):
            self._sys_user_dirs = self._sys_read_user_dirs()
            self.sysStorageChanged.emit()
        self._async(["mkdir", "-p", path],
                    lambda ok, _o: self._async(["xdg-user-dirs-update", "--set", key, path], after) if ok else after(False, ""))

    def _sys_init_misc(self):
        pass

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
