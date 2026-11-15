#!/usr/bin/env bash
set -e
APP_ID="io.github.patchon_t.WinPlusSettingKde"
rm -rf "$HOME/.local/share/WinPlusSettingKde" "$HOME/.cache/WinPlusSettingKde"
rm -f "$HOME/.local/share/applications/$APP_ID.desktop" \
      "$HOME/.local/share/icons/hicolor/scalable/apps/$APP_ID.svg"
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
echo "WinPlusSettingKde removed."
