# WinPlusSettingKde

A Settings app for KDE Plasma 6 that looks like the Windows 11 Settings app. Personal project.

Built with **PySide6 + QML**. It doesn't reimplement Plasma's settings: it changes the real
Plasma config through the tools Plasma already ships (`kwriteconfig6`, `plasma-apply-*`,
`kscreen-doctor`, D-Bus), and opens the stock KCM modules for pages that aren't rebuilt yet.

## Run

```bash
git clone https://github.com/patchon-t/WinPlusSettingKde
cd WinPlusSettingKde
./run.sh            # makes a .venv with PySide6 on first launch
```

Or use your distro's PySide6 (`pyside6` on Arch, `python3-pyside6.*` on Debian/Ubuntu) and run
`python3 main.py`.

### Install to the app menu (optional)

```bash
mkdir -p ~/.local/share && cp -r . ~/.local/share/WinPlusSettingKde
cp io.github.patchon_t.WinPlusSettingKde.desktop ~/.local/share/applications/
```

## What works

| Page | Real settings |
|---|---|
| **Home** | wallpaper picker (`plasma-apply-wallpaperimage`), light/dark mode, Bluetooth toggle, rename PC (`pkexec hostnamectl`), disk usage, OS / Plasma / kernel info, network status |
| **System → Display** | resolution, refresh rate, scale, orientation, HDR, multi-display mode (`kscreen-doctor`), night light (`kwinrc`), brightness (PowerDevil D-Bus), Identify |
| **Personalization → Colors** | light/dark (`plasma-apply-colorscheme`), the Win11 48-color accent grid + recent + custom picker (`--accent-color`), automatic accent from wallpaper, transparency (KWin blur/contrast) |
| Everything else | Win11-style list pages that open the matching Plasma KCM (`kcmshell6`) |

Search (Ctrl+F) covers the nav, every list entry and the settings inside the custom pages.

## Known limits / best-effort

- **Light/Dark** switches to **Breeze Light / Breeze Dark**. If you use a different color
  scheme, change the names in `Backend.setDark`.
- **Brightness** uses the PowerDevil D-Bus API. If your Plasma version doesn't expose it, the card hides itself.
- **Automatic accent** writes `accentColorFromWallpaper`; Plasma may need a re-login to pick it up.
- **Mica** is faked with a tinted gradient. There's no real KWin blur-behind yet.
- The window is frameless (own title bar). Resizing works from the edges.

## Making it look more 1:1

- **Font:** put Segoe UI Variable in `fonts/` (see `fonts/README.md`).
- **Icons:** drop SVGs named after the icon in `qml/icons/` (for example `video-display.svg`) and
  they override the theme icon. [Fluent UI System Icons](https://github.com/microsoft/fluentui-system-icons)
  are MIT-licensed.

## Layout

```
main.py                 app entry, font pick, QML engine
backend.py              all Plasma integration (properties + slots for QML)
qml/
  Main.qml              window, title bar, nav, page stack
  Theme.qml             Fluent design tokens, light + dark
  Data.js               nav tree + list pages + search index
  SettingsCard / ExpanderCard / HomeCard / Fluent*   reusable Win11 components
  HomePage / KcmListPage / DisplayPage / ColorsPage  pages
```

Adding a page: create `qml/MyPage.qml` starting with `SettingsPage { crumbs: ["System", "My page"] ... }`,
then point an entry in `Data.js` at it with `page: "MyPage.qml"`.

## License

MIT
