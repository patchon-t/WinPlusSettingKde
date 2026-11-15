"""Accessibility (text size, visual effects, magnifier, color filters, keyboard, mouse, ...).

Owned by the Accessibility section. Sources used (Plasma v6.7.6):
  * kaccessrc keys: plasma-desktop/kcms/access/kcmaccessibility*.kcfg
  * the KCM applies kaccessrc changes by starting `kaccess` again
    (kcms/access/kcmaccess.cpp:303-306); KDBusService in the running instance
    then re-reads the config (kaccess/kaccess.cpp:157, newInstance()).
  * KWin effects: kwinrc [Plugins] <id>Enabled + org.kde.kwin.Effects
    loadEffect / unloadEffect / reconfigureEffect (kwin/src/org.kde.kwin.Effects.xml).
"""
from __future__ import annotations

import json
import os
import re
import shutil
from pathlib import Path

from PySide6.QtCore import Property, QTimer, Signal, Slot

from .util import HOME, ROOT, dbus, has, spawn


def _a11y_parse_ini(path: Path) -> dict:
    out: dict = {}
    try:
        text = path.read_text(errors="replace")
    except OSError:
        return out
    group = ""
    for line in text.splitlines():
        line = line.strip()
        if not line or line[0] in "#;":
            continue
        if line.startswith("[") and line.endswith("]"):
            group = "/".join(re.findall(r"\[([^\]]*)\]", line))
            out.setdefault(group, {})
        elif "=" in line:
            k, v = line.split("=", 1)
            k = k.strip()
            if "[" in k:
                if re.search(r"\[\$[a-z]+\]$", k):
                    k = k[:k.index("[")]
                else:
                    continue
            out.setdefault(group, {})[k] = v.strip()
    return out


# A11Y.TS.1: every font key scaled by the Text size page
A11Y_FONT_KEYS = [
    ("General", "font", "Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"),
    ("General", "menuFont", "Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"),
    ("General", "toolBarFont", "Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"),
    ("General", "smallestReadableFont", "Noto Sans,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"),
    ("General", "fixed", "Hack,10,-1,5,400,0,0,0,1,0,0,0,0,0,0,1"),
    ("WM", "activeFont", "Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"),
]
A11Y_CONTRAST = {
    "aquatic": ("WinPlusAquatic", "Aquatic"),
    "desert": ("WinPlusDesert", "Desert"),
    "dusk": ("WinPlusDusk", "Dusk"),
    "nightsky": ("WinPlusNightsky", "Night sky"),
}


def _a11y_scale_font(spec: str, pct: int) -> str:
    """QFont::toString() = family,pointSizeF,pixelSize,styleHint,weight,... (verified with
    Qt 6.11: 'Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1'). Scale pointSize, or
    pixelSize when the point size is unset (-1)."""
    parts = spec.split(",")
    try:
        idx = 1 if float(parts[1]) > 0 else 2
        v = float(parts[idx])
    except (IndexError, ValueError):
        return spec
    if v <= 0:
        return spec
    nv = round(v * pct / 100 * 2) / 2 if idx == 1 else round(v * pct / 100)
    parts[idx] = str(int(nv)) if float(nv).is_integer() else str(nv)
    return ",".join(parts)


class AccessibilityMixin:
    a11yCfgChanged = Signal()
    a11yStateChanged = Signal()
    a11yTextChanged = Signal()
    a11yCursorChanged = Signal()
    a11yContrastChanged = Signal()

    def _init_accessibility(self):
        self._a11y_ini_cache: dict = {}
        self._a11y_over: dict = {}
        self._a11y_rev = 0
        self._a11y_text_pct = int(self._settings.value("a11y/textScale", 100) or 100)
        self._a11y_text_busy = False
        self._a11y_cursor_themes: list = []
        self._a11y_cursor_theme = ""
        self._a11y_mag_on = False
        self._a11y_vk_available = False
        self._a11y_vk_active = False
        self._a11y_contrast_busy = False
        self._a11y_kaccess_timer = QTimer(self, singleShot=True, interval=400)
        self._a11y_kaccess_timer.timeout.connect(lambda: spawn(["kaccess"]) if has("kaccess") else None)
        self._pollers.append(self._a11y_poll_vk)

    # ---------------------------------------------------- properties
    @Property(int, notify=a11yCfgChanged)
    def a11yCfgRev(self):
        return self._a11y_rev

    @Property(int, notify=a11yTextChanged)
    def a11yTextScale(self):
        return self._a11y_text_pct

    @Property(bool, notify=a11yTextChanged)
    def a11yTextBusy(self):
        return self._a11y_text_busy

    @Property('QVariantList', notify=a11yCursorChanged)
    def a11yCursorThemes(self):
        return self._a11y_cursor_themes

    @Property(str, notify=a11yCursorChanged)
    def a11yCursorTheme(self):
        return self._a11y_cursor_theme

    @Property(bool, notify=a11yStateChanged)
    def a11yMagnifierOn(self):
        return self._a11y_mag_on

    @Property(bool, notify=a11yStateChanged)
    def a11yVkAvailable(self):
        return self._a11y_vk_available

    @Property(bool, notify=a11yStateChanged)
    def a11yVkActive(self):
        return self._a11y_vk_active

    @Property(str, notify=a11yCfgChanged)
    def a11yContrastActive(self):
        sid = self.a11yCfg("kdeglobals", "General", "ColorScheme", "")
        for k, (s, _n) in A11Y_CONTRAST.items():
            if s == sid:
                return k
        return ""

    @Property(bool, notify=a11yContrastChanged)
    def a11yContrastBusy(self):
        return self._a11y_contrast_busy

    # ---------------------------------------------------- generic KConfig access
    def _a11y_bump(self):
        self._a11y_rev += 1
        self.a11yCfgChanged.emit()

    def _a11y_dirs(self):
        dirs = [Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config")]
        dirs += [Path(d) for d in (os.environ.get("XDG_CONFIG_DIRS") or "/etc/xdg").split(":") if d]
        return dirs

    def _a11y_ini(self, file: str) -> dict:
        merged: dict = {}
        for d in reversed(self._a11y_dirs()):
            p = d / file
            try:
                mt = p.stat().st_mtime_ns
            except OSError:
                continue
            hit = self._a11y_ini_cache.get(str(p))
            if not hit or hit[0] != mt:
                hit = (mt, _a11y_parse_ini(p))
                self._a11y_ini_cache[str(p)] = hit
            for g, kv in hit[1].items():
                merged.setdefault(g, {}).update(kv)
        return merged

    @Slot(str, str, str, str, result=str)
    def a11yCfg(self, file: str, group: str, key: str, default: str = "") -> str:
        k = (file, group, key)
        if k in self._a11y_over:
            v = self._a11y_over[k]
            return default if v is None else v
        return self._a11y_ini(file).get(group, {}).get(key, default)

    def _a11y_write(self, file, group, key, value, kind="", then=None):
        k = (file, group, key)
        self._a11y_over[k] = value
        self._a11y_bump()
        args = ["kwriteconfig6", "--file", file]
        for g in group.split("/"):
            args += ["--group", g]
        args += ["--key", key]
        if value is None:
            args += ["--delete", "--notify"]
        else:
            if kind:
                args += ["--type", kind]
            args += ["--notify", value]

        def done(_ok, _out):
            if self._a11y_over.get(k) == value:
                self._a11y_over.pop(k, None)
            self._a11y_bump()
            if then:
                then()
        self._async(args, done)

    @Slot(str, str, str, str)
    @Slot(str, str, str, str, str)
    def a11yCfgSet(self, file: str, group: str, key: str, value: str, kind: str = ""):
        self._a11y_write(file, group, key, value, kind)

    @Slot(str, str, str)
    def a11yCfgDel(self, file: str, group: str, key: str):
        self._a11y_write(file, group, key, None)

    @Slot()
    def a11yCfgReload(self):
        self._a11y_over.clear()
        self._a11y_ini_cache.clear()
        self._a11y_bump()

    # ---------------------------------------------------- kaccess (keyboard / mouse / bell / narrator)
    @Slot(str, str, str, str)
    def a11yKaccessSet(self, group: str, key: str, value: str, kind: str = ""):
        """Write kaccessrc, then start `kaccess` so the running instance reloads
        (same as kcmaccess.cpp:303-306)."""
        self._a11y_write("kaccessrc", group, key, value, kind,
                         then=self._a11y_kaccess_timer.start)

    # ---------------------------------------------------- KWin effects
    @Slot(str, bool)
    def a11yEffectSet(self, effect: str, on: bool):
        """kwinrc [Plugins] <id>Enabled + loadEffect / unloadEffect."""
        def then():
            dbus("org.kde.KWin", "/Effects", "org.kde.kwin.Effects.loadEffect" if on
                 else "org.kde.kwin.Effects.unloadEffect", f"string:{effect}")
        self._a11y_write("kwinrc", "Plugins", effect + "Enabled", "true" if on else "false",
                         "bool", then=then)

    @Slot(str, str, str, str)
    def a11yEffectCfgSet(self, effect: str, key: str, value: str, kind: str = ""):
        """kwinrc [Effect-<id>] key + reconfigureEffect."""
        def then():
            dbus("org.kde.KWin", "/Effects", "org.kde.kwin.Effects.reconfigureEffect",
                 f"string:{effect}")
        self._a11y_write("kwinrc", "Effect-" + effect, key, value, kind, then=then)

    @Slot(bool)
    def a11yTransparencySet(self, on: bool):
        """A11Y.VE.2 = PER.COL.3: blur + contrast effects."""
        self.a11yEffectSet("blur", on)
        self.a11yEffectSet("contrast", on)

    @Slot(float)
    def a11yAnimationFactor(self, f: float):
        """A11Y.VE.3: kdeglobals [KDE] AnimationDurationFactor (0 = off)."""
        self._a11y_write("kdeglobals", "KDE", "AnimationDurationFactor", str(f), "double")

    # ---------------------------------------------------- Color filters (colorblindnesscorrection + invert)
    @Slot(bool, int, float)
    def a11yColorFilter(self, on: bool, kind: int, intensity: float):
        """kind: 0 inverted, 1 grayscale, 2 grayscale inverted, 3 deuteranopia,
        4 protanopia, 5 tritanopia. Mode enum: 0 protan, 1 deutan, 2 tritan, 3 mono
        (colorblindnesscorrection.h:25-29)."""
        mode = {1: 3, 2: 3, 3: 1, 4: 0, 5: 2}.get(kind)
        if mode is not None:
            self._a11y_write("kwinrc", "Effect-colorblindnesscorrection", "Mode", str(mode), "int")
            self._a11y_write("kwinrc", "Effect-colorblindnesscorrection", "Intensity",
                             f"{intensity:.2f}", "double",
                             then=lambda: dbus("org.kde.KWin", "/Effects",
                                               "org.kde.kwin.Effects.reconfigureEffect",
                                               "string:colorblindnesscorrection"))
        self.a11yEffectSet("colorblindnesscorrection", on and mode is not None)
        self.a11yEffectSet("invert", on and kind in (0, 2))

    # ---------------------------------------------------- Magnifier
    @Slot(bool, bool)
    def a11yMagnifier(self, on: bool, lens: bool):
        """Full screen = effect `zoom`, Lens = effect `magnifier`. Start/stop by invoking
        the effect's global shortcuts (view_zoom_in / view_actual_size, component kwin:
        kwin/src/plugins/zoom/zoom.cpp:44-48, kstandardactions_p.h:89-94)."""
        self._a11y_mag_on = on
        self.a11yStateChanged.emit()
        self.a11yEffectSet("zoom", not lens)
        self.a11yEffectSet("magnifier", lens)
        name = "view_zoom_in" if on else "view_actual_size"
        QTimer.singleShot(600, lambda: dbus(
            "org.kde.kglobalaccel", "/component/kwin",
            "org.kde.kglobalaccel.Component.invokeShortcut", f"string:{name}"))

    # ---------------------------------------------------- Mouse pointer
    @Slot()
    def a11yRefreshCursors(self):
        def done(ok, out):
            themes = []
            cur = ""
            for line in out.splitlines():
                m = re.match(r"\s*\*\s+(.+?)\s+\[(.+?)\](.*)$", line)
                if m:
                    themes.append({"title": m.group(1), "name": m.group(2)})
                    if m.group(3).strip():
                        cur = m.group(2)
            if not cur:
                cur = self.a11yCfg("kcminputrc", "Mouse", "cursorTheme", "")
            self._a11y_cursor_themes, self._a11y_cursor_theme = themes, cur
            self.a11yCursorChanged.emit()
        self._async(["plasma-apply-cursortheme", "--list-themes"], done)

    @Slot(str)
    def a11yCursorThemeSet(self, name: str):
        self._a11y_cursor_theme = name
        self.a11yCursorChanged.emit()
        self._async(["plasma-apply-cursortheme", name])

    @Slot(int)
    def a11yCursorSizeSet(self, size: int):
        """kcminputrc [Mouse] cursorSize, then the KGlobalSettings CursorChanged (5)
        notification, as plasma-apply-cursortheme does (kcms-common.cpp:9-15)."""
        def then():
            spawn(["dbus-send", "--session", "--type=signal", "/KGlobalSettings",
                   "org.kde.KGlobalSettings.notifyChange", "int32:5", "int32:0"])
        self._a11y_write("kcminputrc", "Mouse", "cursorSize", str(size), "int", then=then)

    # ---------------------------------------------------- Text size (A11Y.TS.1)
    @Slot(int)
    def a11yApplyTextSize(self, pct: int):
        """Scale the size field of every font key; originals live in QSettings so 100 % restores."""
        pct = max(100, min(225, int(pct)))
        orig = json.loads(self._settings.value("a11y/origFonts", "") or "{}")
        if not orig and pct != 100:
            for g, k, _d in A11Y_FONT_KEYS:
                orig[f"{g}/{k}"] = self.a11yCfg("kdeglobals", g, k, "")
            self._settings.setValue("a11y/origFonts", json.dumps(orig))
        self._a11y_text_busy = True
        self.a11yTextChanged.emit()
        for g, k, default in A11Y_FONT_KEYS:
            base = orig.get(f"{g}/{k}", None)
            if pct == 100:
                if base is None:
                    continue
                if base:
                    self._a11y_write("kdeglobals", g, k, base)
                else:
                    self._a11y_write("kdeglobals", g, k, None)
            else:
                self._a11y_write("kdeglobals", g, k, _a11y_scale_font(base or default, pct))
        if pct == 100:
            self._settings.remove("a11y/origFonts")
        self._settings.setValue("a11y/textScale", pct)
        self._a11y_text_pct = pct
        self._a11y_text_busy = False
        self.a11yTextChanged.emit()

    # ---------------------------------------------------- On-screen keyboard (= TL.TYP.3)
    def _a11y_poll_vk(self):
        def done(ok, out):
            if not ok:
                return
            m = re.findall(r"b (true|false)", out)
            if len(m) >= 2:
                avail, act = m[0] == "true", m[1] == "true"
                if (avail, act) != (self._a11y_vk_available, self._a11y_vk_active):
                    self._a11y_vk_available, self._a11y_vk_active = avail, act
                    self.a11yStateChanged.emit()
        self._async(["busctl", "--user", "get-property", "org.kde.KWin", "/VirtualKeyboard",
                     "org.kde.kwin.VirtualKeyboard", "available", "active"], done, 3000)

    @Slot(bool)
    def a11yVkSet(self, on: bool):
        self._a11y_vk_active = on
        self.a11yStateChanged.emit()
        self._async(["busctl", "--user", "set-property", "org.kde.KWin", "/VirtualKeyboard",
                     "org.kde.kwin.VirtualKeyboard", "active", "b", "true" if on else "false"], None, 3000)

    # ---------------------------------------------------- Contrast themes (A11Y.CT.1)
    def _a11y_scheme_dir(self) -> Path:
        return Path(os.environ.get("XDG_DATA_HOME") or HOME / ".local" / "share") / "color-schemes"

    @Slot(str)
    def a11yContrastApply(self, key: str):
        """Install our .colors into ~/.local/share/color-schemes and apply it with
        plasma-apply-colorscheme (accepts a scheme name or .colors path:
        plasma-workspace/kcms/colors/plasma-apply-colorscheme.cpp:66-99)."""
        if key not in A11Y_CONTRAST or not has("plasma-apply-colorscheme"):
            return
        sid = A11Y_CONTRAST[key][0]
        prev = self.a11yCfg("kdeglobals", "General", "ColorScheme", "")
        if prev and prev not in {s for s, _ in A11Y_CONTRAST.values()}:
            self._settings.setValue("a11y/prevScheme", prev)
        dest = self._a11y_scheme_dir()
        try:
            dest.mkdir(parents=True, exist_ok=True)
            for s, _n in A11Y_CONTRAST.values():
                shutil.copyfile(ROOT / "qml" / "pages" / "accessibility" / "contrast" / f"{s}.colors",
                                dest / f"{s}.colors")
        except OSError:
            return
        self._a11y_contrast_busy = True
        self.a11yContrastChanged.emit()

        def done(_ok, _out):
            self._a11y_contrast_busy = False
            self._a11y_over[("kdeglobals", "General", "ColorScheme")] = sid
            self._a11y_ini_cache.clear()
            self._a11y_bump()
            self.a11yContrastChanged.emit()
        self._async(["plasma-apply-colorscheme", sid], done, 15000)

    @Slot()
    def a11yContrastOff(self):
        """Go back to the scheme that was active before (Breeze Light as a fallback)."""
        prev = str(self._settings.value("a11y/prevScheme", "") or "BreezeLight")
        self._a11y_contrast_busy = True
        self.a11yContrastChanged.emit()

        def done(_ok, _out):
            self._a11y_contrast_busy = False
            self._a11y_over.pop(("kdeglobals", "General", "ColorScheme"), None)
            self._a11y_ini_cache.clear()
            self._a11y_bump()
            self.a11yContrastChanged.emit()
        self._async(["plasma-apply-colorscheme", prev], done, 15000)
