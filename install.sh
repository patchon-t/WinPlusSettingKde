#!/usr/bin/env bash
# Install WinPlusSettingKde into your app launcher (no root needed).
# Run once:  ./install.sh      Update later:  git pull && ./install.sh
set -e
SRC="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
APP_ID="io.github.patchon_t.WinPlusSettingKde"
DEST="$HOME/.local/share/WinPlusSettingKde"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor/scalable/apps"

# PySide6 check: use the distro package if possible
if ! python3 -c "import PySide6.QtQuick" 2>/dev/null; then
    echo "PySide6 isn't installed. On Kubuntu/Debian run:"
    echo "  sudo apt install python3-pyside6.qtquick python3-pyside6.qtquickcontrols2 python3-pyside6.qtqml"
    echo "(or the app will download it into a .venv on first launch, which is slower)"
fi

echo "Installing to $DEST"
mkdir -p "$DEST" "$APPS" "$ICONS"
# copy app files (skip git data, venv, caches)
tar -C "$SRC" --exclude=.git --exclude=.venv --exclude=__pycache__ -cf - . | tar -C "$DEST" -xf -
chmod +x "$DEST/run.sh" "$DEST/main.py"

cp "$SRC/assets/icon.svg" "$ICONS/$APP_ID.svg"

cat > "$APPS/$APP_ID.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Settings 11
GenericName=Settings
Comment=Windows 11 style settings for KDE Plasma
Exec=$DEST/run.sh
Icon=$APP_ID
Terminal=false
Categories=Settings;Qt;KDE;
Keywords=settings;windows;control;display;colors;bluetooth;
StartupWMClass=WinPlusSettingKde
DESKTOP

# refresh the launcher's app database
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" >/dev/null 2>&1 || true

echo "Done. Open the app launcher and search \"Settings 11\"."
