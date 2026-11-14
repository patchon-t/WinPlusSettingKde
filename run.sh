#!/usr/bin/env bash
# Launch WinPlusSettingKde.
# 1. Use the system PySide6 if it's installed (apt/pacman/dnf).
# 2. Otherwise use (or build) a local .venv with PySide6 from pip.
set -e
cd "$(dirname "$(readlink -f "$0")")"

if python3 -c "import PySide6.QtQuick" 2>/dev/null; then
    exec python3 main.py "$@"
fi

# venv missing or broken (e.g. a cancelled install) -> rebuild it
if ! .venv/bin/python -c "import PySide6.QtQuick" 2>/dev/null; then
    echo "Setting up PySide6 in .venv (first run, ~200 MB)..."
    rm -rf .venv
    python3 -m venv .venv
    .venv/bin/pip install -r requirements.txt
fi
exec .venv/bin/python main.py "$@"
