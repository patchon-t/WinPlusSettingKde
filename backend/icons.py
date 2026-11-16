"""image://icon provider: bundled Fluent SVGs (fl:...) + system icon theme."""
from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import QSize, Qt
from PySide6.QtGui import QIcon, QPixmap
from PySide6.QtQuick import QQuickImageProvider

from .util import HOME, ICON_DIR

try:
    from PySide6.QtQml import QQmlImageProviderBase
    PIXMAP = QQmlImageProviderBase.ImageType.Pixmap
except (ImportError, AttributeError):
    PIXMAP = QQuickImageProvider.ImageType.Pixmap

CACHE_DIR = HOME / ".cache" / "WinPlusSettingKde" / "icons"


class IconProvider(QQuickImageProvider):
    """image://icon/<name>[|fallback...]?<d|l>

    name = "fl:<stem>[@rrggbb]"  bundled Fluent SVG from qml/icons/<stem>.svg.
           *_color icons keep their own colors; mono icons get the tint, or the
           theme text color (dark/light) when no tint is given.
    name = anything else          looked up in the system icon theme.
    """

    def __init__(self, backend):
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
            elif name.startswith("/"):            # .desktop Icon=/absolute/path.png
                icon = QIcon(name) if Path(name).is_file() else QIcon()
            else:
                QIcon.setThemeName(self._b.icon_theme(dark))
                icon = QIcon.fromTheme(name)
            if not icon.isNull():
                return icon.pixmap(QSize(px, px))
        pm = QPixmap(px, px)
        pm.fill(Qt.transparent)
        return pm

