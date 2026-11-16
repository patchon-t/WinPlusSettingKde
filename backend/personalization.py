"""Personalization: colors (dark mode, accent, transparency), wallpaper."""
from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

from PySide6.QtCore import Property, QUrl, Signal, Slot

from .util import (HOME, IMG_EXT, best_image, file_url, has, kread, kwin_reconfigure, kwrite,
                   prop, rgb_to_hex)

# Plasma scripting prelude: helpers shared by every evaluateScript call (see SITEMAP shared rules).
_PER_PRELUDE = """
function _perPanel() {
  var ps = panels(), p = null, i;
  for (i = 0; i < ps.length; i++) if (ps[i].location == 'bottom') { p = ps[i]; break; }
  return p || (ps.length ? ps[0] : null);
}
function _perWidget(p, types) {
  if (!p) return null;
  var ws = p.widgets(), i, j;
  for (i = 0; i < ws.length; i++) for (j = 0; j < types.length; j++) if (ws[i].type == types[j]) return ws[i];
  return null;
}
function _perAllWidget(types) {
  var ps = panels(), i, w;
  for (i = 0; i < ps.length; i++) { w = _perWidget(ps[i], types); if (w) return w; }
  return null;
}
function _perDesktops(fn) { var ds = desktops(), i; for (i = 0; i < ds.length; i++) fn(ds[i]); }
function _perRead(o, grp, k) { o.currentConfigGroup = grp; return o.readConfig(k); }
"""

_PER_TASKMGR = "['org.kde.plasma.icontasks', 'org.kde.plasma.taskmanager']"

_PER_READ_JS = """
(function () {
  var o = {};
  try {
    var ds = desktops();
    if (ds.length) {
      var d = ds[0];
      o.bgPlugin = d.wallpaperPlugin;
      o.fill = _perRead(d, ['Wallpaper', 'org.kde.image', 'General'], 'FillMode');
      o.color = _perRead(d, ['Wallpaper', 'org.kde.color', 'General'], 'Color');
      o.slidePaths = _perRead(d, ['Wallpaper', 'org.kde.slideshow', 'General'], 'SlidePaths');
      o.interval = _perRead(d, ['Wallpaper', 'org.kde.slideshow', 'General'], 'SlideInterval');
      o.slideMode = _perRead(d, ['Wallpaper', 'org.kde.slideshow', 'General'], 'SlideshowMode');
    }
  } catch (e) {}
  try {
    var p = _perPanel();
    if (p) {
      o.panel = true; o.alignment = p.alignment; o.hiding = p.hiding; o.height = p.height;
      var t = _perWidget(p, %TASK%);
      if (t) {
        o.taskFound = true;
        o.grouping = _perRead(t, ['General'], 'groupingStrategy');
        o.onlyWhenFull = _perRead(t, ['General'], 'onlyGroupWhenFull');
        o.onlyCurrentScreen = _perRead(t, ['General'], 'showOnlyCurrentScreen');
      }
      var s = _perWidget(p, ['org.kde.plasma.systemtray']);
      if (s) {
        o.trayFound = true;
        o.trayShown = _perRead(s, ['General'], 'shownItems');
        o.trayHidden = _perRead(s, ['General'], 'hiddenItems');
        o.trayKnown = _perRead(s, ['General'], 'knownItems');
        o.trayShowAll = _perRead(s, ['General'], 'showAllItems');
      }
    }
  } catch (e) {}
  try {
    var sp = _perAllWidget(%PILL%);
    if (sp) {
      o.pill = true;
      %PILLREAD%
    }
  } catch (e) {}
  try {
    var k = _perAllWidget(['org.kde.plasma.kickoff']);
    if (k) {
      o.kickoff = true;
      o.compact = _perRead(k, ['General'], 'compactMode');
      o.favDisplay = _perRead(k, ['General'], 'favoritesDisplay');
      o.appDisplay = _perRead(k, ['General'], 'applicationsDisplay');
      o.newApps = _perRead(k, ['General'], 'highlightNewlyInstalledApps');
    }
  } catch (e) {}
  print(JSON.stringify(o));
})();
""".replace("%TASK%", _PER_TASKMGR).replace("%PILL%", "['com.techbypatch.searchpill']").replace(
    "%PILLREAD%", " ".join("o['pill_%s'] = _perRead(sp, ['General'], '%s');" % (k, k) for k in (
        "pillWidth", "pillHeight", "showIcon", "placeholderText", "inlineSearch",
        "floatingPopup", "popupWidth", "popupHeight", "popupGap")))

# Search Pill keys -> (type, min, max); from the widget's contents/config/main.xml
_PER_PILL_KEYS = {
    "pillWidth": ("int", 4, 60), "pillHeight": ("int", 0, 120), "showIcon": ("bool", 0, 0),
    "placeholderText": ("str", 0, 0), "inlineSearch": ("bool", 0, 0), "floatingPopup": ("bool", 0, 0),
    "popupWidth": ("int", 14, 80), "popupHeight": ("int", 10, 80), "popupGap": ("int", 0, 64),
}
_PER_PILL_DEFAULTS = {"pillWidth": 12, "pillHeight": 0, "showIcon": True, "placeholderText": "",
                      "inlineSearch": True, "floatingPopup": True, "popupWidth": 44,
                      "popupHeight": 32, "popupGap": 12}

_LNF_DIRS = (Path("/usr/share/plasma/look-and-feel"), HOME / ".local/share/plasma/look-and-feel")
_ICON_DIRS = (Path("/usr/share/icons"), HOME / ".local/share/icons", HOME / ".icons")
_FONT_DIR = HOME / ".local/share/fonts"
_FONT_LANGS = [("English", "en"), ("Thai", "th"), ("Japanese", "ja"), ("Korean", "ko"),
               ("Chinese (Simplified)", "zh-cn"), ("Chinese (Traditional)", "zh-tw"), ("Russian", "ru"),
               ("Arabic", "ar"), ("Hebrew", "he"), ("Hindi", "hi"), ("Greek", "el")]


def _per_bool(v, default=False) -> bool:
    if isinstance(v, bool):
        return v
    if v in (None, ""):
        return default
    return str(v).strip().lower() in ("true", "1", "yes")


def _per_int(v, default=0) -> int:
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return default


def _per_list(v) -> list:
    if isinstance(v, list):
        return [str(x) for x in v]
    if not v:
        return []
    return [x for x in str(v).split(",") if x]


class PersonalizationMixin:
    darkChanged = Signal()
    accentChanged = Signal()
    accentAutoChanged = Signal()
    recentAccentsChanged = Signal()
    blurChanged = Signal()
    wallpaperChanged = Signal()
    lookAndFeelChanged = Signal()
    colorStateChanged = Signal()
    themeChoicesChanged = Signal()
    decoStateChanged = Signal()
    plasmaStateChanged = Signal()
    lockStateChanged = Signal()
    miscStateChanged = Signal()
    fontStateChanged = Signal()

    def _init_personalization(self):
        self._per_lnf = {"themes": [], "current": ""}
        self._per_color = {"custom": bool(self._settings.value("perCustomColorMode", False, type=bool)),
                           "shellDark": False, "shellOk": False, "auto": False}
        self._per_choices = {}
        self._per_deco = {}
        self._per_plasma_state = {"loaded": False}
        self._per_lock = {}
        self._per_misc = {}
        self._per_fonts_all = []          # [{family, faces:[{style,file}], langs:set}]
        self._per_fonts = {"list": [], "count": 0, "langs": [n for n, _ in _FONT_LANGS],
                           "loading": False, "loaded": False}
        self._per_font_query = ("", "")
        self._dark = self._read_dark()
        self._accent = self._read_accent()
        self._accent_auto = kread("kdeglobals", "General", "accentColorFromWallpaper", "false") == "true"
        self._recent = [str(c) for c in (self._settings.value("recentAccents", [], type=list) or [])]
        self._blur = kread("kwinrc", "Plugins", "blurEnabled", "true") == "true"
        self._wallpaper = self._read_wallpaper()
        self._wallpapers = self._scan_wallpapers()
        if not self._wallpaper and self._wallpapers:
            self._wallpaper = self._wallpapers[0]["path"]

    dark = prop("dark", bool, darkChanged)
    accent = prop("accent", str, accentChanged)
    accentAuto = prop("accent_auto", bool, accentAutoChanged)
    recentAccents = prop("recent", "QVariantList", recentAccentsChanged)
    blur = prop("blur", bool, blurChanged)
    wallpaper = prop("wallpaper", str, wallpaperChanged)
    wallpapers = prop("wallpapers", "QVariantList", wallpaperChanged)
    lookAndFeel = prop("per_lnf", "QVariantMap", lookAndFeelChanged)
    colorState = prop("per_color", "QVariantMap", colorStateChanged)
    themeChoices = prop("per_choices", "QVariantMap", themeChoicesChanged)
    decoState = prop("per_deco", "QVariantMap", decoStateChanged)
    plasmaState = prop("per_plasma_state", "QVariantMap", plasmaStateChanged)
    lockState = prop("per_lock", "QVariantMap", lockStateChanged)
    miscState = prop("per_misc", "QVariantMap", miscStateChanged)
    fontState = prop("per_fonts", "QVariantMap", fontStateChanged)

    @Property(str, notify=wallpaperChanged)
    def wallpaperUrl(self):
        return file_url(self._wallpaper)

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

    # ---------------------------------------------------- slots
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

    @Slot(str)
    def setWallpaper(self, path: str):
        self._wallpaper = path
        self.wallpaperChanged.emit()
        self._async(["plasma-apply-wallpaperimage", path])

    # ================================================================ generic helpers
    def _per_emit_map(self, attr: str, sig, **changes):
        d = dict(getattr(self, attr))
        d.update(changes)
        setattr(self, attr, d)
        sig.emit()

    def _per_script(self, js: str, cb=None):
        """Run Plasma scripting through org.kde.PlasmaShell.evaluateScript (busctl, never on the GUI thread).
        cb(ok, text) gets the script's print() output."""
        def done(ok, out):
            text = ""
            if ok:
                try:
                    text = json.loads(out)["data"][0]
                except (ValueError, KeyError, IndexError, TypeError):
                    ok = False
            if cb:
                cb(ok, text)
        self._async(["busctl", "--user", "--json=short", "call", "org.kde.plasmashell", "/PlasmaShell",
                     "org.kde.PlasmaShell", "evaluateScript", "s", _PER_PRELUDE + js], done, 15000)

    def _per_apply(self, js: str):
        """Fire-and-forget Plasma script write."""
        self._per_script(js)

    @staticmethod
    def _per_read_json(path: Path):
        try:
            return json.loads(path.read_text(errors="replace"))
        except (OSError, ValueError):
            return {}

    # ================================================================ global themes (PER.0 / PER.THM.2)
    def _per_scan_lnf(self) -> list:
        out, seen = [], set()
        for root in _LNF_DIRS:
            if not root.is_dir():
                continue
            for d in sorted(root.iterdir()):
                if d.name in seen or not (d / "metadata.json").exists():
                    continue
                seen.add(d.name)
                meta = self._per_read_json(d / "metadata.json").get("KPlugin", {})
                prev = d / "contents" / "previews" / "preview.png"
                splash = d / "contents" / "previews" / "splash.png"
                out.append({"id": d.name, "name": meta.get("Name", d.name),
                            "preview": file_url(str(prev)) if prev.exists() else "",
                            "hasSplash": (d / "contents" / "splash").is_dir(),
                            "splashPreview": file_url(str(splash)) if splash.exists() else ""})
        return out

    @Slot()
    def refreshLookAndFeel(self):
        cur = kread("kdeglobals", "KDE", "LookAndFeelPackage", "org.kde.breeze.desktop")
        self._per_lnf = {"themes": self._per_scan_lnf(), "current": cur}
        self.lookAndFeelChanged.emit()

    @Slot(str)
    def applyLookAndFeel(self, theme_id: str):
        self._per_lnf = dict(self._per_lnf, current=theme_id)
        self.lookAndFeelChanged.emit()

        def done(*_):
            self._dark = self._read_dark()
            self.darkChanged.emit()
            self._refresh_accent()
            self._wallpaper = self._read_wallpaper() or self._wallpaper
            self.wallpaperChanged.emit()
            self.refreshPlasma()
        self._async(["plasma-apply-lookandfeel", "--apply", theme_id], done, 30000)

    # ================================================================ colors
    @Slot()
    def refreshColorState(self):
        self._per_emit_map("_per_color", self.colorStateChanged,
                           auto=kread("kdeglobals", "KDE", "AutomaticLookAndFeel", "false") == "true")
        if not has("plasma-apply-desktoptheme"):
            return
        cur = kread("plasmarc", "Theme", "name", "default")

        def done(ok, out):
            names = re.findall(r"^\s*\*\s+(\S+)", out, re.M)
            self._per_shell = {"light": "breeze-light" if "breeze-light" in names else "",
                               "dark": "breeze-dark" if "breeze-dark" in names else ""}
            self._per_emit_map("_per_color", self.colorStateChanged,
                               shellOk=bool(self._per_shell["light"] and self._per_shell["dark"]),
                               shellDark=cur.endswith("dark"))
        self._async(["plasma-apply-desktoptheme", "--list-themes"], done)

    def _per_apply_shell(self, dark: bool):
        sh = getattr(self, "_per_shell", None)
        name = sh and sh["dark" if dark else "light"]
        if name:
            self._async(["plasma-apply-desktoptheme", name])

    @Slot(int)
    def setColorMode(self, mode: int):
        """0 Light, 1 Dark, 2 Custom"""
        custom = mode == 2
        self._settings.setValue("perCustomColorMode", custom)
        self._per_emit_map("_per_color", self.colorStateChanged, custom=custom)
        if not custom:
            self.setDark(mode == 1)
            self._per_apply_shell(mode == 1)
            self._per_emit_map("_per_color", self.colorStateChanged, shellDark=mode == 1)

    @Slot(bool)
    def setShellDark(self, dark: bool):
        self._per_emit_map("_per_color", self.colorStateChanged, shellDark=dark)
        self._per_apply_shell(dark)

    @Slot(bool)
    def setAutoLookAndFeel(self, on: bool):
        self._per_emit_map("_per_color", self.colorStateChanged, auto=on)
        kwrite("kdeglobals", "KDE", "AutomaticLookAndFeel", "true" if on else "false", "bool")

    # ================================================================ related theme pages
    # kinds: plasma, icons, cursors, splash, style
    def _per_choice_set(self, kind: str, items: list, current: str, **extra):
        c = dict(self._per_choices)
        c[kind] = dict({"items": items, "current": current}, **extra)
        self._per_choices = c
        self.themeChoicesChanged.emit()

    def _per_scan_icons(self) -> list:
        out, seen = [], set()
        for root in _ICON_DIRS:
            if not root.is_dir():
                continue
            for d in sorted(root.iterdir()):
                f = d / "index.theme"
                if d.name in seen or not f.exists():
                    continue
                name, hidden, dirs, sect = d.name, False, False, ""
                try:
                    for line in f.read_text(errors="replace").splitlines():
                        line = line.strip()
                        if line.startswith("["):
                            sect = line
                        elif sect == "[Icon Theme]":
                            if line.startswith("Name=") and name == d.name:
                                name = line[5:]
                            elif line.startswith("Hidden=") and line[7:].lower() == "true":
                                hidden = True
                            elif line.startswith("Directories=") and len(line) > 12:
                                dirs = True
                except OSError:
                    continue
                if hidden or not dirs:
                    continue
                seen.add(d.name)
                out.append({"id": d.name, "name": name})
        return out

    @Slot(str)
    def refreshThemeChoices(self, kind: str):
        if kind == "plasma":
            cur = kread("plasmarc", "Theme", "name", "default")

            def done(ok, out):
                items = [{"id": m, "name": m} for m in re.findall(r"^\s*\*\s+(\S+)", out, re.M)]
                self._per_choice_set("plasma", items, self._per_choices.get("plasma", {}).get("current", cur))
            self._per_choice_set("plasma", [], cur)
            self._async(["plasma-apply-desktoptheme", "--list-themes"], done)
        elif kind == "cursors":
            cur = kread("kcminputrc", "Mouse", "cursorTheme", "default")
            self._per_cursor_size = _per_int(kread("kcminputrc", "Mouse", "cursorSize", "24"), 24) or 24
            self._per_choice_set("cursors", [], cur, size=self._per_cursor_size)

            def done(ok, out):
                items = [{"id": m.group(2), "name": m.group(1).strip()}
                         for m in re.finditer(r"^\s*\*\s+(.+?)\s+\[([^\]]+)\]", out, re.M)]
                self._per_choice_set("cursors", items, self._per_choices.get("cursors", {}).get("current", cur),
                                     size=self._per_cursor_size)
            self._async(["plasma-apply-cursortheme", "--list-themes"], done)
        elif kind == "icons":
            self._per_choice_set("icons", self._per_scan_icons(), kread("kdeglobals", "Icons", "Theme", "breeze"))
        elif kind == "splash":
            items = [{"id": "None", "name": "None"}]
            items += [{"id": t["id"], "name": t["name"], "preview": t["splashPreview"]}
                      for t in self._per_scan_lnf() if t["hasSplash"]]
            self._per_choice_set("splash", items, kread("ksplashrc", "KSplash", "Theme", "org.kde.breeze.desktop"))
        elif kind == "style":
            try:
                from PySide6.QtWidgets import QStyleFactory
                keys = list(QStyleFactory.keys())
            except ImportError:
                keys = []
            self._per_choice_set("style", [{"id": k, "name": k} for k in keys],
                                 kread("kdeglobals", "KDE", "widgetStyle", "Breeze"))

    @Slot(str, str)
    def chooseTheme(self, kind: str, theme_id: str):
        cur = self._per_choices.get(kind)
        if cur is not None:
            self._per_choice_set(kind, cur["items"], theme_id, **{k: v for k, v in cur.items()
                                                                  if k not in ("items", "current")})
        if kind == "plasma":
            self._async(["plasma-apply-desktoptheme", theme_id])
        elif kind == "cursors":
            self._async(["plasma-apply-cursortheme", theme_id, "--size", str(getattr(self, "_per_cursor_size", 24))])
        elif kind == "icons":
            kwrite("kdeglobals", "Icons", "Theme", theme_id)
        elif kind == "splash":
            kwrite("ksplashrc", "KSplash", "Theme", theme_id)
            kwrite("ksplashrc", "KSplash", "Engine", "none" if theme_id == "None" else "KSplashQML")
        elif kind == "style":
            kwrite("kdeglobals", "KDE", "widgetStyle", theme_id)

    @Slot(int)
    def setCursorSize(self, size: int):
        self._per_cursor_size = size
        cur = self._per_choices.get("cursors")
        if cur is None:
            return
        self._per_choice_set("cursors", cur["items"], cur["current"], size=size)
        self._later("per-cursor-size", ["plasma-apply-cursortheme", cur["current"], "--size", str(size)])

    # ---- window decorations (kwinrc [org.kde.kdecoration2])
    @Slot()
    def refreshDecoration(self):
        g = "org.kde.kdecoration2"
        self._per_deco = {
            "theme": kread("kwinrc", g, "theme", "Breeze"),
            "borderSize": kread("kwinrc", g, "BorderSize", "Normal"),
            "borderAuto": kread("kwinrc", g, "BorderSizeAuto", "true") == "true",
            "left": kread("kwinrc", g, "ButtonsOnLeft", "MSE"),
            "right": kread("kwinrc", g, "ButtonsOnRight", "HIAX"),
        }
        self.decoStateChanged.emit()

    @Slot(str, "QVariant")
    def setDecoration(self, key: str, value):
        keys = {"borderSize": ("BorderSize", None), "borderAuto": ("BorderSizeAuto", "bool"),
                "left": ("ButtonsOnLeft", None), "right": ("ButtonsOnRight", None)}
        if key not in keys:
            return
        self._per_emit_map("_per_deco", self.decoStateChanged, **{key: value})
        k, kind = keys[key]
        v = ("true" if value else "false") if kind == "bool" else str(value)
        kwrite("kwinrc", "org.kde.kdecoration2", k, v, kind)
        kwin_reconfigure()

    # ================================================================ Plasma-scripted state
    @Slot()
    def refreshPlasma(self):
        def done(ok, text):
            if not ok:
                self._per_emit_map("_per_plasma_state", self.plasmaStateChanged, loaded=True, available=False)
                return
            try:
                o = json.loads(text)
            except ValueError:
                o = {}
            tg = _per_int(o.get("grouping"), 1)
            full = _per_bool(o.get("onlyWhenFull"), False)
            col = o.get("color")
            self._per_plasma_state = {
                "loaded": True, "available": bool(o),
                "bgPlugin": o.get("bgPlugin") or "org.kde.image",
                "fill": _per_int(o.get("fill"), 2),
                "color": col if isinstance(col, str) and col.startswith("#") else "#1d99f3",
                "slidePaths": [x for x in _per_list(o.get("slidePaths")) if not x.startswith("preferred:")],
                "interval": _per_int(o.get("interval"), 900) or 900,
                "shuffle": _per_int(o.get("slideMode"), 0) == 0,
                "panel": bool(o.get("panel")),
                "alignment": o.get("alignment") or "center",
                "hiding": o.get("hiding") or "none",
                "height": _per_int(o.get("height"), 44) or 44,
                "taskFound": bool(o.get("taskFound")),
                "grouping": "never" if tg == 0 else ("full" if full else "always"),
                "onlyCurrentScreen": _per_bool(o.get("onlyCurrentScreen")),
                "trayFound": bool(o.get("trayFound")),
                "trayShown": _per_list(o.get("trayShown")),
                "trayHidden": _per_list(o.get("trayHidden")),
                "trayKnown": _per_list(o.get("trayKnown")),
                "trayShowAll": _per_bool(o.get("trayShowAll")),
                "kickoff": bool(o.get("kickoff")),
                "compact": _per_bool(o.get("compact")),
                "favDisplay": _per_int(o.get("favDisplay"), 0),
                "appDisplay": _per_int(o.get("appDisplay"), 0),
                "newApps": _per_bool(o.get("newApps"), True),
                "pill": bool(o.get("pill")),
            }
            for k, (kind, _lo, _hi) in _PER_PILL_KEYS.items():
                raw, dflt = o.get("pill_" + k), _PER_PILL_DEFAULTS[k]
                self._per_plasma_state["pill_" + k] = (
                    _per_bool(raw, dflt) if kind == "bool" else _per_int(raw, dflt) if kind == "int"
                    else (raw if isinstance(raw, str) else dflt))
            self.plasmaStateChanged.emit()
        self._per_script(_PER_READ_JS, done)

    def _per_pset(self, **kw):
        self._per_emit_map("_per_plasma_state", self.plasmaStateChanged, **kw)

    # ---- background
    @Slot(str)
    def setBackgroundMode(self, mode: str):
        plugin = {"picture": "org.kde.image", "color": "org.kde.color",
                  "slideshow": "org.kde.slideshow", "spotlight": "org.kde.potd"}.get(mode)
        if not plugin:
            return
        self._per_pset(bgPlugin=plugin)
        self._per_apply("_perDesktops(function (d) { d.wallpaperPlugin = %s; });" % json.dumps(plugin))

    @Slot(int)
    def setBackgroundFit(self, fill_mode: int):
        """Image FillMode: 0 stretch, 1 fit, 2 fill, 3 tile, 6 center (SITEMAP PER.BG.3)."""
        self._per_pset(fill=fill_mode)
        self._per_apply("_perDesktops(function (d) { d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];"
                        " d.writeConfig('FillMode', %d); });" % fill_mode)

    @Slot(str)
    def setBackgroundColor(self, color: str):
        color = "#" + color.lstrip("#")[-6:].lower()
        self._per_pset(color=color, bgPlugin="org.kde.color")
        self._per_apply("_perDesktops(function (d) { d.wallpaperPlugin = 'org.kde.color';"
                        " d.currentConfigGroup = ['Wallpaper', 'org.kde.color', 'General'];"
                        " d.writeConfig('Color', %s); });" % json.dumps(color))

    @Slot(str)
    def setBackgroundSlideshowFolder(self, folder: str):
        if folder.startswith("file:"):
            folder = QUrl(folder).toLocalFile()
        if not folder:
            return
        self._per_pset(slidePaths=[folder], bgPlugin="org.kde.slideshow")
        self._per_apply("_perDesktops(function (d) { d.wallpaperPlugin = 'org.kde.slideshow';"
                        " d.currentConfigGroup = ['Wallpaper', 'org.kde.slideshow', 'General'];"
                        " d.writeConfig('SlidePaths', [%s]); });" % json.dumps(folder))

    @Slot(int)
    def setSlideshowInterval(self, seconds: int):
        self._per_pset(interval=seconds)
        self._per_apply("_perDesktops(function (d) { d.currentConfigGroup = ['Wallpaper', 'org.kde.slideshow', 'General'];"
                        " d.writeConfig('SlideInterval', %d); });" % seconds)

    @Slot(bool)
    def setSlideshowShuffle(self, on: bool):
        self._per_pset(shuffle=on)
        self._per_apply("_perDesktops(function (d) { d.currentConfigGroup = ['Wallpaper', 'org.kde.slideshow', 'General'];"
                        " d.writeConfig('SlideshowMode', %d); });" % (0 if on else 1))

    # ---- taskbar (panel)
    @Slot(str, "QVariant")
    def setPanelProperty(self, key: str, value):
        if key not in ("alignment", "hiding", "height"):
            return
        v = int(value) if key == "height" else str(value)
        self._per_pset(**{key: v})
        self._per_apply("var p = _perPanel(); if (p) { p.%s = %s; }" % (key, json.dumps(v)))

    @Slot(str)
    def setTaskGrouping(self, mode: str):
        strategy, full = (0, False) if mode == "never" else (1, mode == "full")
        self._per_pset(grouping=mode)
        self._per_apply("var t = _perWidget(_perPanel(), %s); if (t) { t.currentConfigGroup = ['General'];"
                        " t.writeConfig('groupingStrategy', %d); t.writeConfig('onlyGroupWhenFull', %s); }"
                        % (_PER_TASKMGR, strategy, "true" if full else "false"))

    @Slot(str, "QVariant")
    def setSearchPillOption(self, key: str, value):
        """Write one Search Pill widget setting live (only keys from its main.xml)."""
        spec = _PER_PILL_KEYS.get(key)
        if not spec:
            return
        kind, lo, hi = spec
        if kind == "int":
            v = max(lo, min(hi, int(value)))
        elif kind == "bool":
            v = bool(value)
        else:
            v = str(value)
        self._per_pset(**{"pill_" + key: v})
        self._per_apply("var sp = _perAllWidget(['com.techbypatch.searchpill']); if (sp) {"
                        " sp.currentConfigGroup = ['General']; sp.writeConfig(%s, %s); }"
                        % (json.dumps(key), json.dumps(v)))

    @Slot(bool)
    def setTaskOnlyCurrentScreen(self, on: bool):
        self._per_pset(onlyCurrentScreen=on)
        self._per_apply("var t = _perWidget(_perPanel(), %s); if (t) { t.currentConfigGroup = ['General'];"
                        " t.writeConfig('showOnlyCurrentScreen', %s); }" % (_PER_TASKMGR, "true" if on else "false"))

    def _per_tray_write(self, **kw):
        self._per_pset(**kw)
        st = self._per_plasma_state
        self._per_apply("var s = _perWidget(_perPanel(), ['org.kde.plasma.systemtray']); if (s) {"
                        " s.currentConfigGroup = ['General'];"
                        " s.writeConfig('shownItems', %s); s.writeConfig('hiddenItems', %s);"
                        " s.writeConfig('showAllItems', %s); }"
                        % (json.dumps(st["trayShown"]), json.dumps(st["trayHidden"]),
                           "true" if st["trayShowAll"] else "false"))

    @Slot(str, bool)
    def setTrayItemShown(self, item: str, on: bool):
        st = self._per_plasma_state
        shown = [x for x in st.get("trayShown", []) if x != item]
        hidden = [x for x in st.get("trayHidden", []) if x != item]
        (shown if on else hidden).append(item)
        self._per_tray_write(trayShown=shown, trayHidden=hidden)

    @Slot(bool)
    def setTrayShowAll(self, on: bool):
        self._per_tray_write(trayShowAll=on)

    # ---- start (Kickoff)
    @Slot(str, "QVariant")
    def setStartOption(self, key: str, value):
        keys = {"compact": ("compactMode", "bool"), "favDisplay": ("favoritesDisplay", "int"),
                "appDisplay": ("applicationsDisplay", "int"), "newApps": ("highlightNewlyInstalledApps", "bool")}
        if key not in keys:
            return
        k, kind = keys[key]
        v = bool(value) if kind == "bool" else int(value)
        self._per_pset(**{key: v})
        self._per_apply("var k = _perAllWidget(['org.kde.plasma.kickoff']); if (k) { k.currentConfigGroup = ['General'];"
                        " k.writeConfig(%s, %s); }" % (json.dumps(k), json.dumps(v)))

    # ================================================================ misc config-file settings
    @Slot()
    def refreshMisc(self):
        self._per_misc = {
            "kbdIndicator": kread("plasmarc", "OSD", "kbdLayoutChangedEnabled", "true") == "true",
            "badges": kread("plasmanotifyrc", "Badges", "InTaskManager", "true") == "true",
            "history": kread("kactivitymanagerd-pluginsrc", "Plugin-org.kde.ActivityManager.Resources.Scoring",
                             "what-to-remember", "0") != "2",
            "sounds": kread("kdeglobals", "Sounds", "Theme", "ocean"),
        }
        self.miscStateChanged.emit()

    @Slot(str, bool)
    def setMiscOption(self, key: str, on: bool):
        self._per_emit_map("_per_misc", self.miscStateChanged, **{key: on})
        b = "true" if on else "false"
        if key == "kbdIndicator":
            kwrite("plasmarc", "OSD", "kbdLayoutChangedEnabled", b, "bool")
        elif key == "badges":
            kwrite("plasmanotifyrc", "Badges", "InTaskManager", b, "bool")
        elif key == "history":
            kwrite("kactivitymanagerd-pluginsrc", "Plugin-org.kde.ActivityManager.Resources.Scoring",
                   "what-to-remember", "0" if on else "2", "int")

    # ================================================================ lock screen
    @Slot()
    def refreshLockScreen(self):
        g = "Greeter/Wallpaper/%s/General"
        self._per_lock = {
            "plugin": kread("kscreenlockerrc", "Greeter", "WallpaperPlugin", "org.kde.image"),
            "image": kread("kscreenlockerrc", g % "org.kde.image", "Image", ""),
            "slidePaths": _per_list(kread("kscreenlockerrc", g % "org.kde.slideshow", "SlidePaths", "")),
            "autolock": kread("kscreenlockerrc", "Daemon", "Autolock", "true") == "true",
            "timeout": _per_int(kread("kscreenlockerrc", "Daemon", "Timeout", "5"), 5),
        }
        self.lockStateChanged.emit()

    @Slot(str)
    def setLockPlugin(self, plugin: str):
        self._per_emit_map("_per_lock", self.lockStateChanged, plugin=plugin)
        kwrite("kscreenlockerrc", "Greeter", "WallpaperPlugin", plugin)

    @Slot(str)
    def setLockWallpaper(self, path: str):
        if path.startswith("file:"):
            path = QUrl(path).toLocalFile()
        self._per_emit_map("_per_lock", self.lockStateChanged, image=path, plugin="org.kde.image")
        kwrite("kscreenlockerrc", "Greeter/Wallpaper/org.kde.image/General", "Image", path)
        kwrite("kscreenlockerrc", "Greeter", "WallpaperPlugin", "org.kde.image")

    @Slot(str)
    def setLockSlideshowFolder(self, folder: str):
        if folder.startswith("file:"):
            folder = QUrl(folder).toLocalFile()
        if not folder:
            return
        self._per_emit_map("_per_lock", self.lockStateChanged, slidePaths=[folder], plugin="org.kde.slideshow")
        kwrite("kscreenlockerrc", "Greeter/Wallpaper/org.kde.slideshow/General", "SlidePaths", folder)
        kwrite("kscreenlockerrc", "Greeter", "WallpaperPlugin", "org.kde.slideshow")

    @Slot(int)
    def setLockTimeout(self, minutes: int):
        """0 = never lock automatically."""
        self._per_emit_map("_per_lock", self.lockStateChanged, autolock=minutes > 0,
                           timeout=minutes if minutes > 0 else self._per_lock.get("timeout", 5))
        kwrite("kscreenlockerrc", "Daemon", "Autolock", "true" if minutes > 0 else "false", "bool")
        if minutes > 0:
            kwrite("kscreenlockerrc", "Daemon", "Timeout", str(minutes))

    # ================================================================ fonts
    @Slot()
    def refreshFonts(self):
        if self._per_fonts.get("loading"):
            return
        self._per_emit_map("_per_fonts", self.fontStateChanged, loading=True)

        def done(ok, out):
            fam = {}
            for line in out.splitlines():
                parts = line.split("\t")
                if len(parts) < 3 or not parts[0]:
                    continue
                f = fam.setdefault(parts[0], {"family": parts[0], "faces": [], "langs": set()})
                f["faces"].append({"style": parts[1], "file": parts[2]})
                if len(parts) > 3:
                    f["langs"].update(parts[3].split("|"))
            self._per_fonts_all = sorted(fam.values(), key=lambda f: f["family"].lower())
            self._per_emit_map("_per_fonts", self.fontStateChanged, loading=False, loaded=True)
            self.filterFonts(*self._per_font_query)
        self._async(["fc-list", "--format", "%{family[0]}\t%{style[0]}\t%{file}\t%{lang}\n"], done, 40000)

    @Slot(str, str)
    def filterFonts(self, query: str, language: str):
        """language: a display name from fontState.langs, or '' for all."""
        self._per_font_query = (query, language)
        q = query.strip().lower()
        code = dict(_FONT_LANGS).get(language, "")
        items = []
        for f in self._per_fonts_all:
            if q and q not in f["family"].lower():
                continue
            if code and code not in f["langs"]:
                continue
            items.append({"family": f["family"], "faces": len(f["faces"])})
        self._per_emit_map("_per_fonts", self.fontStateChanged, list=items, count=len(items))

    @Slot(str, result="QVariantList")
    def fontFaces(self, family: str):
        for f in self._per_fonts_all:
            if f["family"] == family:
                return [{"style": x["style"], "file": x["file"], "user": x["file"].startswith(str(_FONT_DIR))}
                        for x in sorted(f["faces"], key=lambda x: x["style"])]
        return []

    @Slot("QVariantList")
    def installFonts(self, urls):
        """Copy font files into ~/.local/share/fonts and refresh the font cache."""
        copied = False
        _FONT_DIR.mkdir(parents=True, exist_ok=True)
        for u in urls:
            src = Path(QUrl(str(u)).toLocalFile() if str(u).startswith("file:") else str(u))
            if src.suffix.lower() in (".ttf", ".otf", ".ttc", ".woff", ".woff2", ".pfb") and src.is_file():
                try:
                    shutil.copy2(src, _FONT_DIR / src.name)
                    copied = True
                except OSError:
                    pass
        if copied:
            self._async(["fc-cache", "-f"], lambda *_: self.refreshFonts(), 60000)

    @Slot(str)
    def uninstallFont(self, family: str):
        """Removes the per-user files of a family (system fonts are left alone)."""
        for f in self._per_fonts_all:
            if f["family"] == family:
                for x in f["faces"]:
                    if x["file"].startswith(str(_FONT_DIR)):
                        try:
                            Path(x["file"]).unlink()
                        except OSError:
                            pass
        self._async(["fc-cache", "-f"], lambda *_: self.refreshFonts(), 60000)
