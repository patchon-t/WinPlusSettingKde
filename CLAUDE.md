# WinPlusSettingKde — notes for Claude Code

A Windows 11 Settings app clone for KDE Plasma 6, **1:1 with Windows 11** in look, layout and motion.
Personal project by Patch. Target machine: Kubuntu 26.10, Plasma 6.7, **Qt/PySide6 6.11**, Wayland, 1.25× scale.

## Goal
Every page should be built inside this app in Fluent / Windows 11 style. Handing off to a KDE KCM window
(`Backend.openKcm`) is a temporary fallback only; replacing those hand-offs with native pages is the main work.
When unsure how something should look or behave, match the real Windows 11 Settings app.

## Stack / layout
- `main.py` — entry. Basic Quick Controls style, alpha buffer (rounded corners), font pick, registers `Backend` singleton (`import WinSettings`) and the `image://icon` provider.
- `backend/` — ALL system integration. One `Backend(QObject)` (in `backend/__init__.py`) assembled from one mixin per section; Properties + Slots used from QML. Talks to Plasma through CLI tools and D-Bus only: `kreadconfig6`/`kwriteconfig6` (`kread`/`kwrite`, nested groups as `"AC/Display"`), `plasma-apply-*`, `kscreen-doctor`, `pactl`, `bluetoothctl`, `nmcli`, `powerprofilesctl`, `timedatectl`, `dbus-send`.
  - `util.py` helpers (`run`, `spawn`, `kread`, `kwrite`, `dbus`, `prop`...), `core.py` (`_async`, `_later`, `_pollers`, `openKcm`), `icons.py` (IconProvider) — shared.
  - Sections: `system.py`, `bluetooth.py`, `network.py`, `personalization.py`, `apps.py`, `accounts.py`, `time_language.py`, `gaming.py`, `accessibility.py`, `privacy.py`, `updates.py`. Each is a `XMixin` with `_init_<section>()`; register periodic status checks with `self._pollers.append(fn)`.
  - All mixins share one namespace. `backend/__init__.py` refuses to start if two mixins define the same name — prefix private helpers/state with your section if in doubt.
- `qml/Theme.qml` — singleton: Fluent colors (light/dark), metrics, **motion tokens** (`durFaster 83 / durFast 167 / durNormal 250 / durSlow 333 / durPage`, bezier curves `decelerate` / `accelerate` / `standard`), and vector glyphs (`gChevronRight`...).
- `qml/Router.qml` — singleton nav bus: `open(page, props)` = drill-in push, `back()`, `openNav(i)`, `activate(entry)`.
- `qml/Data.js` — merges `qml/data/<section>.js`. Each section file exports `entry` (its nav entry) and `settings` (search keywords for settings inside its pages). Entries open `page:` / `kcm:` / `cmd:`; nested `items` are walked by search. Builders `H.list(...)` / `H.custom(title, icon, page, items)` live in `data/helpers.js`.
- Shared components (in `qml/`): `SettingsPage` (breadcrumb + scrolling column; children go into the column), `SettingsCard`, `ExpanderCard` + `ExpanderRow`, `HomeCard` + `HomeRow`, `KcmListPage` (with `header` Component slot + `listTitle`), `FluentToggle`, `FluentCombo`, `FluentButton`, `FluentSlider`, `IconButton`, `InputDialog`, `SectionHeader`, `Icon`, `Glyph`, `FlyoutBackground`, `FText`, `LinkText`, `Avatar`.
- Pages: `qml/pages/<section>/` (home, system, bluetooth, network, personalization, apps, accounts, time_language, gaming, accessibility, privacy, updates). Pages start with `import "../.."` to see the shared components. **Page paths are relative to `qml/`** everywhere: `Router.open("pages/system/DisplayPage.qml", {})`, `page: P + "DisplayPage.qml"` in data files.
- `qml/icons/` — bundled Microsoft Fluent UI System Icons (MIT). Source: `npm pack @fluentui/svg-icons`.
- `SITEMAP.md` — the full Win11 Settings tree with the Linux equivalent of every setting and how it was verified.

## Conventions (follow these)
- **Icons:** always bundled Fluent: `"fl:<file stem>"` e.g. `fl:desktop_20_regular`; nav uses `*_20_color`; fixed tint `fl:bluetooth_20_filled@0078d4`. Mono icons auto-recolor for dark mode. Copy any new SVG into `qml/icons/` and check it exists.
- **Controlled controls:** `FluentToggle` / `FluentCombo` emit `toggled(v)` / `activated(i)`; bind `checked` / `currentIndex` to Backend state and update state in the slot (optimistic update + emit). Use `autoSelect: true` only for combos without live state.
- **Config writes:** `kwrite(file, group, key, value, kind)` passes `--notify` (default) so KConfigWatcher daemons apply changes live; `kdelete(...)` resets a key to default. Every key/method you use must be in `SITEMAP.md` (verified) — never invent one.
- **Backend pattern:** state in `self._x`, `Property(type, getter, notify=xChanged)`, mutate in a `@Slot` then emit. Slow or possibly-hanging commands go through `self._async(args, callback(ok, out), timeout_ms)` — never block the GUI thread. Fast sliders use `self._later(key, args)` (debounced).
- **Motion:** use Theme tokens + `Easing.BezierSpline`. Hover/press color: `Behavior on color { ColorAnimation { duration: Theme.durFaster } }`. Page transitions live in `Main.qml` (replace = entrance slide-up, push = drill-in zoom, pop = reverse).
- New page: `qml/pages/<section>/XPage.qml` starting `import "../.."` + `SettingsPage { crumbs: ["Parent", "X"] ... }`, then point an entry in `qml/data/<section>.js` at `page: P + "XPage.qml"` and add search keywords to that file's `settings`.

## Qt 6.11 / QML gotchas already hit
- `Image.implicitWidth/Height` are **read-only** → size icons with `Layout.preferredWidth/Height`.
- `Item` now has **FINAL `top` / `bottom`** properties → never declare custom properties named `top`, `bottom`, `left`, `right`.
- Inline `component X: ...` **can't see ids** of the enclosing file — pass data via properties or put helper functions inside the component.
- **Never name a property `on<Capital>…`** (`onAccent`, `onText`): QML parses it as a signal handler and the binding silently never runs (value stays default). Use `textOnAccent`, `checkedText`, etc.
- Don't give an id the same name as a property of a derived type (e.g. id `header` vs property `header`).
- `QQuickWindow.setDefaultAlphaBuffer(True)` must run before the engine loads.

## Test loop
There is no automated test. After changes:
1. `python3 -m py_compile backend/*.py main.py`
2. `./run.sh` from a terminal — **read every QML warning/error**; a single error ("Type X unavailable") stops the whole window.
3. Click through the page you changed, in light AND dark mode.
4. `./install.sh` so the launcher entry ("Settings 11") gets the new version.
Only claim something works after it ran without QML errors.

## Commits
Small focused commits with clear messages; push to `main` on `patchon-t/WinPlusSettingKde`.
