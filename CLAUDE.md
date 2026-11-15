# WinPlusSettingKde — notes for Claude Code

A Windows 11 Settings app clone for KDE Plasma 6, **1:1 with Windows 11** in look, layout and motion.
Personal project by Patch. Target machine: Kubuntu 26.10, Plasma 6.7, **Qt/PySide6 6.11**, Wayland, 1.25× scale.

## Goal
Every page should be built inside this app in Fluent / Windows 11 style. Handing off to a KDE KCM window
(`Backend.openKcm`) is a temporary fallback only; replacing those hand-offs with native pages is the main work.
When unsure how something should look or behave, match the real Windows 11 Settings app.

## Stack / layout
- `main.py` — entry. Basic Quick Controls style, alpha buffer (rounded corners), font pick, registers `Backend` singleton (`import WinSettings`) and the `image://icon` provider.
- `backend.py` — ALL system integration. One `Backend(QObject)` with Properties + Slots used from QML. Talks to Plasma through CLI tools and D-Bus only: `kreadconfig6`/`kwriteconfig6` (`kread`/`kwrite`, nested groups as `"AC/Display"`), `plasma-apply-*`, `kscreen-doctor`, `pactl`, `bluetoothctl`, `nmcli`, `powerprofilesctl`, `timedatectl`, `dbus-send`.
- `qml/Theme.qml` — singleton: Fluent colors (light/dark), metrics, **motion tokens** (`durFaster 83 / durFast 167 / durNormal 250 / durSlow 333 / durPage`, bezier curves `decelerate` / `accelerate` / `standard`), and vector glyphs (`gChevronRight`...).
- `qml/Router.qml` — singleton nav bus: `open(page, props)` = drill-in push, `back()`, `openNav(i)`, `activate(entry)`.
- `qml/Data.js` — nav tree, list pages, search index. Entries open `page:` / `kcm:` / `cmd:`. `custom(title, icon, page, items)` for a top-level page that also lists items.
- Components: `SettingsPage` (breadcrumb + scrolling column; children go into the column), `SettingsCard`, `ExpanderCard` + `ExpanderRow`, `HomeCard` + `HomeRow`, `KcmListPage` (with `header` Component slot + `listTitle`), `FluentToggle`, `FluentCombo`, `FluentButton`, `FluentSlider`, `IconButton`, `InputDialog`, `SectionHeader`, `Icon`, `Glyph`, `FlyoutBackground`.
- Pages: Home, Display, Sound, Power, About, Bluetooth, Network, Colors, DateTime, KcmListPage.
- `qml/icons/` — bundled Microsoft Fluent UI System Icons (MIT). Source: `npm pack @fluentui/svg-icons`.

## Conventions (follow these)
- **Icons:** always bundled Fluent: `"fl:<file stem>"` e.g. `fl:desktop_20_regular`; nav uses `*_20_color`; fixed tint `fl:bluetooth_20_filled@0078d4`. Mono icons auto-recolor for dark mode. Copy any new SVG into `qml/icons/` and check it exists.
- **Controlled controls:** `FluentToggle` / `FluentCombo` emit `toggled(v)` / `activated(i)`; bind `checked` / `currentIndex` to Backend state and update state in the slot (optimistic update + emit). Use `autoSelect: true` only for combos without live state.
- **Backend pattern:** state in `self._x`, `Property(type, getter, notify=xChanged)`, mutate in a `@Slot` then emit. Slow or possibly-hanging commands go through `self._async(args, callback(ok, out), timeout_ms)` — never block the GUI thread. Fast sliders use `self._later(key, args)` (debounced).
- **Motion:** use Theme tokens + `Easing.BezierSpline`. Hover/press color: `Behavior on color { ColorAnimation { duration: Theme.durFaster } }`. Page transitions live in `Main.qml` (replace = entrance slide-up, push = drill-in zoom, pop = reverse).
- New page: `qml/XPage.qml` starting `SettingsPage { crumbs: ["Parent", "X"] ... }`, then point a `Data.js` entry at `page: "XPage.qml"`, add search keywords to `pageSettings`.

## Qt 6.11 / QML gotchas already hit
- `Image.implicitWidth/Height` are **read-only** → size icons with `Layout.preferredWidth/Height`.
- `Item` now has **FINAL `top` / `bottom`** properties → never declare custom properties named `top`, `bottom`, `left`, `right`.
- Inline `component X: ...` **can't see ids** of the enclosing file — pass data via properties or put helper functions inside the component.
- Don't give an id the same name as a property of a derived type (e.g. id `header` vs property `header`).
- `QQuickWindow.setDefaultAlphaBuffer(True)` must run before the engine loads.

## Test loop
There is no automated test. After changes:
1. `python3 -m py_compile backend.py main.py`
2. `./run.sh` from a terminal — **read every QML warning/error**; a single error ("Type X unavailable") stops the whole window.
3. Click through the page you changed, in light AND dark mode.
4. `./install.sh` so the launcher entry ("Settings 11") gets the new version.
Only claim something works after it ran without QML errors.

## Commits
Small focused commits with clear messages; push to `main` on `patchon-t/WinPlusSettingKde`.
