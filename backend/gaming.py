"""Gaming: Captures (Spectacle save locations), game controller as mouse.

Mechanisms (SITEMAP section 8, verified in Plasma 6.7.6 sources):
  spectaclerc [ImageSave] imageSaveLocation, [VideoSave] videoSaveLocation  (Url)
      spectacle/src/Gui/SettingsDialog/spectacle.kcfg; defaults are
      <Pictures>/Screenshots/ and <Videos>/Screencasts/.
  kwinrc [Plugins] gamecontrollerEnabled + org.kde.KWin /Plugins
      org.kde.KWin.Plugins.LoadPlugin|UnloadPlugin("gamecontroller")
      (what plasma-desktop/kcms/gamecontroller/kcm.cpp:58-77 does).
"""
from __future__ import annotations

import os

from PySide6.QtCore import QStandardPaths, QUrl, Signal, Slot

from .util import dbus, kread, kwrite, prop, spawn

_GAM_CAPTURES = {
    # kind: (group, key, standard location, default sub folder)
    "image": ("ImageSave", "imageSaveLocation", QStandardPaths.PicturesLocation, "Screenshots"),
    "video": ("VideoSave", "videoSaveLocation", QStandardPaths.MoviesLocation, "Screencasts"),
}


def _gam_default_dir(kind: str) -> str:
    _g, _k, loc, sub = _GAM_CAPTURES[kind]
    return os.path.join(QStandardPaths.writableLocation(loc), sub)


def _gam_local(value: str) -> str:
    """spectaclerc stores a URL (file:///...); accept a plain path too."""
    if value.startswith("file:"):
        value = QUrl(value).toLocalFile()
    return value.rstrip("/") or value


class GamingMixin:
    gamingChanged = Signal()

    def _init_gaming(self):
        self._gam_shots = _gam_default_dir("image")
        self._gam_clips = _gam_default_dir("video")
        self._gam_pad_mouse = False

    gamingScreenshotDir = prop("gam_shots", str, gamingChanged)
    gamingRecordingDir = prop("gam_clips", str, gamingChanged)
    gamingControllerMouse = prop("gam_pad_mouse", bool, gamingChanged)

    @Slot()
    def refreshGaming(self):
        """Instant local config reads (kreadconfig6), called when a page opens."""
        for kind, attr in (("image", "_gam_shots"), ("video", "_gam_clips")):
            group, key, _loc, _sub = _GAM_CAPTURES[kind]
            raw = kread("spectaclerc", group, key, "")
            setattr(self, attr, _gam_local(raw) if raw else _gam_default_dir(kind))
        self._gam_pad_mouse = kread("kwinrc", "Plugins", "gamecontrollerEnabled", "false") == "true"
        self.gamingChanged.emit()

    @Slot(str, str)
    def setGamingCaptureDir(self, kind: str, path: str):
        """kind = "image" | "video"; path = local folder chosen in the dialog."""
        if kind not in _GAM_CAPTURES or not path:
            return
        path = _gam_local(path)
        group, key, _loc, _sub = _GAM_CAPTURES[kind]
        setattr(self, "_gam_shots" if kind == "image" else "_gam_clips", path)
        self.gamingChanged.emit()
        # Spectacle writes the folder URL with a trailing slash; keep that format.
        kwrite("spectaclerc", group, key, QUrl.fromLocalFile(path + "/").toString())

    @Slot(str)
    def openGamingCaptureDir(self, kind: str):
        path = self._gam_shots if kind == "image" else self._gam_clips
        try:
            os.makedirs(path, exist_ok=True)      # Spectacle creates it on first save
        except OSError:
            return
        spawn(["xdg-open", path])

    @Slot(bool)
    def setGamingControllerMouse(self, on: bool):
        self._gam_pad_mouse = on
        self.gamingChanged.emit()
        kwrite("kwinrc", "Plugins", "gamecontrollerEnabled", "true" if on else "false", "bool")
        dbus("org.kde.KWin", "/Plugins",
             "org.kde.KWin.Plugins." + ("LoadPlugin" if on else "UnloadPlugin"),
             "string:gamecontroller")
