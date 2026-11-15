"""Time & language: date/time, language & region, typing (keyboard).

Mechanisms (see SITEMAP section 7):
  timedatectl                         time zone, NTP, manual time, timesync
  kded6 geotimezoned module           automatic time zone
  PlasmaShell.evaluateScript          Digital Clock applet options
  plasma-localerc + localegenhelper   preferred languages, regional format
  kxkbrc / kcminputrc / plasmarc      keyboard layouts, hot keys, key repeat
"""
from __future__ import annotations

import json
import os
import re
from datetime import datetime, timedelta, timezone as dt_timezone

from PySide6.QtCore import QLocale, QSettings, QTimer, Signal, Slot

from .util import has, kdelete, kread, kwrite, prop

CLOCK = "org.kde.plasma.digitalclock"
CAL_PLUGINS = ["", "alternatecalendarplugin", "astronomicaleventsplugin"]
XKB_LST = "/usr/share/X11/xkb/rules/evdev.lst"
# xkb "grp:*" switching options (ids from xkeyboard-config, evdev.lst)
HOTKEYS = [("", "Not assigned"), ("grp:alt_shift_toggle", "Alt + Shift"),
           ("grp:ctrl_shift_toggle", "Ctrl + Shift"), ("grp:ctrl_alt_toggle", "Ctrl + Alt"),
           ("grp:alt_space_toggle", "Alt + Space"), ("grp:caps_toggle", "Caps Lock")]
SWITCH_MODES = ["Global", "WinClass", "Window", "Desktop"]
LOCALE_FILE = "plasma-localerc"
REGION_KEYS = ["LC_ADDRESS", "LC_TELEPHONE", "LC_PAPER", "LC_MEASUREMENT"]
FORMAT_KEYS = ["LC_TIME", "LC_NUMERIC", "LC_MONETARY"]


def _tl_parse_props(text: str) -> dict:
    return dict(line.split("=", 1) for line in text.splitlines() if "=" in line)


def _tl_bus_string(out: str) -> str:
    """Decode the `s "..."` reply of busctl."""
    out = out.strip()
    if out.startswith("s "):
        out = out[2:]
    try:
        return json.loads(out)
    except ValueError:
        return out.strip('"').replace("\\n", "\n")


def _tl_js(s: str) -> str:
    return json.dumps(s)


class TimeLanguageMixin:
    timeChanged = Signal()
    clockChanged = Signal()
    languageChanged = Signal()
    typingChanged = Signal()
    timeSetFinished = Signal(bool)
    localeStatusChanged = Signal()

    # ------------------------------------------------------------------ init
    def _init_time_language(self):
        self._timezone, self._ntp, self._timezones = "", False, []
        self._timezoneLabels = []
        self._tl_tz_loading = False
        self._autoTimeZone = False
        self._timeServer = ""
        self._lastTimeSync = ""
        # Digital clock
        self._clockShowDate = True
        self._clockShowSeconds = False
        self._clockExtraZones = []
        self._clockCalendarMode = 0
        self._clockUse24h = 1
        self._clockFirstDay = -1
        self._clockAvailable = False
        # Language & region
        self._preferredLanguages = []
        self._regionalFormat = ""
        self._regionalFormatName = ""
        self._homeRegion = ""
        self._localeCatalogue = []
        self._regionCatalogue = []
        self._systemLocale = ""
        self._localeStatus = ""
        # Typing
        self._keyboardLayouts = []
        self._keyboardCatalogue = []
        self._keyboardVariantChoices = []
        self._keyboardHotkey = 0
        self._keyboardHotkeyNames = [n for _i, n in HOTKEYS]
        self._keyboardSwitchMode = 0
        self._keyboardOsd = True
        self._keyRepeatEnabled = True
        self._keyRepeatDelay = 600
        self._keyRepeatRate = 25.0
        self._numLockState = 2
        self._spellHighlight = True
        self._touchKeyboardAvailable = False
        self._touchKeyboardActive = False
        self._tl_xkb = None            # parsed evdev.lst
        self._tl_pending = {}
        self._tl_flush = QTimer(self, singleShot=True, interval=300)
        self._tl_flush.timeout.connect(self._tl_flush_pending)

    # ------------------------------------------------------------ properties
    timezone = prop("timezone", str, timeChanged)
    timezones = prop("timezones", "QVariantList", timeChanged)
    autoTime = prop("ntp", bool, timeChanged)
    timezoneLabels = prop("timezoneLabels", "QVariantList", timeChanged)
    autoTimeZone = prop("autoTimeZone", bool, timeChanged)
    timeServer = prop("timeServer", str, timeChanged)
    lastTimeSync = prop("lastTimeSync", str, timeChanged)

    clockAvailable = prop("clockAvailable", bool, clockChanged)
    clockShowDate = prop("clockShowDate", bool, clockChanged)
    clockShowSeconds = prop("clockShowSeconds", bool, clockChanged)
    clockExtraZones = prop("clockExtraZones", "QVariantList", clockChanged)
    clockCalendarMode = prop("clockCalendarMode", int, clockChanged)
    clockUse24h = prop("clockUse24h", int, clockChanged)
    clockFirstDay = prop("clockFirstDay", int, clockChanged)

    preferredLanguages = prop("preferredLanguages", "QVariantList", languageChanged)
    regionalFormat = prop("regionalFormat", str, languageChanged)
    regionalFormatName = prop("regionalFormatName", str, languageChanged)
    homeRegion = prop("homeRegion", str, languageChanged)
    localeCatalogue = prop("localeCatalogue", "QVariantList", languageChanged)
    regionCatalogue = prop("regionCatalogue", "QVariantList", languageChanged)
    systemLocale = prop("systemLocale", str, languageChanged)
    localeStatus = prop("localeStatus", str, localeStatusChanged)

    keyboardLayouts = prop("keyboardLayouts", "QVariantList", typingChanged)
    keyboardCatalogue = prop("keyboardCatalogue", "QVariantList", typingChanged)
    keyboardVariantChoices = prop("keyboardVariantChoices", "QVariantList", typingChanged)
    keyboardHotkey = prop("keyboardHotkey", int, typingChanged)
    keyboardHotkeyNames = prop("keyboardHotkeyNames", "QVariantList", typingChanged)
    keyboardSwitchMode = prop("keyboardSwitchMode", int, typingChanged)
    keyboardOsd = prop("keyboardOsd", bool, typingChanged)
    keyRepeatEnabled = prop("keyRepeatEnabled", bool, typingChanged)
    keyRepeatDelay = prop("keyRepeatDelay", int, typingChanged)
    keyRepeatRate = prop("keyRepeatRate", float, typingChanged)
    numLockState = prop("numLockState", int, typingChanged)
    spellHighlight = prop("spellHighlight", bool, typingChanged)
    touchKeyboardAvailable = prop("touchKeyboardAvailable", bool, typingChanged)
    touchKeyboardActive = prop("touchKeyboardActive", bool, typingChanged)

    # ================================================================ DATE & TIME
    @Slot()
    def refreshTime(self):
        self._async(["timedatectl", "show"], self._tl_on_show, 6000)
        self._async(["timedatectl", "show-timesync"], self._tl_on_timesync, 6000)
        self._async(["busctl", "--user", "call", "org.kde.kded6", "/kded", "org.kde.kded6",
                     "isModuleAutoloaded", "s", "geotimezoned"], self._tl_on_geotz, 5000)
        if not self._timezones and not self._tl_tz_loading and has("timedatectl"):
            self._tl_tz_loading = True
            self._async(["timedatectl", "list-timezones"], self._tl_on_zones, 10000)

    def _tl_on_show(self, ok, out):
        if not ok:
            return
        info = _tl_parse_props(out)
        self._timezone = info.get("Timezone", "")
        self._ntp = info.get("NTP", "no") == "yes"
        self.timeChanged.emit()

    def _tl_on_timesync(self, ok, out):
        info = _tl_parse_props(out) if ok else {}
        self._timeServer = info.get("ServerName", "") or info.get("FallbackNTPServers", "").split(" ")[0]
        stamp = "/run/systemd/timesync/synchronized"   # touched by systemd-timesyncd on every sync
        try:
            self._lastTimeSync = datetime.fromtimestamp(os.path.getmtime(stamp)).strftime("%A, %d %B %Y %H:%M")
        except OSError:
            self._lastTimeSync = ""
        self.timeChanged.emit()

    def _tl_on_geotz(self, ok, out):
        self._autoTimeZone = ok and out.strip().endswith("true")
        self.timeChanged.emit()

    def _tl_on_zones(self, ok, out):
        self._tl_tz_loading = False
        names = [z for z in out.splitlines() if z.strip()]
        if not names:
            return
        try:
            from zoneinfo import ZoneInfo
            now = datetime.now(dt_timezone.utc)
            offs = {}
            for z in names:
                try:
                    offs[z] = ZoneInfo(z).utcoffset(now) or timedelta(0)
                except Exception:
                    offs[z] = timedelta(0)
        except ImportError:
            offs = {z: timedelta(0) for z in names}
        names.sort(key=lambda z: (offs[z], z))

        def label(z):
            m = int(offs[z].total_seconds() // 60)
            sign = "+" if m >= 0 else "-"
            m = abs(m)
            return f"(UTC{sign}{m // 60:02d}:{m % 60:02d}) {z.replace('_', ' ')}"

        self._timezones = names
        self._timezoneLabels = [label(z) for z in names]
        self.timeChanged.emit()

    @Slot(str)
    def setTimezone(self, tz: str):
        self._timezone = tz
        self.timeChanged.emit()
        self._async(["timedatectl", "set-timezone", tz], lambda *_: self.refreshTime(), 120000)

    @Slot(bool)
    def setAutoTime(self, on: bool):
        self._ntp = on
        self.timeChanged.emit()
        self._async(["timedatectl", "set-ntp", "true" if on else "false"], lambda *_: self.refreshTime(), 120000)

    @Slot(bool)
    def setAutoTimeZone(self, on: bool):
        self._autoTimeZone = on
        self.timeChanged.emit()
        b = "true" if on else "false"
        bus = ["busctl", "--user", "call", "org.kde.kded6", "/kded", "org.kde.kded6"]

        def after_autoload(ok, _out):
            if on:
                self._async(bus + ["loadModule", "sb", "geotimezoned", "false"], lambda *_: self.refreshTime(), 15000)
            else:
                self._async(bus + ["unloadModule", "s", "geotimezoned"], lambda *_: self.refreshTime(), 15000)

        self._async(bus + ["setModuleAutoloading", "sb", "geotimezoned", b], after_autoload, 15000)

    @Slot(str, str)
    def setDateTimeManually(self, date: str, time: str):
        """date 'YYYY-MM-DD', time 'HH:MM[:SS]'. Only works while NTP is off."""
        if re.fullmatch(r"\d{1,2}:\d{2}", time):
            time += ":00"
        try:
            datetime.strptime(f"{date} {time}", "%Y-%m-%d %H:%M:%S")
        except ValueError:
            self.timeSetFinished.emit(False)
            return
        self._async(["timedatectl", "set-time", f"{date} {time}"],
                    lambda ok, _o: (self.timeSetFinished.emit(ok), self.refreshTime()), 120000)

    # ---- Digital Clock applet (taskbar clock)
    def _tl_clock_script(self, body: str, cb=None):
        script = (f"var ps=panels();for(var i=0;i<ps.length;i++){{var ws=ps[i].widgets({_tl_js(CLOCK)});"
                  f"for(var j=0;j<ws.length;j++){{var w=ws[j];w.currentConfigGroup=['Appearance'];{body}}}}}")
        self._async(["busctl", "--user", "call", "org.kde.plasmashell", "/PlasmaShell",
                     "org.kde.PlasmaShell", "evaluateScript", "s", script],
                    (lambda ok, out: cb(ok, _tl_bus_string(out) if ok else "")) if cb else None, 10000)

    def _tl_clock_write(self, key: str, value):
        v = json.dumps(value)
        self._tl_clock_script(f"w.writeConfig({_tl_js(key)},{v});w.reloadConfig();")

    @Slot()
    def refreshClock(self):
        keys = ["showDate", "showSeconds", "selectedTimeZones", "enabledCalendarPlugins", "use24hFormat", "firstDayOfWeek"]
        body = "print('@'+" + "+'|'+".join(f"JSON.stringify(w.readConfig({_tl_js(k)}))" for k in keys) + "+'\\n');"
        self._tl_clock_script(body, self._tl_on_clock)

    def _tl_on_clock(self, ok, out):
        line = next((ln for ln in out.splitlines() if ln.startswith("@")), "")
        self._clockAvailable = bool(line)
        if line:
            try:
                p = [json.loads(x) for x in line[1:].split("|")]
                self._clockShowDate = p[0] in (True, "true")
                self._clockShowSeconds = int(p[1] or 0) == 2
                zones = p[2] if isinstance(p[2], list) else str(p[2]).split(",")
                self._clockExtraZones = [z for z in zones if z and z != "Local"]
                plugins = p[3] if isinstance(p[3], list) else str(p[3]).split(",")
                self._clockCalendarMode = next((i for i, c in enumerate(CAL_PLUGINS) if c and c in plugins), 0)
                self._clockUse24h = int(p[4]) if p[4] != "" else 1
                self._clockFirstDay = int(p[5]) if p[5] != "" else -1
            except (ValueError, IndexError, TypeError):
                pass
        self.clockChanged.emit()

    @Slot(bool)
    def setClockShowDate(self, on: bool):
        self._clockShowDate = on
        self.clockChanged.emit()
        self._tl_clock_write("showDate", on)

    @Slot(bool)
    def setClockShowSeconds(self, on: bool):
        self._clockShowSeconds = on
        self.clockChanged.emit()
        self._tl_clock_write("showSeconds", 2 if on else 0)    # enum Never=0 ToolTip=1 Always=2

    @Slot(str)
    def addClockZone(self, tz: str):
        if tz and tz not in self._clockExtraZones:
            self._clockExtraZones = self._clockExtraZones + [tz]
            self.clockChanged.emit()
            self._tl_clock_write("selectedTimeZones", ["Local"] + self._clockExtraZones)

    @Slot(int)
    def removeClockZone(self, i: int):
        if 0 <= i < len(self._clockExtraZones):
            self._clockExtraZones = self._clockExtraZones[:i] + self._clockExtraZones[i + 1:]
            self.clockChanged.emit()
            self._tl_clock_write("selectedTimeZones", ["Local"] + self._clockExtraZones)

    @Slot(int)
    def setClockCalendarMode(self, i: int):
        self._clockCalendarMode = i
        self.clockChanged.emit()
        self._tl_clock_write("enabledCalendarPlugins", [CAL_PLUGINS[i]] if CAL_PLUGINS[i] else [])

    @Slot(int)
    def setClockUse24h(self, i: int):       # 0 = 12 h, 1 = follow region, 2 = 24 h
        self._clockUse24h = i
        self.clockChanged.emit()
        self._tl_clock_write("use24hFormat", i)

    @Slot(int)
    def setClockFirstDay(self, d: int):     # -1 = region default, 0 = Sunday ... 6 = Saturday
        self._clockFirstDay = d
        self.clockChanged.emit()
        self._tl_clock_write("firstDayOfWeek", d)

    # ================================================================ LANGUAGE & REGION
    @staticmethod
    def _tl_locale_display(code: str) -> str:
        loc = QLocale(code)
        lang = QLocale.languageToString(loc.language())
        terr = QLocale.territoryToString(loc.territory())
        if loc.language() == QLocale.Language.C:
            return code
        return f"{lang} ({terr})" if "_" in code and loc.territory() != QLocale.Country.AnyCountry else lang

    @staticmethod
    def _tl_strip(code: str) -> str:
        return code.split(".")[0].split("@")[0]

    @Slot()
    def refreshLanguage(self):
        langs = kread(LOCALE_FILE, "Translations", "LANGUAGE", "") or os.environ.get("LANGUAGE", "")
        if not langs:
            langs = self._tl_strip(os.environ.get("LANG", "")) or QLocale.system().name()
        codes = [c for c in langs.split(":") if c and c != "C"]
        self._preferredLanguages = [{"code": c, "name": self._tl_locale_display(c)} for c in codes]
        fmt = self._tl_strip(kread(LOCALE_FILE, "Formats", "LANG", "")
                             or os.environ.get("LANG", "") or QLocale.system().name())
        self._regionalFormat = fmt
        self._regionalFormatName = self._tl_locale_display(fmt) if fmt else ""
        region = kread(LOCALE_FILE, "Formats", "LC_ADDRESS", "")
        self._homeRegion = self._tl_strip(region) if region and "Inherit" not in region else fmt
        self.languageChanged.emit()
        self._async(["localectl", "status"], self._tl_on_localectl, 6000)

    def _tl_on_localectl(self, ok, out):
        m = re.search(r"LANG=(\S+)", out) if ok else None
        self._systemLocale = m.group(1) if m else ""
        self.languageChanged.emit()

    @Slot()
    def loadLocaleCatalogue(self):
        if self._localeCatalogue:
            return
        seen, items, regions = set(), [], {}
        for loc in QLocale.matchingLocales(QLocale.Language.AnyLanguage, QLocale.Script.AnyScript,
                                           QLocale.Country.AnyCountry):
            code = loc.name()
            if loc.language() == QLocale.Language.C or "_" not in code or code in seen:
                continue
            seen.add(code)
            name = self._tl_locale_display(code)
            items.append({"code": code, "name": name})
            terr = QLocale.territoryToString(loc.territory())
            regions.setdefault(terr, code)
        items.sort(key=lambda d: d["name"])
        self._localeCatalogue = items
        self._regionCatalogue = [{"code": c, "name": t} for t, c in sorted(regions.items())]
        self.languageChanged.emit()

    def _tl_save_languages(self, codes):
        self._preferredLanguages = [{"code": c, "name": self._tl_locale_display(c)} for c in codes]
        self.languageChanged.emit()
        if codes:
            kwrite(LOCALE_FILE, "Translations", "LANGUAGE", ":".join(codes))
        else:
            kdelete(LOCALE_FILE, "Translations", "LANGUAGE")

    @Slot(str)
    def addLanguage(self, code: str):
        codes = [d["code"] for d in self._preferredLanguages]
        if code and code not in codes:
            self._tl_save_languages(codes + [code])
            self._tl_enable_locale(code)

    @Slot(int, int)
    def moveLanguage(self, i: int, delta: int):
        codes = [d["code"] for d in self._preferredLanguages]
        j = i + delta
        if 0 <= i < len(codes) and 0 <= j < len(codes):
            codes[i], codes[j] = codes[j], codes[i]
            self._tl_save_languages(codes)

    @Slot(int)
    def setDisplayLanguage(self, i: int):
        """Windows display language = first entry of the preferred list."""
        codes = [d["code"] for d in self._preferredLanguages]
        if 0 < i < len(codes):
            codes.insert(0, codes.pop(i))
            self._tl_save_languages(codes)

    @Slot(int)
    def removeLanguage(self, i: int):
        codes = [d["code"] for d in self._preferredLanguages]
        if 0 <= i < len(codes) and len(codes) > 1:
            del codes[i]
            self._tl_save_languages(codes)

    def _tl_enable_locale(self, code: str):
        """Ask the Plasma locale helper to generate `code` (polkit prompt, async)."""
        if "_" not in code:
            return
        self._localeStatus = "Generating locale…"
        self.localeStatusChanged.emit()

        def done(ok, _out):
            self._localeStatus = "" if ok else "Could not generate the locale (permission denied or unavailable)."
            self.localeStatusChanged.emit()

        self._async(["busctl", "--system", "call", "org.kde.localegenhelper", "/LocaleGenHelper",
                     "org.kde.localegenhelper.LocaleGenHelper", "enableLocales", "as", "1",
                     code + ".UTF-8"], done, 120000)

    @Slot(str)
    def setRegionalFormat(self, code: str):
        if not code:
            return
        kwrite(LOCALE_FILE, "Formats", "LANG", code + ".UTF-8")
        for k in FORMAT_KEYS:
            kdelete(LOCALE_FILE, "Formats", k)      # inherit LANG
        self._regionalFormat = code
        self._regionalFormatName = self._tl_locale_display(code)
        self.languageChanged.emit()
        self._tl_enable_locale(code)

    @Slot(str)
    def setHomeRegion(self, code: str):
        if not code:
            return
        for k in REGION_KEYS:
            kwrite(LOCALE_FILE, "Formats", k, code + ".UTF-8")
        self._homeRegion = code
        self.languageChanged.emit()
        self._tl_enable_locale(code)

    @Slot(str)
    def setSystemLocale(self, name: str):
        """Administrative language settings: localectl set-locale (polkit)."""
        name = name.strip()
        if not re.fullmatch(r"[A-Za-z0-9_.@-]+", name):
            return
        self._async(["localectl", "set-locale", "LANG=" + name], lambda *_: self.refreshLanguage(), 120000)

    # ================================================================ TYPING
    def _tl_load_xkb(self):
        if self._tl_xkb is not None:
            return self._tl_xkb
        data = {"layout": [], "variant": {}}
        try:
            section = ""
            with open(XKB_LST, encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.rstrip("\n")
                    if line.startswith("!"):
                        section = line[1:].strip()
                        continue
                    if not line.strip():
                        continue
                    parts = line.strip().split(None, 1)
                    if len(parts) < 2:
                        continue
                    if section == "layout":
                        data["layout"].append({"code": parts[0], "name": parts[1]})
                    elif section == "variant":
                        lay, _, desc = parts[1].partition(": ")
                        data["variant"].setdefault(lay, []).append({"code": parts[0], "name": desc})
        except OSError:
            pass
        self._tl_xkb = data
        return data

    def _tl_layout_name(self, layout: str, variant: str) -> str:
        data = self._tl_load_xkb()
        if variant:
            for v in data["variant"].get(layout, []):
                if v["code"] == variant:
                    return v["name"]
        for d in data["layout"]:
            if d["code"] == layout:
                return d["name"]
        return layout

    @staticmethod
    def _tl_split(v: str):
        return v.split(",") if v else []

    @Slot()
    def refreshTyping(self):
        # layouts
        layouts = self._tl_split(kread("kxkbrc", "Layout", "LayoutList", ""))
        variants = self._tl_split(kread("kxkbrc", "Layout", "VariantList", ""))
        if layouts:
            variants += [""] * (len(layouts) - len(variants))
            self._keyboardLayouts = [{"layout": layouts[i], "variant": variants[i],
                                      "name": self._tl_layout_name(layouts[i], variants[i])}
                                     for i in range(len(layouts))]
        else:
            self._keyboardLayouts = []
            self._async(["localectl", "status"], self._tl_on_x11_layout, 6000)
        opts = self._tl_split(kread("kxkbrc", "Layout", "Options", ""))
        ids = [i for i, _n in HOTKEYS]
        self._keyboardHotkey = next((ids.index(o) for o in opts if o in ids and o), 0)
        mode = kread("kxkbrc", "Layout", "SwitchMode", "Global")
        self._keyboardSwitchMode = SWITCH_MODES.index(mode) if mode in SWITCH_MODES else 0
        self._keyboardOsd = kread("plasmarc", "OSD", "kbdLayoutChangedEnabled", "true") != "false"
        # key repeat / NumLock
        self._keyRepeatEnabled = kread("kcminputrc", "Keyboard", "KeyRepeat", "repeat") != "nothing"
        self._keyRepeatDelay = self._tl_int(kread("kcminputrc", "Keyboard", "RepeatDelay", "600"), 600)
        try:
            self._keyRepeatRate = float(kread("kcminputrc", "Keyboard", "RepeatRate", "25"))
        except ValueError:
            self._keyRepeatRate = 25.0
        self._numLockState = self._tl_int(kread("kcminputrc", "Keyboard", "NumLock", "2"), 2)
        self._spellHighlight = bool(QSettings("KDE", "Sonnet").value("backgroundCheckerEnabled", True, type=bool))
        self._keyboardCatalogue = self._tl_load_xkb()["layout"]
        self.typingChanged.emit()
        if not self._keyboardCatalogue:
            self._async(["localectl", "list-x11-keymap-layouts"], self._tl_on_layouts, 10000)
        self._async(["busctl", "--user", "get-property", "org.kde.KWin", "/VirtualKeyboard",
                     "org.kde.kwin.VirtualKeyboard", "available"], self._tl_on_vk_available, 5000)
        self._async(["busctl", "--user", "get-property", "org.kde.KWin", "/VirtualKeyboard",
                     "org.kde.kwin.VirtualKeyboard", "active"], self._tl_on_vk_active, 5000)

    @staticmethod
    def _tl_int(s, default):
        try:
            return int(float(s))
        except ValueError:
            return default

    def _tl_on_x11_layout(self, ok, out):
        m = re.search(r"X11 Layout:\s*(\S+)", out) if ok else None
        if m:
            lay = m.group(1).split(",")[0]
            self._keyboardLayouts = [{"layout": lay, "variant": "", "name": self._tl_layout_name(lay, ""), "implicit": True}]
            self.typingChanged.emit()

    def _tl_on_layouts(self, ok, out):
        self._keyboardCatalogue = [{"code": c, "name": c} for c in out.split()] if ok else []
        self.typingChanged.emit()

    def _tl_on_vk_available(self, ok, out):
        self._touchKeyboardAvailable = ok and out.strip().endswith("true")
        self.typingChanged.emit()

    def _tl_on_vk_active(self, ok, out):
        self._touchKeyboardActive = ok and out.strip().endswith("true")
        self.typingChanged.emit()

    @Slot(str)
    def loadKeyboardVariants(self, layout: str):
        vs = self._tl_load_xkb()["variant"].get(layout)
        if vs is not None or self._tl_load_xkb()["layout"]:
            self._keyboardVariantChoices = [{"code": "", "name": "Default"}] + (vs or [])
            self.typingChanged.emit()
            return
        self._keyboardVariantChoices = [{"code": "", "name": "Default"}]
        self.typingChanged.emit()

        def got(ok, out):
            self._keyboardVariantChoices = [{"code": "", "name": "Default"}] + (
                [{"code": v, "name": v} for v in out.split()] if ok else [])
            self.typingChanged.emit()

        self._async(["localectl", "list-x11-keymap-variants", layout], got, 8000)

    def _tl_save_layouts(self, layouts):
        self._keyboardLayouts = layouts
        self.typingChanged.emit()
        kwrite("kxkbrc", "Layout", "Use", "true", "bool")
        kwrite("kxkbrc", "Layout", "LayoutList", ",".join(d["layout"] for d in layouts))
        kwrite("kxkbrc", "Layout", "VariantList", ",".join(d["variant"] for d in layouts))
        kwrite("kxkbrc", "Layout", "DisplayNames", ",".join("" for _ in layouts))

    def _tl_explicit_layouts(self):
        return [d for d in self._keyboardLayouts]

    @Slot(str, str)
    def addKeyboardLayout(self, layout: str, variant: str):
        cur = self._tl_explicit_layouts()
        if any(d["layout"] == layout and d["variant"] == variant for d in cur):
            return
        cur.append({"layout": layout, "variant": variant, "name": self._tl_layout_name(layout, variant)})
        self._tl_save_layouts(cur)

    @Slot(int)
    def removeKeyboardLayout(self, i: int):
        cur = self._tl_explicit_layouts()
        if len(cur) > 1 and 0 <= i < len(cur):
            del cur[i]
            self._tl_save_layouts(cur)

    @Slot(int, int)
    def moveKeyboardLayout(self, i: int, delta: int):
        cur = self._tl_explicit_layouts()
        j = i + delta
        if 0 <= i < len(cur) and 0 <= j < len(cur):
            cur[i], cur[j] = cur[j], cur[i]
            self._tl_save_layouts(cur)

    @Slot(int)
    def setDefaultKeyboardLayout(self, i: int):
        """Override for default input method = first entry of LayoutList."""
        cur = self._tl_explicit_layouts()
        if 0 < i < len(cur):
            cur.insert(0, cur.pop(i))
            self._tl_save_layouts(cur)

    @Slot(int)
    def setKeyboardHotkey(self, i: int):
        opts = [o for o in self._tl_split(kread("kxkbrc", "Layout", "Options", ""))
                if not o.startswith("grp:")]
        if i > 0:
            opts.append(HOTKEYS[i][0])
        self._keyboardHotkey = i
        self.typingChanged.emit()
        kwrite("kxkbrc", "Layout", "Use", "true", "bool")
        kwrite("kxkbrc", "Layout", "ResetOldOptions", "true", "bool")
        kwrite("kxkbrc", "Layout", "Options", ",".join(opts))

    @Slot(int)
    def setKeyboardSwitchMode(self, i: int):
        self._keyboardSwitchMode = i
        self.typingChanged.emit()
        kwrite("kxkbrc", "Layout", "SwitchMode", SWITCH_MODES[i])

    @Slot(bool)
    def setKeyboardOsd(self, on: bool):
        self._keyboardOsd = on
        self.typingChanged.emit()
        kwrite("plasmarc", "OSD", "kbdLayoutChangedEnabled", "true" if on else "false", "bool")

    # ---- key repeat / NumLock (kcminputrc [Keyboard])
    def _tl_queue(self, key, fn):
        self._tl_pending[key] = fn
        self._tl_flush.start()

    def _tl_flush_pending(self):
        for fn in self._tl_pending.values():
            fn()
        self._tl_pending.clear()

    @Slot(bool)
    def setKeyRepeatEnabled(self, on: bool):
        self._keyRepeatEnabled = on
        self.typingChanged.emit()
        kwrite("kcminputrc", "Keyboard", "KeyRepeat", "repeat" if on else "nothing")

    @Slot(int)
    def setKeyRepeatDelay(self, ms: int):
        self._keyRepeatDelay = ms
        self.typingChanged.emit()
        self._tl_queue("delay", lambda: kwrite("kcminputrc", "Keyboard", "RepeatDelay", str(ms), "int"))

    @Slot(float)
    def setKeyRepeatRate(self, r: float):
        self._keyRepeatRate = r
        self.typingChanged.emit()
        self._tl_queue("rate", lambda: kwrite("kcminputrc", "Keyboard", "RepeatRate", f"{r:.1f}", "double"))

    @Slot(int)
    def setNumLockState(self, s: int):     # 0 = on, 1 = off, 2 = unchanged (keyboardmisc TriState)
        self._numLockState = s
        self.typingChanged.emit()
        kwrite("kcminputrc", "Keyboard", "NumLock", str(s), "int")

    # ---- spell check (Sonnet, QSettings KDE/Sonnet)
    @Slot(bool)
    def setSpellHighlight(self, on: bool):
        self._spellHighlight = on
        self.typingChanged.emit()
        s = QSettings("KDE", "Sonnet")
        s.setValue("backgroundCheckerEnabled", on)
        s.sync()

    # ---- touch keyboard
    @Slot(bool)
    def setTouchKeyboardActive(self, on: bool):
        self._touchKeyboardActive = on
        self.typingChanged.emit()
        self._async(["busctl", "--user", "set-property", "org.kde.KWin", "/VirtualKeyboard",
                     "org.kde.kwin.VirtualKeyboard", "active", "b", "true" if on else "false"],
                    lambda *_: self.refreshTyping(), 8000)
