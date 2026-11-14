#!/usr/bin/env python3
"""WinPlusSettingKde - a Windows 11 style Settings app for KDE Plasma 6."""
import sys
from pathlib import Path

from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtGui import QFontDatabase, QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterSingletonInstance
from PySide6.QtQuickControls2 import QQuickStyle

from backend import Backend, IconProvider

ROOT = Path(__file__).resolve().parent

# First installed family wins. Drop Segoe UI Variable .ttf files into ./fonts
# for the real Windows look (not redistributable, so it's not in the repo).
FONT_PREFERENCE = [
    "Segoe UI Variable Text", "Segoe UI Variable", "Segoe UI",
    "Selawik", "Inter", "Noto Sans",
]


def pick_font():
    fonts_dir = ROOT / "fonts"
    if fonts_dir.is_dir():
        for f in fonts_dir.iterdir():
            if f.suffix.lower() in (".ttf", ".otf"):
                QFontDatabase.addApplicationFont(str(f))
    families = set(QFontDatabase.families())
    return next((f for f in FONT_PREFERENCE if f in families), None)


def main():
    QQuickStyle.setStyle("Basic")  # fully restylable controls
    QCoreApplication.setOrganizationName("patchon-t")
    QCoreApplication.setApplicationName("WinPlusSettingKde")

    app = QGuiApplication(sys.argv)
    app.setDesktopFileName("io.github.patchon_t.WinPlusSettingKde")
    app.setWindowIcon(QIcon.fromTheme("preferences-system"))

    family = pick_font()
    if family:
        font = app.font()
        font.setFamily(family)
        app.setFont(font)

    backend = Backend()
    qmlRegisterSingletonInstance(Backend, "WinSettings", 1, 0, "Backend", backend)

    engine = QQmlApplicationEngine()
    provider = IconProvider(backend)
    engine.addImageProvider("icon", provider)
    engine.load(QUrl.fromLocalFile(str(ROOT / "qml" / "Main.qml")))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
