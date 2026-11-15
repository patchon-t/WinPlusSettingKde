"""Personalization: colors (dark mode, accent, transparency), wallpaper."""
from __future__ import annotations

import re
from pathlib import Path

from PySide6.QtCore import Property, QUrl, Signal, Slot

from .util import HOME, IMG_EXT, best_image, file_url, kread, kwin_reconfigure, kwrite, prop, rgb_to_hex


class PersonalizationMixin:
    darkChanged = Signal()
    accentChanged = Signal()
    accentAutoChanged = Signal()
    recentAccentsChanged = Signal()
    blurChanged = Signal()
    wallpaperChanged = Signal()

    def _init_personalization(self):
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
