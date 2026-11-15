# SITEMAP — Windows 11 (24H2) Settings → KDE Plasma 6.7

The full Windows 11 24H2 Settings tree, section → page → sub page → setting.
For every setting: the Linux/Plasma equivalent, how to read/write it, and how
that was verified. Section owners build exactly this tree, in this order and
with this wording.

## How this was verified (read this first)

Your machine (Kubuntu 26.10, Plasma 6.7) could not be reached from the cloud
session that wrote this file: no Remote Control folder was shared. So nothing here was
run on *your* machine. Instead, every entry carries one of these tags:

| Tag | Meaning |
|---|---|
| **APP** | Already used by this app's current code (written against your machine). Not re-run by me. |
| **SRC** | Verified in upstream source at the version you run: Plasma repos at tag **v6.7.6** (kwin, plasma-workspace, plasma-desktop, powerdevil, kscreen, libkscreen, plasma-nm, bluedevil, plasma-pa, kscreenlocker, discover, krdp, …), frameworks/gear/BlueZ/NetworkManager/xdg-desktop-portal at master of 2026-11-15. Config keys come from the `.kcfg` / `main.xml` schema (exact file, group, key, type, default). D-Bus members come from the interface XML or `Q_CLASSINFO`/`Q_SCRIPTABLE` + `registerObject` path. File cited as `repo/path`. |
| **CLI** | Verified from the tool's own `--help` in an Ubuntu 24.04 container (NetworkManager 1.46, BlueZ 5.72, systemd 255, pactl, fwupd, flatpak, ufw, cups-client, PackageKit, fprintd, xdg-utils, util-linux). Your 26.10 versions are newer; subcommands used here are long-standing. |
| **UNVERIFIED** | Plausible but not confirmed in source or help. Do not ship as working until checked on the machine. |
| **N/A — hide** | No Linux equivalent; leave the row out of the page. |
| **N/A — disabled** | No Linux equivalent, but keep the row (greyed out, with a one-line reason) because it's important to the page's layout or users look for it. |
| **PARTIAL** | Linux has something close but not identical; the difference is noted. |
| ⚠ root | Needs privileges: use `pkexec` / a polkit-backed D-Bus call through `_async`, never block the GUI. |

`tools/verify_sitemap.sh` re-checks every D-Bus member and CLI used below **on
your machine** (read-only). Run it once and send me the output; anything that
fails gets re-marked before Phase 1.

### Shared rules for every section

* Config writes: `kwrite(file, group, key, value, kind, notify=True)` →
  `kwriteconfig6 --notify` (SRC `kconfig/src/kreadconfig/kwriteconfig.cpp:37`).
  Most Plasma daemons pick changes up through **KConfigWatcher**, which only fires on
  notifying writes (e.g. KWin reloads keyboard layouts that way,
  `kwin/src/keyboard_layout.cpp:101`). Use `--delete` to reset a key to default.
* Nested groups: `"A/B"` → `--group A --group B` (existing helper).
* KWin settings without a watcher: call `org.kde.KWin /KWin org.kde.KWin.reconfigure` (SRC `kwin/src/org.kde.KWin.xml`).
* Plasma panel/applet/wallpaper settings: `org.kde.plasmashell /PlasmaShell
  org.kde.PlasmaShell.evaluateScript(js)` (SRC `plasma-workspace/shell/dbus/org.kde.PlasmaShell.xml`).
  Script API verified in `plasma-workspace/shell/scripting/`: globals `panels()`, `desktops()`;
  panel props `location, alignment (left|center|right), hiding (none|autohide|dodgewindows|windowsgobelow),
  height, floating, lengthMode, length`; containment `widgets()`, `wallpaperPlugin`;
  widget `type`, `currentConfigGroup = [...]`, `readConfig(k)`, `writeConfig(k, v)`, `reloadConfig()`.
* Per-device input settings: set D-Bus properties on `org.kde.KWin /org/kde/KWin/InputDevice/<sysName>
  org.kde.KWin.InputDevice`; KWin persists them to `kcminputrc [Libinput][<vendor>][<product>][<name>]`
  itself (SRC `kwin/src/backends/libinput/device.cpp:245-260, 533`, `connection.cpp:714`). List devices with
  property `devicesSysNames` (all devices, including tablets) or `ListPointers|ListKeyboards|ListTouch` on `org.kde.KWin /org/kde/KWin/InputDevice org.kde.KWin.InputDeviceManager` (the manager lives at `/org/kde/KWin/InputDevice`, SRC `connection.cpp:64`). Mouse = `pointer && !touchpad && !tabletTool && !tabletPad`.

### Bugs found in the current code while verifying

1. **Identify displays is broken on 6.7.** `identifyDisplays()` calls
   `org.kde.kscreen.osdService.showOutputIdentifier`, which no longer exists (6.7 interface has only
   `hideOsd`, `showActionSelector`: SRC `kscreen/osd/org.kde.kscreen.osdService.xml`). The Display KCM now calls
   `org.kde.KWin /org/kde/KWin/Effect/OutputLocator1 org.kde.KWin.Effect.OutputLocator1.show`
   (SRC `kscreen/kcm/kcm.cpp:251-257`, `kwin/src/plugins/outputlocator/outputlocator.cpp:50`). → System owner fixes.
2. **`kwrite()` never notifies.** Writes land in the file but running daemons using KConfigWatcher don't
   see them until restart. → Fixed in `backend/util.py` (new `notify` argument, default True).
3. "Show accent color on title bars" is **not a user key**: `TitlebarIsAccentColored` is read from the active
   *color scheme file* (SRC `plasma-workspace/kcms/colors/colorsapplicator.cpp:155`). See PER.COL.6.

---
## 1. System  · owner: `backend/system.py`, `qml/pages/system/`, `qml/data/system.js`

Nav order (24H2): Display · Sound · Notifications · Focus · Power & battery · Storage · Nearby sharing ·
Multitasking · For developers · Activation · Troubleshoot · Recovery · Projecting to this PC · Remote Desktop ·
Clipboard · System components · Optional features · About.
Hide: Activation, Troubleshoot, Recovery, Projecting to this PC, System components (all N/A).

### 1.1 Display
`kscreen-doctor` ops verified in SRC `libkscreen/src/doctor/doctor.cpp` (`output.<name>.<op>[.<value>]`):
`enable, disable, mode.<id>, position.x,y, priority.<n>, scale.<f>, rotation|orientation.<normal|left|right|inverted|flipped…>,
vrrpolicy.<never|always|automatic>, rgbrange.<automatic|full|limited>, hdr.<enable|disable|toggle>, sdr-brightness.<n>,
wcg.<enable|disable|toggle>, iccprofile.<path>, brightness.<0-100>, mirror, maxbpc, abm.<0-4>, colorPowerTradeoff.<preferEfficiency|preferAccuracy>`.
Read: `kscreen-doctor -j` (APP).

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.DISP.1 | Monitor arrangement canvas, drag to rearrange | `kscreen-doctor output.X.position.x,y` | APP (read) · SRC (write) |
| SYS.DISP.2 | Identify | `org.kde.KWin /org/kde/KWin/Effect/OutputLocator1 org.kde.KWin.Effect.OutputLocator1.show` | SRC (fixes bug 1) |
| SYS.DISP.3 | Detect | re-run `kscreen-doctor -j` (`reloadOutputs`) | APP |
| **Brightness & color** ||||
| SYS.DISP.4 | Brightness slider | Internal panel: `org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl …BrightnessControl.setBrightness/brightness/brightnessMax` (APP). Per-display (external DDC too): `org.kde.ScreenBrightness /org/kde/ScreenBrightness` prop `DisplaysDBusNames`; each `/org/kde/ScreenBrightness/<name>` iface `org.kde.ScreenBrightness.Display` props `Label, IsInternal, Brightness, MaxBrightness`, method `SetBrightness` | APP · SRC `powerdevil/daemon/dbus/org.kde.ScreenBrightness*.xml`, `powerdevilscreenbrightnessagent.cpp:30` |
| SYS.DISP.5 | Change brightness based on content (Off / Always / On battery only) | AMD panel ABM: `kscreen-doctor output.X.abm.0-4`. Only "Off/Always"; no battery-only. | PARTIAL · SRC |
| SYS.DISP.6 | Night light (toggle + ›) | `kwinrc [NightColor] Active` (Bool) + reconfigure | APP · SRC `plasma-workspace/kcms/nightlight/nightlightsettings.kcfg` |
| SYS.DISP.6a | › Turn on now | `kwinrc [NightColor] Active=true, Mode=Constant` | SRC (choices `Constant, DarkLight`) |
| SYS.DISP.6b | › Strength slider | `kwinrc [NightColor] NightTemperature` (Int, default 4500, K); live preview `org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight.preview(u)` / `stopPreview` | SRC `kwin/src/plugins/nightlight/org.kde.KWin.NightLight.xml` |
| SYS.DISP.6c | › Schedule night light (toggle) | `kwinrc [NightColor] Mode=DarkLight` (follows the shared day/night schedule) vs `Constant` | SRC |
| SYS.DISP.6d | › Sunset to sunrise / Set hours | `knighttimerc [General] Source = Location \| Times`; `[Location] Automatic, Latitude, Longitude`; `[Times] SunsetStart, SunriseStart (Time), TransitionDuration (UInt s, default 1800)` | SRC `plasma-workspace/kcms/nighttime/nighttimesettings.kcfg` |
| SYS.DISP.6e | › status line ("Night light will turn on at …") | NightLight props `running, daylight, scheduledTransitionDateTime (t), currentTemperature (u)` | SRC |
| SYS.DISP.7 | HDR (›) Use HDR | `kscreen-doctor output.X.hdr.enable/disable` (APP); support read from `-o` text (APP) | APP |
| SYS.DISP.7a | › SDR content brightness | `kscreen-doctor output.X.sdr-brightness.<n>` | SRC |
| SYS.DISP.7b | › Wide color gamut (Win: "Use HDR" sub-option / Auto color mgmt) | `kscreen-doctor output.X.wcg.enable/disable` | SRC |
| SYS.DISP.7c | › Play streaming HDR video, Auto HDR, HDR video calibration | — | N/A — hide |
| SYS.DISP.8 | Color profile | `kscreen-doctor output.X.iccprofile.<path>` (list `~/.local/share/icc`, `/usr/share/color/icc`) | SRC (paths UNVERIFIED) |
| SYS.DISP.8a | Automatically manage color for apps | `kscreen-doctor output.X.colorPowerTradeoff.preferAccuracy/preferEfficiency` | PARTIAL · SRC |
| **Scale & layout** ||||
| SYS.DISP.9 | Scale (100/125/150/175/200 %) | `kscreen-doctor output.X.scale.<f>` | APP |
| SYS.DISP.9a | › Custom scaling | same op, free value (kscreen-doctor accepts `scale.<n>[.<n>]`) | SRC |
| SYS.DISP.9b | (extra) Legacy X11 apps: apply scaling themselves | `kdeglobals [KScreen] XwaylandClientsScale` (Bool, default true) | SRC `kscreen/kcm/globalscalesettings.kcfg` |
| SYS.DISP.10 | Display resolution | `kscreen-doctor output.X.mode.<id>` | APP |
| SYS.DISP.11 | Display orientation | `kscreen-doctor output.X.rotation.<normal\|left\|inverted\|right>` | APP |
| SYS.DISP.12 | Multiple displays: Extend / Duplicate / Show only on N | enable/disable (APP); Duplicate: `kscreen-doctor output.X.mirror.<name>`, undo `mirror.none`; read `replicationSource` from `-j` | APP · SRC `libkscreen/src/doctor/doctor.cpp:522`, `configserializer.cpp:72-131` |
| SYS.DISP.12a | Make this my main display | `kscreen-doctor output.X.priority.1` | SRC |
| SYS.DISP.12b | Remember window locations based on monitor connection; Minimize windows when a monitor is disconnected; Ease cursor movement between displays | KWin does this itself, no toggle | N/A — hide |
| **Related settings** ||||
| SYS.DISP.13 | › Advanced display: Select a display, Display information (desktop mode, active signal mode, bit depth, color format, color space, refresh rate) | read `kscreen-doctor -j` (modes, size, rate, HDR/WCG flags) | APP (read) · field names beyond the app's UNVERIFIED |
| SYS.DISP.13a | › Choose a refresh rate | `kscreen-doctor output.X.mode.<id>` | APP |
| SYS.DISP.13b | › Dynamic refresh rate | `kscreen-doctor output.X.vrrpolicy.never/automatic/always` | SRC |
| SYS.DISP.13c | › (extra) Max bits per color, RGB range | `maxbpc`, `rgbrange.automatic/full/limited` | SRC |
| SYS.DISP.14 | › Graphics: Default settings (Optimizations for windowed games, Auto HDR) | — | N/A — hide |
| SYS.DISP.14a | › Graphics: Variable refresh rate | = SYS.DISP.13b | SRC |
| SYS.DISP.14b | › Graphics: (extra) Allow tearing in full-screen games | `kwinrc [Compositing] AllowTearing` (Bool, default true) | SRC `kscreen/kcm/kwincompositing_setting.kcfg` |
| SYS.DISP.14c | › Graphics: Custom options for apps (GPU preference per app) | `.desktop` key `PrefersNonDefaultGPU=true` in a `~/.local/share/applications` override | UNVERIFIED (freedesktop spec, not checked against Plasma 6.7 launcher code) |
| SYS.DISP.14d | › Hardware-accelerated GPU scheduling | — | N/A — hide |

### 1.2 Sound
| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.SND.1 | Output: Choose where to play sound (device list) | `pactl -f json list sinks`, `set-default-sink` | APP |
| SYS.SND.2 | Output volume + mute | `pactl set-sink-volume/-mute @DEFAULT_SINK@` | APP |
| SYS.SND.3 | Mono audio | no Plasma/PipeWire toggle (needs a filter-chain config file) | N/A — disabled |
| SYS.SND.4 | Pair a new output device | → Bluetooth & devices › Add device | link |
| SYS.SND.5 | Input: device list, volume, mute | `pactl … sources`, `set-default-source`, `set-source-volume/-mute` | APP |
| SYS.SND.6 | All sound devices › device page: Rename | — | N/A — hide |
| SYS.SND.6a | › Allow apps and Windows to use this device | `pactl set-card-profile <card> off` / back to previous profile; cards from `pactl -f json list cards` | CLI (`set-card-profile`) · JSON fields UNVERIFIED |
| SYS.SND.6b | › Output settings: Volume, Left/Right channel balance | `pactl set-sink-volume <sink> L% R%` (multiple VOLUME args) | CLI |
| SYS.SND.6c | › Port (e.g. Headphones/Speakers) (Win: in device properties) | `pactl set-sink-port <sink> <port>` | CLI |
| SYS.SND.6d | › Format, Audio enhancements, Spatial sound | — | N/A — hide |
| SYS.SND.6e | › Input: Test your microphone (level meter) | no CLI peak meter verified | UNVERIFIED |
| SYS.SND.7 | Volume mixer: System master volume, output/input device | same as 1/2/5 | APP |
| SYS.SND.7a | Volume mixer: per-app volume + mute | `pactl -f json list sink-inputs`, `set-sink-input-volume #N`, `set-sink-input-mute #N` | CLI |
| SYS.SND.7b | Volume mixer: per-app output device | `pactl move-sink-input #N <sink>` (inputs: `move-source-output`) | CLI |
| SYS.SND.7c | Reset sound devices and volumes for all apps | — | N/A — hide |
| SYS.SND.8 | Troubleshoot common sound problems | — | N/A — hide |
| SYS.SND.9 | (extra, under Advanced) Raise maximum volume to 150 % | `plasmaparc [General] RaiseMaximumVolume` (Bool) | SRC `plasma-pa/src/globalconfig.kcfg` |
| SYS.SND.9a | (extra) Volume step, volume OSD, feedback sound | `plasmaparc [General] VolumeStep (Int 5), VolumeOsd, AudioFeedback` | SRC |
| SYS.SND.10 | More sound settings › Sounds (system sounds on/off, sound theme) | `kdeglobals [Sounds] Enable (Bool), Theme (String, "ocean")` | SRC `plasma-workspace/kcms/soundtheme/soundthemesettings.kcfg` |

### 1.3 Notifications
Live service watches the file (KConfigWatcher in `plasma-workspace/libnotificationmanager/settings.cpp`) → write with `--notify`.

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.NOT.1 | Notifications (master toggle) | no master switch; closest: Do not disturb until manually off (SYS.NOT.2) | PARTIAL |
| SYS.NOT.1a | › Play a sound when a notification arrives | `plasmanotifyrc [DoNotDisturb] NotificationSoundsMuted` is DND-only; global sound = `kdeglobals [Sounds] Enable` | PARTIAL · SRC |
| SYS.NOT.1b | › Show notifications on the lock screen / reminders & VoIP on lock screen | — | N/A — hide |
| SYS.NOT.2 | Do not disturb (toggle) | `plasmanotifyrc [DoNotDisturb] Until` (DateTime; far future = on, delete key = off) | SRC `libnotificationmanager/kcfg/donotdisturbsettings.kcfg`, `settings.cpp:526-539` |
| SYS.NOT.3 | Turn on DND automatically: During these times | — | N/A — disabled |
| SYS.NOT.3a | … When duplicating your display | `[DoNotDisturb] WhenScreensMirrored` (Bool, default true) | SRC |
| SYS.NOT.3b | … When playing a game / When using an app in full-screen mode | `[DoNotDisturb] WhenFullscreen` (Bool, default true): one key for both rows | PARTIAL · SRC |
| SYS.NOT.3c | … (extra) When sharing your screen | `[DoNotDisturb] WhenScreenSharing` | SRC |
| SYS.NOT.3d | … For the first hour after a feature update | — | N/A — hide |
| SYS.NOT.4 | Set priority notifications › Calls & reminders | `[Notifications] CriticalInDndMode` (Bool) | PARTIAL · SRC `notificationsettings.kcfg` |
| SYS.NOT.4a | › Apps (allowed to break through DND) | per app `[Applications][<desktop-entry>] ShowPopupsInDndMode` | SRC (`settings.cpp:134` group `Applications`; keys in `notificationsettings.kcfg` `$(DesktopEntry)`) |
| SYS.NOT.5 | Notifications from apps and other senders (list, sort by name / most recent) | apps = groups under `plasmanotifyrc [Applications]` + installed `.desktop` files with `X-KDE-…notifyrc`/`.notifyrc`; services under `[Services]` | SRC (`settings.cpp:129-134`) · discovery method UNVERIFIED |
| SYS.NOT.5a | › per app: Notifications on/off | `[Applications][<app>] ShowPopups` + `ShowInHistory` both false | SRC |
| SYS.NOT.5b | › Show notification banners | `ShowPopups` | SRC |
| SYS.NOT.5c | › Show notifications in notification center | `ShowInHistory` | SRC |
| SYS.NOT.5d | › Badges (Win: "Show badges on taskbar" per app) | `ShowBadges` | SRC |
| SYS.NOT.5e | › Hide content when on lock screen; Priority (Top/High/Normal) | — | N/A — hide |
| SYS.NOT.5f | › Play a sound | per-event `Action=Sound` in `~/.config/<app>.notifyrc` `[Event/<id>]` | UNVERIFIED (keys from `eventsettings.kcfg` exist; mapping not checked) |
| SYS.NOT.6 | Additional settings (welcome experience, tips & suggestions) | — | N/A — hide |
| SYS.NOT.7 | (extra) Popup position, low-priority popups | `[Notifications] PopupPosition {CloseToWidget,TopLeft,…,BottomRight}`, `LowPriorityPopups`, `LowPriorityHistory` | SRC |

### 1.4 Focus
| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.FOC.1 | Start focus session (duration) | app-side timer that sets DND `Until = now + N min` | PARTIAL · SRC (key) |
| SYS.FOC.2 | Show the timer in the Clock app; Show badges on taskbar apps; Show flashing on taskbar apps | badges: `plasmanotifyrc [Badges] InTaskManager` while session runs; others — | PARTIAL / N/A — hide |
| SYS.FOC.3 | Turn on do not disturb | = SYS.NOT.2 | SRC |

### 1.5 Power & battery
Profiles = `AC`, `Battery`, `LowBattery` groups in `powerdevilrc` (SRC `powerdevil/kcm/PowerKCM.cpp:66-68`,
`PowerDevilProfileSettings.kcfg` `parentGroupName="$(ProfileId)"`). After writing: `org.kde.Solid.PowerManagement
/org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.refreshStatus` (what the KCM calls, `PowerKCM.cpp:251`).
Action values (`powerdevil/daemon/powerdevilenums.h`): `NoAction 0, Sleep 1, Hibernate 2, Shutdown 8, PromptLogoutDialog 16,
LockScreen 32, TurnOffScreen 64, ToggleScreenOnOff 128`. Defaults (desktop): screen off AC 600 s / Battery 300 s / LowBattery 120 s;
sleep AC 900 / Battery 600 / LowBattery 300 (`powerdevilsettingsdefaults.cpp`). Hide the Battery parts when no `/sys/class/power_supply/BAT*`.

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.PWR.1 | Battery level + "Estimated time remaining" | `/sys/class/power_supply/BAT*/capacity,status` (APP); remaining: `org.kde.Solid.PowerManagement.batteryRemainingTime` | APP · SRC |
| SYS.PWR.2 | Battery levels chart (24 h / 7 days) | `org.freedesktop.UPower` device `GetHistory` (or `upower -i`) | UNVERIFIED (method from UPower docs, not checked) |
| SYS.PWR.3 | Energy recommendations (›) | — | N/A — hide |
| SYS.PWR.4 | Screen, sleep & hibernate timeouts › Turn my screen off after (plugged in / on battery) | `powerdevilrc [AC\|Battery/Display] TurnOffDisplayWhenIdle (Bool), TurnOffDisplayIdleTimeoutSec (Int)` | APP · SRC |
| SYS.PWR.4a | › Make my device sleep after | `[AC\|Battery/SuspendAndShutdown] AutoSuspendAction (0/1), AutoSuspendIdleTimeoutSec` | APP · SRC |
| SYS.PWR.4b | › Make my device hibernate after | Plasma has ONE idle action: `AutoSuspendAction=2` (Hibernate) or `SleepMode=3` (SuspendThenHibernate; delay from systemd `HibernateDelaySec` ⚠root) | PARTIAL · SRC |
| SYS.PWR.5 | Power mode (plugged in / on battery) | live: `powerprofilesctl get/set/list` (APP); per profile: `powerdevilrc [AC\|Battery\|LowBattery/Performance] PowerProfile` (`power-saver`/`balanced`/`performance`) | APP · SRC |
| SYS.PWR.6 | Energy saver: Always use energy saver | `powerprofilesctl set power-saver` | APP |
| SYS.PWR.6a | Energy saver: Turn energy saver on automatically at N % | `powerdevilrc [BatteryManagement] BatteryLowLevel (Int, default 10)` + `[LowBattery/Performance] PowerProfile=power-saver` | SRC `PowerDevilGlobalSettings.kcfg` |
| SYS.PWR.6b | Lower screen brightness when using energy saver | `[LowBattery/Display] UseProfileSpecificDisplayBrightness=true, DisplayBrightness (Int %)` | SRC |
| SYS.PWR.7 | Battery usage (per app) | — | N/A — hide |
| SYS.PWR.8 | Lid & power button controls › Pressing the power button will make my PC | `[AC\|Battery/SuspendAndShutdown] PowerButtonAction` (enum above) | SRC |
| SYS.PWR.8a | › Closing the lid will make my PC | `LidAction`; (extra) `InhibitLidActionWhenExternalMonitorPresent` | SRC |
| SYS.PWR.8b | › Pressing the sleep button | — | N/A — hide |
| SYS.PWR.9 | (extra, Win "Battery" smart charging) Charge limit | read `org.kde.Solid.PowerManagement.chargeStartThreshold/chargeStopThreshold`; writing needs powerdevil's polkit helper | PARTIAL · SRC (read) · write UNVERIFIED |
| SYS.PWR.10 | (extra) Critical battery action / level | `[BatteryManagement] BatteryCriticalAction, BatteryCriticalLevel` | SRC |

### 1.6 Storage
| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.STO.1 | Local disk usage bar + categories (Apps, Temporary files, Documents, Pictures, Other…) | `shutil.disk_usage` (APP); categories = async `du -s` of XDG dirs (`xdg-user-dir`), `~/.cache`, Trash, `/var/lib/flatpak` | APP (total) · categories PARTIAL |
| SYS.STO.2 | › Temporary files (Recycle Bin, thumbnails, temp files…) + Remove files | Trash: `ktrash6 --empty` (SRC `kio/src/kioworkers/trash/ktrash.cpp`); thumbnails `~/.cache/thumbnails`; cache `~/.cache` | SRC (ktrash6) · paths are XDG spec |
| SYS.STO.3 | Storage Sense (toggle + › schedules) | — (closest: low-space warning) | N/A — disabled |
| SYS.STO.3a | (extra) Warn when free space is low | `freespacenotifierrc [General] enableNotification, minimumSpace (MiB), minimumSpacePercentage` | SRC `plasma-workspace/freespacenotifier/freespacenotifier.kcfg` |
| SYS.STO.4 | Cleanup recommendations | — | N/A — hide |
| SYS.STO.5 | Advanced storage settings › Storage used on other drives / Disks & volumes | read-only list: `lsblk -J -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,TYPE` + `shutil.disk_usage` per mount | CLI (`lsblk -J`) |
| SYS.STO.5a | › Disks & volumes › Properties: change label, format, drive letter | — (destructive; leave to KDE Partition Manager) | N/A — hide |
| SYS.STO.5b | › Where new content is saved | XDG user dirs: `xdg-user-dirs-update --set DOCUMENTS|MUSIC|PICTURES|VIDEOS|DOWNLOAD <path>` (what `plasma-desktop/kcms/desktoppaths` edits) | CLI (`--help`) |
| SYS.STO.5c | › Storage Spaces, Drive optimization, Backup options | — | N/A — hide |
| SYS.STO.6 | (extra) Removable drives: mount on plug-in / at login | `kded_device_automounterrc [General] AutomountEnabled, AutomountOnPlugin, AutomountOnLogin, AutomountUnknownDevices` | SRC `plasma-desktop/solid-device-automounter/lib/AutomounterSettingsBase.kcfg` (also used by B&D › AutoPlay) |

### 1.7 Nearby sharing  → KDE Connect + Bluetooth file receive
| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.NBS.1 | Nearby sharing: Off / My devices only / Everyone nearby | no tri-state; KDE Connect is pair-based | PARTIAL → show paired devices instead |
| SYS.NBS.2 | Save files I receive to | Bluetooth: `bluedevilreceiverrc [General] saveUrl (Url)`; KDE Connect per-device share path UNVERIFIED | SRC `bluedevil/src/settings/filereceiver.kcfg` |
| SYS.NBS.3 | Rename your device | `kdeconnect-cli --name` only *selects* a device by name; no verified way to rename this PC | N/A — disabled (`kdeconnect-cli.cpp:28,97`) |
| SYS.NBS.4 | (extra) Accept files automatically | `bluedevilreceiverrc [General] autoAccept (Int)` | SRC |

### 1.8 Multitasking
| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.MT.1 | Snap windows (master toggle) | `kwinrc [Windows] ElectricBorderMaximize` + `ElectricBorderTiling` (both Bool) | SRC `kwin/src/kwin.kcfg` (key names) |
| SYS.MT.1a | › Show snap layouts when I hover over maximize / drag to top | — (KWin custom tiling is Meta+T, no hover flyout) | N/A — disabled |
| SYS.MT.1b | › Show my snapped windows when I hover over taskbar apps; suggest what to snap next; automatically size to fill | — | N/A — hide |
| SYS.MT.1c | › When I drag a window, let me snap it without dragging all the way to the screen edge | `kwinrc [Windows] BorderSnapZone / WindowSnapZone (Int px)` are window *magnetism*, not edge snapping | N/A — hide |
| SYS.MT.2 | Title bar window shake | — | N/A — hide |
| SYS.MT.3 | Desktops › On the taskbar, show all open windows: On all desktops / Only on the desktop I'm using | Task Manager applet `showOnlyCurrentDesktop` (Bool) via evaluateScript | SRC `plasma-desktop/applets/taskmanager/main.xml` |
| SYS.MT.3a | › Show all open windows when I press Alt+Tab: On all desktops / Only on the desktop I'm using | `kwinrc [TabBox] DesktopMode` (0 = all desktops, 1 = current) | SRC `kwin/src/kcms/tabbox/kwintabboxsettings.kcfg`, enum `kwin/src/tabbox/tabboxconfig.h:47` |
| SYS.MT.4 | Alt + Tab: Show tabs from apps (Edge tabs) | — | N/A — hide |
| SYS.MT.5 | (Task view) virtual desktops add/remove/rename | `org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager`: props `count, current (rw), rows (rw), desktops a(iss)`, methods `createDesktop, removeDesktop, setDesktopName` | SRC `kwin/src/org.kde.KWin.VirtualDesktopManager.xml` |

### 1.9 For developers
| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.DEV.1 | Developer Mode, Device portal, Device discovery, Dev Drive, Sudo, End task | — | N/A — hide |
| SYS.DEV.2 | Terminal: choose the default terminal app | `kdeglobals [General] TerminalApplication (konsole), TerminalService (org.kde.konsole.desktop)` | SRC `plasma-workspace/kcms/componentchooser/terminal_settings.kcfg` |
| SYS.DEV.3 | File Explorer: show file extensions, hidden files, full path in title bar, empty drives | Dolphin settings (`dolphinrc`) | UNVERIFIED (dolphin not checked) |
| SYS.DEV.4 | Remote Desktop / PowerShell rows | Remote Desktop → link to SYS.RDP; PowerShell — | link / N/A — hide |

### 1.10 Remote Desktop  → KRdp
| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.RDP.1 | Remote Desktop (toggle) | systemd user unit `app-org.kde.krdpserver.service`: enable+start / disable+stop (`systemctl --user enable --now …`) + `krdpserverrc [General] Autostart (Bool)` | SRC `krdp/src/kcm/kcmkrdpserver.cpp:250`, `krdp/server/krdpserversettings.kcfg` |
| SYS.RDP.2 | Require devices to use Network Level Authentication | — | N/A — disabled |
| SYS.RDP.3 | Remote Desktop port | `krdpserverrc [General] ListenPort (Int, 3389)` | SRC |
| SYS.RDP.4 | Remote Desktop users | `krdpserverrc [General] Users (StringList)`, `SystemUserEnabled (Bool)`; per-user passwords stored by KRdp in the secret store | SRC (keys) · password storage UNVERIFIED |
| SYS.RDP.5 | (extra) Video quality | `krdpserverrc [General] Quality (Int, 75)` | SRC |

### 1.11 Clipboard  → Klipper
| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.CLP.1 | Clipboard history | `klipperrc [General] KeepClipboardContents (Bool)`, history size `MaxClipItems (Int, 20)` (off ≈ 1) | PARTIAL · SRC `plasma-workspace/klipper/klipper.kcfg` |
| SYS.CLP.2 | Sync across your devices | KDE Connect clipboard plugin | N/A — disabled (no verified switch) |
| SYS.CLP.3 | Suggested actions | `klipperrc [General] URLGrabberEnabled (Bool)` | SRC |
| SYS.CLP.4 | Clear clipboard data | `org.kde.klipper /klipper org.kde.klipper.klipper.clearClipboardHistory` | SRC `plasma-workspace/klipper/klipper.h:42`, `klipper.cpp:62-63` |

### 1.12 Optional features
| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.OPT.1 | Add an optional feature / installed features / history | distro packages → Apps › Installed apps / System updates | N/A — hide page |

### 1.13 About
| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| SYS.ABT.1 | Device specifications: Device name, Processor, Installed RAM, System type | (APP) | APP |
| SYS.ABT.1a | Device ID | `/etc/machine-id` | PARTIAL (file is standard systemd) |
| SYS.ABT.1b | Product ID | — | N/A — hide |
| SYS.ABT.1c | Pen and touch | `InputDeviceManager.ListTouch` non-empty → "Touch support"; tablet tools via device props `tabletTool` | SRC |
| SYS.ABT.1d | (Win 24H2) Graphics card, Storage size | GPU: `org.kde.KWin /KWin org.kde.KWin.supportInformation` text; storage = SYS.STO.1 | SRC (method) · parsing UNVERIFIED |
| SYS.ABT.2 | Copy | `copyText` | APP |
| SYS.ABT.3 | Rename this PC | `pkexec hostnamectl set-hostname` ⚠root | APP |
| SYS.ABT.4 | Related links: Domain or workgroup, System protection, Advanced system settings | — | N/A — hide |
| SYS.ABT.5 | Windows specifications: Edition, Version, Installed on, OS build | os-release, `plasmashell --version`, kernel (APP); Installed on: — | APP · "Installed on" N/A — hide |
| SYS.ABT.6 | Related: Product key and activation, Device Manager, BitLocker | — | N/A — hide |

## 2. Bluetooth & devices  · owner: `backend/bluetooth.py`, `qml/pages/bluetooth/`, `qml/data/bluetooth.js`

Page order (24H2): Bluetooth row + Add device · Devices (›) · Printers & scanners · Mobile devices · Cameras · Mouse ·
Touchpad · Pen & Windows Ink · AutoPlay · USB. bluetoothctl commands verified in SRC `bluez/client/main.c`:
`power, pairable, discoverable, discoverable-timeout, scan, pair, cancel-pairing, trust, untrust, block, unblock,
remove, connect, disconnect, devices, info, system-alias`.

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| BT.1 | Bluetooth (toggle) | `bluetoothctl power on/off` | APP |
| BT.1a | (extra) Bluetooth state at login: Remember / On / Off | `bluedevilglobalrc [General] launchState {Remember,Enable,Disable}` | SRC `bluedevil/src/settings/bluedevilglobalsettings.kcfg` |
| BT.2 | Add device → dialog: Bluetooth / Wireless display or dock / Everything else | Bluetooth: `bluetoothctl scan on` (async, long timeout) → `pair <mac>` → `trust <mac>` → `connect <mac>`; others — | SRC (commands) · wireless display N/A — hide |
| BT.3 | Device cards (connected/paired, battery %) + ⋯ Connect/Disconnect/Remove | `bluetoothctl devices Paired|Connected`, `connect`, `disconnect`, `remove` (APP); `bluetoothctl info <mac>` prints `Icon:` and `Battery Percentage: 0x.. (N)` | APP · SRC `bluez/client/main.c:2041-2067` |
| BT.4 | Devices (›) page: Mouse, keyboard & pen / Audio / Other devices groups | group by `bluetoothctl info` `Icon:` value (input-mouse, audio-headset…, list in `bluez/src/dbus-common.c:60-175`) | SRC |
| BT.4a | › Device settings: Show notifications to connect using Swift Pair; Download over metered connections | — | N/A — hide |
| BT.4b | › Bluetooth devices discovery (Default / Advanced) | — | N/A — hide |
| BT.4c | › (extra) Make this PC discoverable | `bluetoothctl discoverable on/off` | SRC |
| BT.4d | › Send or receive files via Bluetooth | receive: SYS.NBS.2/4; send: `bluedevil-sendfile` | SRC (receiver keys) · sender binary UNVERIFIED |
| **Printers & scanners** ||||
| BT.PRN.1 | Printer list + Add device | `lpstat -p -d` (list, default); discovery `lpinfo -v` ⚠root; add `lpadmin -p NAME -E -v URI -m everywhere` ⚠root | CLI (`lpstat`, `lpadmin`) · `lpinfo` UNVERIFIED |
| BT.PRN.2 | Printer preferences: Let Windows manage my default printer; Download drivers over metered connections | — | N/A — hide |
| BT.PRN.3 | per-printer page: Set as default | `lpadmin -d NAME` | CLI |
| BT.PRN.3a | › Open print queue | native list: `lpstat -o NAME`; cancel `cancel <job>` | CLI (`lpstat`) · `cancel` UNVERIFIED |
| BT.PRN.3b | › Print test page | `lp -d NAME <CUPS datadir>/data/testprint` (`CUPS_DATADIR` overrides the datadir) | SRC `print-manager/src/libkcups/KCupsRequest.cpp:373-377` · CLI |
| BT.PRN.3c | › Printer properties / Printing preferences / Hardware properties | `configure-printer NAME` (print-manager binary) | SRC `print-manager` CMake target · this is a hand-off window |
| BT.PRN.3d | › Remove | `lpadmin -x NAME` ⚠root | CLI |
| BT.PRN.4 | Scanners | `scanimage -L` (SANE) | UNVERIFIED |
| **Mobile devices** (KDE Connect) ||||
| BT.MOB.1 | Allow this PC to access your mobile devices; Manage devices | `kdeconnect-cli --list-devices / --list-available / --refresh / --pair / --unpair -d <id>` | SRC `kdeconnect-kde/cli/kdeconnect-cli.cpp` (option names) |
| BT.MOB.1a | (extra) Ring / Ping / Send file | `--ring`, `--ping`, `--share <path>` | SRC |
| BT.MOB.2 | Phone Link | — | N/A — hide |
| **Cameras** ||||
| BT.CAM.1 | Connected cameras list | `/sys/class/video4linux/*/name` | UNVERIFIED (sysfs path is kernel ABI, not checked on target) |
| BT.CAM.2 | Camera page: Brightness, Contrast, Rotation, HDR, Eye contact | `v4l2-ctl --set-ctrl` | UNVERIFIED (v4l-utils not checked) |
| BT.CAM.3 | Add a network camera; Blocked cameras; Troubleshoot | — | N/A — hide |
| **Mouse** (props on `org.kde.KWin.InputDevice`, devices where `pointer && !touchpad`) ||||
| BT.MSE.1 | Primary mouse button (Left/Right) | `leftHanded` (rw; `supportsLeftHanded`) | SRC `kwin/src/backends/libinput/device.h` |
| BT.MSE.2 | Mouse pointer speed (1–20) | `pointerAcceleration` (rw, −1.0…1.0) | SRC |
| BT.MSE.3 | Enhance pointer precision | `pointerAccelerationProfileAdaptive` true / `pointerAccelerationProfileFlat` true | SRC |
| BT.MSE.4 | Scrolling: Roll the mouse wheel to scroll (Multiple lines / One screen) | — | N/A — hide |
| BT.MSE.5 | Lines to scroll at a time | `scrollFactor` (rw, qreal multiplier) | PARTIAL · SRC |
| BT.MSE.6 | Scroll inactive windows when hovering over them | `kwinrc [MouseBindings] CommandWindowWheel {Scroll, ActivateScroll, ActivateRaiseAndScroll}`: on = Scroll | SRC `kwin/src/kcms/options/kwinoptions_settings.kcfg` |
| BT.MSE.7 | Scrolling direction (Down motion scrolls down/up) | `naturalScroll` (rw) | SRC |
| BT.MSE.8 | Related: Additional mouse settings (double-click speed) | `kdeglobals [KDE] DoubleClickInterval (Int ms, 400)` | SRC `plasma-desktop/kcms/workspaceoptions/workspaceoptions_kdeglobalssettings.kcfg` |
| BT.MSE.9 | Related: Mouse pointer → Accessibility › Mouse pointer and touch | link | — |
| **Touchpad** (devices where `touchpad`) ||||
| BT.TPD.1 | Touchpad (toggle) | `enabled` (rw) | SRC |
| BT.TPD.1a | Leave touchpad on when a mouse is connected | inverse of `disableEventsOnExternalMouse` (if `supportsDisableEventsOnExternalMouse`) | SRC |
| BT.TPD.2 | Cursor speed | `pointerAcceleration` | SRC |
| BT.TPD.3 | Taps › Touchpad sensitivity | closest: `disableWhileTyping` | PARTIAL · SRC |
| BT.TPD.3a | › Tap with a single finger to single-click | `tapToClick` | SRC |
| BT.TPD.3b | › Tap with two fingers to right-click | default libinput 2-finger = right; `lmrTapButtonMap` false keeps it | SRC (prop) · PARTIAL |
| BT.TPD.3c | › Tap twice and drag to multi-select | `tapAndDrag` (+ `tapDragLock`) | SRC |
| BT.TPD.3d | › Press the lower right corner of the touchpad to right-click | `clickMethodAreas` (vs `clickMethodClickfinger`) | SRC |
| BT.TPD.4 | Scroll & zoom › Drag two fingers to scroll | `scrollTwoFinger` (vs `scrollEdge`) | SRC |
| BT.TPD.4a | › Scrolling direction | `naturalScroll` | SRC |
| BT.TPD.4b | › Pinch to zoom | — (app-level gesture) | N/A — hide |
| BT.TPD.5 | Three-finger / Four-finger gestures (swipes, taps) | KWin gestures are fixed in 6.7 | N/A — disabled |
| BT.TPD.6 | Advanced gestures (›) | — | N/A — hide |
| BT.TPD.7 | Reset (touchpad settings and gestures to default) | write each `*EnabledByDefault` / `default*` value back | SRC |
| **Pen & Windows Ink** (drawing tablets: devices where `tabletTool` or `tabletPad`) ||||
| BT.PEN.1 | Choose which hand you write with | `leftHanded` | SRC |
| BT.PEN.2 | (extra, Win "Pen ‹display›") Map pen to display / area | `outputName` (rw), `outputArea` (rw), `mapToWorkspace` (rw), `rotation` (rw) | SRC |
| BT.PEN.3 | Pen pressure (Win 24H2 has none; Plasma extra) | `pressureCurve` (rw), `pressureRangeMin/Max` (rw) | SRC |
| BT.PEN.4 | Show visual effects; Show cursor; Pen shortcuts (tail button); Handwriting | — | N/A — hide |
| **AutoPlay** ||||
| BT.AP.1 | Use AutoPlay for all media and devices | automount on plug-in: `kded_device_automounterrc [General] AutomountEnabled + AutomountOnPlugin` | PARTIAL · SRC |
| BT.AP.2 | Choose AutoPlay defaults: Removable drive / Memory card | — | N/A — hide |
| **USB** ||||
| BT.USB.1 | Connection notifications; USB battery saver; Show a notification if this PC is charging slowly | — | N/A — hide |
| BT.USB.2 | USB4 hubs and devices (Thunderbolt) | `org.freedesktop.bolt` (`boltctl`) device list / authorize | SRC `plasma-thunderbolt/src/interfaces/org.freedesktop.bolt1.*.xml` (only when bolt is running) |
| **Linux extras on this page** ||||
| BT.X.1 | Keyboard: repeat delay / rate, NumLock at startup | `kcminputrc [Keyboard] RepeatDelay (Int 600), RepeatRate (Double 25), KeyRepeat (repeat|nothing|accent), NumLock (0 on / 1 off / 2 unchanged)` → built under Time & language › Typing › Advanced keyboard settings | SRC `keyboardmiscsettings.kcfg`, `keyboard_hardware.cpp:28-31` |
| BT.X.2 | Game controllers | → Gaming (GAM.X.1) | — |

## 3. Network & internet  · owner: `backend/network.py`, `qml/pages/network/`, `qml/data/network.js`

Page order: status hero (connected network + Properties + Data usage) · Wi-Fi · Ethernet · VPN · Mobile hotspot ·
Airplane mode · Proxy · Dial-up · Advanced network settings. All `nmcli` below: CLI (help text) and NM setting
names SRC `NetworkManager/src/libnm-core-public/nm-setting-*.h` (`connection.autoconnect`, `connection.metered`,
`ipv4|ipv6.method/addresses/gateway/dns/ignore-auto-dns`, `802-11-wireless.ssid/band/hidden/cloned-mac-address/mac-address-randomization`,
`802-11-wireless-security.key-mgmt/psk`, `802-3-ethernet.cloned-mac-address`, `proxy.method/pac-url/browser-only`).
Writes to system connections may prompt polkit (⚠root) → always `_async`.

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| NET.1 | Hero: connected network, Properties, Data usage | `nmcli -t -f TYPE,STATE,CONNECTION device` (APP); details `nmcli -t connection show <id>` / `device show <if>` | APP · CLI |
| NET.1a | Data usage (per adapter, per app) | — | N/A — disabled |
| **Wi-Fi** ||||
| NET.WIFI.1 | Wi-Fi toggle | `nmcli radio wifi on/off` | APP |
| NET.WIFI.2 | Show available networks (connect / disconnect / password) | `nmcli device wifi list/connect`, `device disconnect` | APP |
| NET.WIFI.3 | Hardware properties (SSID, protocol, security, band, channel, IPv4/6, DNS, MAC, manufacturer, driver) | `nmcli -t device show <if>` + `nmcli -t -f all device wifi list ifname <if>` | CLI (field names UNVERIFIED) |
| NET.WIFI.4 | Manage known networks (›) list + Forget | `nmcli -t -f NAME,TYPE connection show` (APP), `connection delete id` (APP) | APP |
| NET.WIFI.4a | › network page: Connect automatically when in range | `nmcli connection modify <id> connection.autoconnect yes/no` | CLI · SRC |
| NET.WIFI.4b | › Metered connection | `connection.metered yes/no/unknown` | CLI · SRC |
| NET.WIFI.4c | › Set a data limit | — | N/A — hide |
| NET.WIFI.4d | › Random hardware addresses (Off / On / Change daily) | `802-11-wireless.cloned-mac-address permanent / random / stable` | PARTIAL · SRC |
| NET.WIFI.4e | › IP assignment: Edit (Automatic DHCP / Manual) | `ipv4.method auto|manual`, `ipv4.addresses a.b.c.d/nn`, `ipv4.gateway`; same for ipv6 | CLI · SRC |
| NET.WIFI.4f | › DNS server assignment: Edit (incl. DNS over HTTPS) | `ipv4.dns "x y"`, `ipv4.ignore-auto-dns yes`; DoH — | CLI · SRC · DoH N/A |
| NET.WIFI.4g | › View Wi-Fi security key | `nmcli device wifi show-password` | CLI |
| NET.WIFI.5 | Random hardware addresses (global toggle) | NetworkManager.conf ⚠root | N/A — disabled |
| NET.WIFI.6 | Wi-Fi Services | — | N/A — hide |
| **Ethernet** ||||
| NET.ETH.1 | Ethernet page: Authentication (802.1X) | — | N/A — disabled |
| NET.ETH.2 | Metered, IP assignment, DNS, Properties | same `nmcli connection modify` keys as NET.WIFI.4b/e/f | CLI · SRC |
| **VPN** ||||
| NET.VPN.1 | VPN connections list + Connect / Disconnect / Remove | `nmcli connection show` (TYPE `vpn` / `wireguard`), `connection up/down/delete id` | CLI |
| NET.VPN.2 | Add VPN | import a file: `nmcli connection import type openvpn|wireguard file <f>` | CLI (`import`; openvpn needs the NM plugin installed) |
| NET.VPN.3 | Advanced: Allow VPN over metered networks / while roaming | — | N/A — hide |
| **Mobile hotspot** ||||
| NET.HOT.1 | Mobile hotspot (toggle) | `nmcli device wifi hotspot [ifname IF] [con-name N] [ssid S] [password P]`; off: `nmcli connection down <con-name>` | CLI |
| NET.HOT.2 | Share my internet connection from / Share over Wi-Fi or Bluetooth | — (NM shares the default route over Wi-Fi only) | N/A — hide |
| NET.HOT.3 | Properties: Edit name, password, band | `802-11-wireless.ssid`, `802-11-wireless-security.psk`, `802-11-wireless.band a|bg` on the hotspot connection | CLI · SRC |
| NET.HOT.4 | Power saving | — | N/A — hide |
| **Airplane mode** ||||
| NET.AIR.1 | Airplane mode (toggle) | what plasma-nm does: remember Wi-Fi/WWAN state, then `nmcli radio wifi off`, `nmcli radio wwan off`, Bluetooth power off; reverse restores | SRC `plasma-nm/libs/handler.cpp:521-537` · CLI |
| NET.AIR.2 | Wireless devices: Wi-Fi, Bluetooth toggles | `nmcli radio wifi`, `bluetoothctl power` | APP |
| NET.AIR.3 | Airplane state shared with the Plasma network applet | `plasma-nm [General] AirplaneModeEnabled (Bool)`; hotspot name/password `HotspotName`, `HotspotPassword` | SRC `plasma-nm/libs/editor/configuration.cpp:90-150` |
| **Proxy** (two layers: KDE apps read `kioslaverc`; NM-aware apps read the connection's `proxy.*`) ||||
| NET.PRX.1 | Automatic: Automatically detect settings | `kioslaverc [Proxy Settings] ProxyType=3` (WPAD) | SRC `kio-extras/kcms/proxy/kioslave.kcfg`, enum `proxy.h:34` (NoProxy 0, Manual 1, PAC 2, WPAD 3, EnvVar 4) |
| NET.PRX.2 | Use setup script: Script address | `ProxyType=2`, `Proxy Config Script (String)`; NM: `proxy.method auto`, `proxy.pac-url` | SRC |
| NET.PRX.3 | Manual: Use a proxy server: address, port | `ProxyType=1`, `httpProxy`, `httpsProxy`, `ftpProxy` as `"host port"` (space separated); running KIO workers reload on signal `/KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration(s)` | SRC `kio-extras/kcms/proxy/ui/main.qml:347`, `kio ksaveioconfig.cpp` |
| NET.PRX.4 | Exceptions; Don't use proxy for local addresses | `NoProxyFor (String, comma separated)`. `ReversedException (Bool)` means "use the proxy ONLY for the exceptions" (not "skip local addresses"); no local-address switch | SRC · "local addresses" N/A |
| **Dial-up** ||||
| NET.DUP.1 | Dial-up | — | N/A — hide |
| **Advanced network settings** ||||
| NET.ADV.1 | Network adapters list (expand: Disable / Edit more adapter options) | `nmcli device` (APP); Disable: `nmcli device disconnect <if>`, Enable: `nmcli device connect <if>`; rename — | CLI · rename N/A |
| NET.ADV.2 | Hardware & connection properties | `nmcli device show` (all) | CLI |
| NET.ADV.3 | Data usage | — | N/A — disabled |
| NET.ADV.4 | Advanced sharing settings (Network discovery, File & printer sharing, Public folder sharing, Password protected sharing) | — (Samba usershares, `kdenetwork-filesharing`) | N/A — disabled |
| NET.ADV.5 | Network reset | `nmcli networking off` → `on` (restarts all connections, not a real reset) | PARTIAL · CLI |
| NET.ADV.6 | Related: More network adapter options, Windows Firewall | Firewall → Privacy & security › PRV.SEC.2 | link |

## 4. Personalization  · owner: `backend/personalization.py`, `qml/pages/personalization/`, `qml/data/personalization.js`

Page order: preview + "Select a theme to apply" · Background · Colors · Themes · Dynamic Lighting · Lock screen ·
Text input · Start · Taskbar · Device usage · Fonts. Hide: Device usage. Plasma-only pages (Plasma style, Window
decorations, Icons, Cursors, Splash) go under **Themes › Related settings** so the top level stays 1:1.

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| PER.0 | Select a theme to apply (thumbnails) | Global themes: `plasma-apply-lookandfeel --list` / `--apply <id>` | SRC `plasma-workspace/kcms/lookandfeel/tool/lnftool.cpp` |
| **Background** (desktop containments; layout `[Containments][N][Wallpaper][<plugin>][General]` in `plasma-org.kde.plasma.desktop-appletsrc`) ||||
| PER.BG.1 | Personalize your background: Picture / Solid color / Slideshow / Windows spotlight | evaluateScript: `d.wallpaperPlugin = 'org.kde.image' \| 'org.kde.color' \| 'org.kde.slideshow' \| 'org.kde.potd'` | SRC (`wallpaperPlugin` in `shell/scripting/containment.h`; plugin ids from wallpaper packages) |
| PER.BG.2 | Picture: Recent images, Browse photos | `plasma-apply-wallpaperimage <file>` (APP); thumbnails from `/usr/share/wallpapers`, `~/.local/share/wallpapers` (APP) | APP |
| PER.BG.3 | Choose a fit: Fill / Fit / Stretch / Tile / Center / Span | `plasma-apply-wallpaperimage --fill-mode preserveAspectCrop / preserveAspectFit / stretch / pad` (= FillMode 2/1/0/6); Tile = `writeConfig('FillMode', 3)`; Span — | SRC `plasma-workspace/wallpapers/image/plasma-apply-wallpaperimage.cpp:43-46` · Span N/A |
| PER.BG.4 | Solid color: color grid + custom | `org.kde.color` `[General] Color` | SRC `plasma-workspace/wallpapers/color/contents/config/main.xml` |
| PER.BG.5 | Slideshow: Choose an album, Change picture every, Shuffle | `org.kde.slideshow` `[General] SlidePaths (StringList), SlideInterval (Int s, 900), SlideshowMode (Int)` | SRC `wallpapers/image/slideshowpackage/contents/config/main.xml` (SlideshowMode value meanings UNVERIFIED) |
| PER.BG.5a | Let slideshow run even if I'm on battery power | — | N/A — hide |
| PER.BG.6 | Windows spotlight | Picture of the Day `org.kde.potd` `[General] Provider` | PARTIAL · SRC `kdeplasma-addons/wallpapers/potd/package/contents/config/main.xml` (kdeplasma-addons may be absent) |
| **Colors** ||||
| PER.COL.1 | Choose your mode: Light / Dark | `plasma-apply-colorscheme BreezeLight\|BreezeDark` | APP |
| PER.COL.2 | Custom: default Windows mode (shell) / default app mode | shell = Plasma style `plasma-apply-desktoptheme breeze-light\|breeze-dark`; apps = color scheme | SRC `kcms/desktoptheme/plasma-apply-desktoptheme.cpp` (theme ids UNVERIFIED on target) |
| PER.COL.3 | Transparency effects | `kwinrc [Plugins] blurEnabled, contrastEnabled` + reconfigure | APP |
| PER.COL.4 | Accent color: Manual / Automatic; Recent colors; Windows colors; View colors | `plasma-apply-colorscheme --accent-color #rrggbb` (APP); auto = `kdeglobals [General] accentColorFromWallpaper` (APP, SRC `kcms/colors/colorssettings.kcfg`) | APP · SRC |
| PER.COL.5 | Show accent color on Start and taskbar | — (Plasma style decides) | N/A — disabled |
| PER.COL.6 | Show accent color on title bars and window borders | `[General] TitlebarIsAccentColored=true` inside the **active .colors file**: requires writing a user copy of the scheme to `~/.local/share/color-schemes/` and applying it | PARTIAL · SRC (`colorsapplicator.cpp:155`) · approach UNVERIFIED |
| PER.COL.7 | (extra) Switch light/dark automatically at sunset | `kdeglobals [KDE] AutomaticLookAndFeel (Bool), DefaultLightLookAndFeel, DefaultDarkLookAndFeel` (schedule = SYS.DISP.6d) | SRC `kcms/lookandfeel/lookandfeelsettings.kcfg` |
| **Themes** ||||
| PER.THM.1 | Current theme: Background · Color · Sounds · Mouse cursor tiles | links to PER.BG / PER.COL / `kdeglobals [Sounds] Theme` / A11Y.MP | SRC |
| PER.THM.2 | Current theme list + Browse themes | `plasma-apply-lookandfeel --list/--apply`; Browse (KNewStuff) — | SRC · Browse N/A — disabled |
| PER.THM.3 | Related: Desktop icon settings | — | N/A — hide |
| PER.THM.4 | Related: Contrast themes | → A11Y.CT | link |
| PER.THM.5 | (Plasma) Plasma style | `plasma-apply-desktoptheme --list-themes` / `<name>`; current `plasmarc [Theme] name` | SRC |
| PER.THM.6 | (Plasma) Window decorations | `kwinrc [org.kde.kdecoration2] library (org.kde.breeze), theme, BorderSize (None…Oversized), BorderSizeAuto, ButtonsOnLeft, ButtonsOnRight` + reconfigure | SRC `kwindecorationsettings.kcfg`, `kwin/src/kcms/decoration/utils.cpp:13-21` |
| PER.THM.7 | (Plasma) Icons | `kdeglobals [Icons] Theme` | SRC `kcms/icons/iconssettingsbase.kcfg` (live-apply tool UNVERIFIED) |
| PER.THM.8 | (Plasma) Cursors | `plasma-apply-cursortheme <name> [--size N]`, `--list-themes`; stored `kcminputrc [Mouse] cursorTheme, cursorSize` | SRC `kcms/cursortheme/plasma-apply-cursortheme.cpp`, `cursorthemesettings.kcfg` |
| PER.THM.9 | (Plasma) Splash screen | `ksplashrc [KSplash] Theme, Engine` | SRC `plasma-desktop/kcms/ksplash/splashscreensettings.kcfg` |
| PER.THM.10 | (Plasma) Application style | `kdeglobals [KDE] widgetStyle (Breeze)` | SRC `kcms/style/stylesettings.kcfg` |
| **Dynamic Lighting** ||||
| PER.DL.1 | Dynamic Lighting (RGB devices) | — | N/A — disabled |
| **Lock screen** ||||
| PER.LCK.1 | Personalize your lock screen: Picture / Slideshow / Windows spotlight | `kscreenlockerrc [Greeter] WallpaperPlugin (org.kde.image)`; image at `[Greeter][Wallpaper][org.kde.image][General] Image` | SRC `kscreenlocker/settings/kscreenlockersettings.kcfg`, `wallpaper_integration.cpp:54`, image plugin `main.xml` |
| PER.LCK.2 | Get fun facts, tips, tricks… ; Lock screen status | — | N/A — hide |
| PER.LCK.3 | Show the lock screen background picture on the sign-in screen | SDDM theme background ⚠root | UNVERIFIED |
| PER.LCK.4 | Related: Screen timeout | `kscreenlockerrc [Daemon] Autolock (Bool), Timeout (minutes)` | SRC |
| PER.LCK.5 | Related: Screen saver | — | N/A — hide |
| **Text input** ||||
| PER.TXT.1 | Touch keyboard theme / size; Text cursor indicator | — | N/A — hide |
| PER.TXT.2 | Input language switcher (show on taskbar) | `plasmarc [OSD] kbdLayoutChangedEnabled (Bool)`; layout indicator widget | PARTIAL · SRC `workspaceoptions_plasmasettings.kcfg` |
| **Start** (Application Launcher = Kickoff applet `org.kde.plasma.kickoff`, via evaluateScript) ||||
| PER.STA.1 | Layout: More pins / Default / More recommendations | `compactMode`, `favoritesDisplay`, `applicationsDisplay` (0 grid / 1 list) | PARTIAL · SRC `plasma-desktop/applets/kickoff/main.xml` |
| PER.STA.2 | Show recently added apps | `highlightNewlyInstalledApps (Bool)` | PARTIAL · SRC |
| PER.STA.3 | Show most used apps | — | N/A — hide |
| PER.STA.4 | Show recommended files in Start, recent files in File Explorer, and items in Jump Lists | activity history: `kactivitymanagerd-pluginsrc [Plugin-org.kde.ActivityManager.Resources.Scoring] what-to-remember` (0 all / 2 none) | SRC (= PRV.ACT.1) |
| PER.STA.5 | Show recommendations for tips, shortcuts, new apps; Show account-related notifications | — | N/A — hide |
| PER.STA.6 | Folders (›): Settings, File Explorer, Documents, Downloads… next to power button | Kickoff `systemFavorites` holds power actions only | N/A — disabled |
| **Taskbar** (panel via evaluateScript `panels()`; Task Manager `org.kde.plasma.taskmanager` / `icontasks`; tray `org.kde.plasma.systemtray`) ||||
| PER.TB.1 | Taskbar items: Search / Task view / Widgets | presence of widgets in the panel | N/A — disabled (no 1:1 widget) |
| PER.TB.2 | System tray icons: Pen menu, Touch keyboard, Virtual touchpad | — | N/A — hide |
| PER.TB.3 | Other system tray icons (per-app On/Off, Hidden icon menu) | systemtray `[General] shownItems, hiddenItems (StringList), showAllItems (bool)` | SRC `plasma-workspace/applets/systemtray/main.xml` |
| PER.TB.4 | Taskbar behaviors › Taskbar alignment (Left / Center) | `panel.alignment = 'left'|'center'` (only visible when the panel isn't full-width) | PARTIAL · SRC (`panel.cpp:156`) |
| PER.TB.4a | › Automatically hide the taskbar | `panel.hiding = 'autohide' \| 'none'` (also `dodgewindows`, `windowsgobelow`) | SRC (`panel.cpp:312-330`) |
| PER.TB.4b | › Show badges on taskbar apps | `plasmanotifyrc [Badges] InTaskManager (Bool)` | SRC `libnotificationmanager/kcfg/badgesettings.kcfg` |
| PER.TB.4c | › Show flashing on taskbar apps | Task Manager `unhideOnAttention` is related, not the same | N/A — hide |
| PER.TB.4d | › Show my taskbar on all displays | — (panels are per screen) | N/A — disabled |
| PER.TB.4e | › When using multiple displays, show my taskbar apps on | Task Manager `showOnlyCurrentScreen (Bool)` | SRC `plasma-desktop/applets/taskmanager/main.xml` |
| PER.TB.4f | › Share any window from my taskbar | — | N/A — hide |
| PER.TB.4g | › Select the far corner of the taskbar to show the desktop | needs the "Peek at Desktop" widget | N/A — disabled |
| PER.TB.4h | › Combine taskbar buttons and hide labels: Always / When taskbar is full / Never | `groupingStrategy` (0 none, 1 by program) + `onlyGroupWhenFull (Bool)` | SRC |
| PER.TB.4i | › Show smaller taskbar buttons | `panel.height` | PARTIAL · SRC |
| **Fonts** ||||
| PER.FNT.1 | Add fonts (drag & drop / Browse) | `org.kde.fontinst` `install` (polkit for system) or copy to `~/.local/share/fonts` + `fc-cache` | SRC `plasma-workspace/kcms/kfontinst/dbus/org.kde.fontinst.xml` · CLI (`fc-cache`) |
| PER.FNT.2 | Available fonts: search, filter by language, list | `fc-list --format` | CLI (binary present; format string UNVERIFIED) |
| PER.FNT.3 | Font page: preview, faces, metadata, Uninstall | `fc-query <file>`; uninstall `org.kde.fontinst.uninstall` | SRC (method) · CLI |
| PER.FNT.4 | Related: Adjust ClearType text | `~/.config/fontconfig/fonts.conf` written by kcm_fonts; `kcmfonts [General] forceFontDPI (UInt)` | PARTIAL · SRC (`fontsaasettingsbase.kcfg`) · fontconfig details UNVERIFIED |
| PER.FNT.5 | Related: Download fonts for all languages | — | N/A — hide |

## 5. Apps  · owner: `backend/apps.py`, `qml/pages/apps/`, `qml/data/apps.js`

Page order: Installed apps · Advanced app settings · Default apps · Offline maps · Optional features (moved to System) ·
Apps for websites · Video playback · Startup. Hide: Offline maps, Apps for websites, Video playback.

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| APP.INS.1 | Installed apps: search, Sort by (name / date / size), Filter by drive, list (icon, name, version, publisher, date, size) | applications = `.desktop` files in XDG data dirs; Flatpak: `flatpak list --app --columns=…` (CLI); distro packages: PackageKit `pkcon get-packages --filter installed` | CLI · columns/size fields UNVERIFIED |
| APP.INS.2 | ⋯ Uninstall | Flatpak: `flatpak uninstall <id>`; package: `pkcon remove <pkg>` ⚠root | CLI |
| APP.INS.3 | ⋯ Modify; Move | — | N/A — hide |
| APP.INS.4 | ⋯ Advanced options (permissions, background apps, Terminate, Repair, Reset) | Flatpak permissions → PRV.APP; Terminate: — | PARTIAL |
| APP.ADV.1 | Advanced app settings: Choose where to get apps; Share across devices; Archive apps; App execution aliases | — | N/A — hide page |
| APP.DEF.1 | Default apps: Set defaults for applications (app list › per-app file types) | `xdg-mime query default <mime>`, `xdg-mime default <app>.desktop <mime>` (writes `mimeapps.list`) | CLI |
| APP.DEF.2 | Set a default for a file type or link type (search box) | same; common types = the list kcm_componentchooser manages: `x-scheme-handler/http(s)/mailto/tel/geo`, `inode/directory`, `application/pdf`, `text/calendar`, `image/*`, `audio/*`, `video/*` | SRC `plasma-workspace/kcms/componentchooser/` (mime list) · CLI |
| APP.DEF.3 | Related: Choose defaults by file type / by link type | same | CLI |
| APP.DEF.4 | (extra) Terminal emulator | = SYS.DEV.2 | SRC |
| APP.STA.1 | Startup: Sort by; apps with On/Off and impact | XDG autostart `~/.config/autostart/*.desktop` (+ system `/etc/xdg/autostart`); disabled = `Hidden=true` in the user copy | SRC `plasma-workspace/kcms/autostart/autostartmodel.cpp:57-59` |
| APP.STA.2 | Startup impact | — | N/A — hide |
| APP.STA.3 | (Plasma) login/logout scripts | `~/.config/plasma-workspace/env/`, `…/shutdown/` | SRC `autostartmodel.cpp:44-45,142-144` |

## 6. Accounts  · owner: `backend/accounts.py`, `qml/pages/accounts/`, `qml/data/accounts.js`

Page order: user header · Your info · Email & accounts · Sign-in options · Family · Windows backup · Other users ·
Access work or school · Passkey settings. Hide: Family, Windows backup, Access work or school, Passkey settings.
AccountsService (system bus `org.freedesktop.Accounts`, `/org/freedesktop/Accounts`, user objects
`/org/freedesktop/Accounts/User<uid>`): methods verified in SRC `plasma-workspace/kcms/users/src/org.freedesktop.Accounts*.xml`
(`ListCachedUsers, FindUserById, FindUserByName, CreateUser, DeleteUser`; User: `SetUserName, SetRealName, SetEmail,
SetIconFile, SetAccountType, SetPasswordMode, SetPassword, SetAutomaticLogin, SetLocked`). Writes are polkit-gated (⚠root for other users).

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| ACC.0 | Header: picture, name, email, account type | `userName`, `avatar` (APP); type via User `AccountType` property | APP · SRC |
| ACC.INF.1 | Your info: Adjust your photo › Choose a file / Take a photo | `User.SetIconFile <path>` | SRC · Take a photo N/A — hide |
| ACC.INF.2 | Account settings: Sign in with a Microsoft account instead | — | N/A — hide |
| ACC.INF.3 | (Win: name, via Control Panel) Change display name | `User.SetRealName` | SRC |
| ACC.EML.1 | Email & accounts: Add a Microsoft/work/other account; accounts list | KAccounts: its kded module `org.kde.Accounts` has no list/add API → justified hand-off `kcm_kaccounts` | SRC (kaccounts-integration) · hand-off |
| ACC.SGN.1 | Sign-in options: Facial recognition (Windows Hello) | — | N/A — disabled |
| ACC.SGN.2 | Fingerprint recognition: Set up / Remove | `fprintd-enroll`, `fprintd-list`, `fprintd-delete` (CLI) or `net.reactivated.Fprint` D-Bus | CLI · D-Bus UNVERIFIED |
| ACC.SGN.3 | PIN (Windows Hello); Security key; Picture password | — | N/A — disabled (PIN) / hide |
| ACC.SGN.4 | Password: Change | `User.SetPassword(crypted, hint)` with SHA-512 `$6$<salt>$` crypt (as kcm_users), via QtDBus with interactive polkit; no old-password argument | SRC `plasma-workspace/kcms/users/src/user.cpp:170,269-293` |
| ACC.SGN.5 | Additional settings: For improved security, only allow Windows Hello sign-in | — | N/A — hide |
| ACC.SGN.6 | If you've been away, when should Windows require you to sign in again? (Never / Every time / 1 / 3 / 5 / 15 min…) | `kscreenlockerrc [Daemon]`: Never = `RequirePassword=false`; otherwise `RequirePassword=true`, `LockOnResume=true`, `LockGrace` = seconds (0 = every time) | SRC `kscreenlockersettings.kcfg`, `kscreenlocker/kcm/ui/main.qml:120-150` |
| ACC.SGN.7 | Dynamic lock | — | N/A — hide |
| ACC.SGN.8 | Automatically save my restartable apps and restart them when I sign back in | `ksmserverrc [General] loginMode {restorePreviousLogout, restoreSavedSession, emptySession}` | SRC `plasma-desktop/kcms/ksmserver/smserversettings.kcfg` |
| ACC.SGN.9 | Show account details such as my email address on the sign-in screen; Use my sign-in info to finish setup after an update | — | N/A — hide |
| ACC.SGN.10 | (extra) Automatic login | SDDM `[Autologin]` config ⚠root | UNVERIFIED (sddm-kcm not checked) |
| ACC.OTH.1 | Other users: Add account | `Accounts.CreateUser(name, fullname, type)` | SRC |
| ACC.OTH.2 | per user: Change account type (Standard / Administrator) | `User.SetAccountType(0|1)` | SRC |
| ACC.OTH.3 | per user: Remove (Delete account and data) | `Accounts.DeleteUser(uid, removeFiles)` | SRC |
| ACC.OTH.4 | Set up a kiosk | — | N/A — hide |
| ACC.X.1 | (Plasma extra) Wallet: enable, close when idle | `kwalletrc [Wallet] Enabled, Close When Idle, Idle Timeout` | SRC `kwallet/src/kwalletsettings.kcfg` |

## 7. Time & language  · owner: `backend/time_language.py`, `qml/pages/time_language/`, `qml/data/time_language.js`

Page order: Date & time · Language & region · Typing · Speech. `timedatectl` subcommands (CLI): `show, set-time, set-timezone,
list-timezones, set-local-rtc, set-ntp, timesync-status, show-timesync, ntp-servers, revert`. Digital Clock applet
`org.kde.plasma.digitalclock` config via evaluateScript, group `Appearance` (SRC `plasma-workspace/applets/digital-clock/main.xml`).

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| TL.DT.1 | Current date/time header | `QDateTime` | — |
| TL.DT.2 | Set time automatically | `timedatectl set-ntp true/false` ⚠polkit | APP |
| TL.DT.3 | Set time zone automatically | kded module `geotimezoned`: `org.kde.kded6 /kded org.kde.kded6.setModuleAutoloading("geotimezoned", b)` + `loadModule` / `unloadModule`; read `isModuleAutoloaded` | SRC `kded/src/kded.h:43-104`, `plasma-workspace/geotimezoned/` (module calls timedated `SetTimezone`) |
| TL.DT.4 | Time zone | `timedatectl set-timezone`, `list-timezones` | APP |
| TL.DT.5 | Adjust for daylight saving time automatically | always on (tzdata) | N/A — hide |
| TL.DT.6 | Set the date and time manually: Change | `timedatectl set-time "YYYY-MM-DD HH:MM:SS"` (only when NTP off) ⚠polkit | CLI |
| TL.DT.7 | Additional settings: Sync now, Last successful time synchronization, Time server | last sync: `timedatectl show-timesync` / `timesync-status`; server: `timedatectl ntp-servers <link> <srv>` (per link); Sync now — | CLI · Sync now N/A — disabled |
| TL.DT.8 | Show time and date in the System tray | Digital Clock `showDate (Bool)` | SRC |
| TL.DT.9 | Show seconds in system tray clock | `showSeconds {Never, ToolTip, Always}` → Always / Never | SRC |
| TL.DT.10 | Show additional calendars in the taskbar | `enabledCalendarPlugins (StringList)` | PARTIAL · SRC |
| TL.DT.11 | (Win "Additional clocks") | `selectedTimeZones (StringList)` | SRC |
| TL.LR.1 | Windows display language | `plasma-localerc [Translations] LANGUAGE` (colon list) | SRC `plasma-workspace/kcms/region_language/regionandlangsettingsbase.kcfg` |
| TL.LR.2 | Preferred languages: list, Add a language, ⋯ move up/down/remove | same `LANGUAGE` list order; installing translations = distro packages | SRC · install N/A — disabled |
| TL.LR.2a | ⋯ Language options: language pack, handwriting, speech, Keyboards (Add a keyboard) | keyboards → TL.TYP.5 | link |
| TL.LR.3 | Country or region | `plasma-localerc [Formats] LC_ADDRESS, LC_TELEPHONE, LC_PAPER, LC_MEASUREMENT` | PARTIAL · SRC |
| TL.LR.4 | Regional format (+ › Change formats: calendar, first day of week, short/long date, short/long time) | `[Formats] LANG, LC_TIME, LC_NUMERIC, LC_MONETARY…`; individual date patterns are fixed by the locale (show read-only preview) | PARTIAL · SRC |
| TL.LR.4a | (needed after choosing a locale) generate locale | system bus `org.kde.localegenhelper /LocaleGenHelper org.kde.localegenhelper.LocaleGenHelper.enableLocales(as)` ⚠polkit | SRC `kcms/region_language/localegenhelper/` |
| TL.LR.5 | Related: Administrative language settings | `localectl set-locale` ⚠polkit | CLI |
| TL.TYP.1 | Typing: Show text suggestions, Multilingual suggestions, Typing insights | — | N/A — hide |
| TL.TYP.2 | Autocorrect misspelled words; Highlight misspelled words | Highlight = Sonnet `QSettings("KDE","Sonnet")` (`~/.config/KDE/Sonnet.conf`) key `backgroundCheckerEnabled`; Autocorrect: no system-wide key | SRC `sonnet/src/core/settingsimpl.cpp:230-250` · Autocorrect N/A — disabled |
| TL.TYP.3 | Touch keyboard (›) | KWin input method: `kwinrc [Wayland] InputMethod (Path to .desktop)`; on/off `org.kde.KWin /VirtualKeyboard org.kde.kwin.VirtualKeyboard` props `available, active (rw)` | SRC `kwin/src/kcms/virtualkeyboard/virtualkeyboardsettings.kcfg`, `kwin/src/virtualkeyboard_dbus.h:20-24` |
| TL.TYP.4 | Advanced keyboard settings › Override for default input method | first entry of `kxkbrc [Layout] LayoutList` | SRC |
| TL.TYP.4a | › Let me use a different input method for each app window | `kxkbrc [Layout] SwitchMode` (`Global` / `Desktop` / `WinClass` / `Window`) | SRC `plasma-desktop/kcms/keyboard/keyboard_config.cpp:15-20` |
| TL.TYP.4b | › Use the desktop language bar when it's available | = PER.TXT.2 | SRC |
| TL.TYP.4c | › Input language hot keys | `kxkbrc [Layout] Options` (xkb `grp:*` options) | SRC (key) · option ids from xkeyboard-config (`localectl list-x11-keymap-options` CLI) |
| TL.TYP.4d | › (extra) Key repeat delay/rate, NumLock | = BT.X.1 | SRC |
| TL.TYP.5 | Keyboards (Win: per language "Add a keyboard") | `kxkbrc [Layout] Use=true, LayoutList, VariantList, DisplayNames (StringList)`, `Model`; catalogue: `localectl list-x11-keymap-layouts / -variants <layout>`; apply = write with `--notify` (KWin watches `[Layout]`, `kwin/src/keyboard_layout.cpp:101`) | SRC · CLI |
| TL.TYP.6 | (extra) Emoji panel | `plasma-emojier` (Meta+.) | SRC `plasma-desktop/emojier/` |
| TL.SPC.1 | Speech: Speech language, Voices, Microphone | — | N/A — hide page |

## 8. Gaming  · owner: `backend/gaming.py`, `qml/pages/gaming/`, `qml/data/gaming.js`

Page order: Game Bar · Captures · Game Mode.

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| GAM.BAR.1 | Game Bar: Allow your controller to open Game Bar | — | N/A — disabled (page keeps the row) |
| GAM.CAP.1 | Captures location (screenshots / clips), Open folder | Spectacle: `spectaclerc [ImageSave] imageSaveLocation`, `[VideoSave] videoSaveLocation` | SRC `spectacle/src/Gui/SettingsDialog/spectacle.kcfg` |
| GAM.CAP.2 | Record what happened, Record audio, Record mouse cursor, Video frame rate/quality | — | N/A — hide |
| GAM.MODE.1 | Game Mode (toggle) | Feral GameMode is per game (`gamemoderun`), no global switch; can show status | N/A — disabled (status UNVERIFIED) |
| GAM.X.1 | (Linux extra) Game controllers: list + test | `/dev/input/js*` or SDL | UNVERIFIED |
| GAM.X.2 | (Linux extra) Use a game controller as a mouse | `kwinrc [Plugins] gamecontrollerEnabled (Bool)` | SRC `plasma-desktop/kcms/gamecontroller/gamecontrolleremulationsettings.kcfg` |
| GAM.X.3 | (Linux extra) Allow tearing in full-screen games | = SYS.DISP.14b | SRC |

## 9. Accessibility  · owner: `backend/accessibility.py`, `qml/pages/accessibility/`, `qml/data/accessibility.js`

Page order: **Vision**: Text size · Visual effects · Mouse pointer and touch · Text cursor · Magnifier · Color filters ·
Contrast themes · Narrator · **Hearing**: Audio · Captions · **Interaction**: Speech · Keyboard · Mouse · Eye control.
Hide: Text cursor, Captions, Speech, Eye control. KWin effects: enable with `kwinrc [Plugins] <id>Enabled` +
`org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect/unloadEffect/reconfigureEffect(<id>)` (SRC `kwin/src/org.kde.kwin.Effects.xml`).

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| A11Y.TS.1 | Text size slider + preview + Apply | scale the size field of `kdeglobals [General] font, menuFont, toolBarFont, smallestReadableFont, fixed` and `[WM] activeFont` | SRC `plasma-workspace/kcms/fonts/fontssettings.kcfg` (QFont string format UNVERIFIED) |
| A11Y.VE.1 | Always show scrollbars | — | N/A — hide |
| A11Y.VE.2 | Transparency effects | = PER.COL.3 | APP |
| A11Y.VE.3 | Animation effects | `kdeglobals [KDE] AnimationDurationFactor (Double)`: 0 = off, 1 = normal | SRC `kwin/src/kcms/animations/animationskdeglobalssettings.kcfg` |
| A11Y.VE.4 | Dismiss notifications after this amount of time | `plasmanotifyrc [Notifications] PopupTimeout (Int ms, 5000)` | SRC |
| A11Y.MP.1 | Mouse pointer style (white / black / inverted / custom) | cursor themes via `plasma-apply-cursortheme` (theme names on target UNVERIFIED) | PARTIAL · SRC |
| A11Y.MP.2 | Size | `plasma-apply-cursortheme <current> --size N` / `kcminputrc [Mouse] cursorSize (Int 24)` | SRC |
| A11Y.MP.3 | Touch indicator | KWin effect `touchpoints` | PARTIAL · SRC (plugin dir exists) |
| A11Y.MP.4 | (extra) Shake cursor to find it | `kwinrc [Plugins] shakecursorEnabled (Bool, true)`, `[Effect-shakecursor] Magnification` | SRC `plasma-desktop/kcms/access/kcmaccessibilityshakecursor.kcfg` |
| A11Y.MAG.1 | Magnifier (toggle: start magnifying) | effect `zoom` (`[Plugins] zoomEnabled`, default true); zoom in/out by invoking its shortcuts: `org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut(<name>)` | SRC (method, path) · shortcut names (`view_zoom_in`…) UNVERIFIED |
| A11Y.MAG.2 | Zoom increment | `kwinrc [Effect-zoom] ZoomFactor (Double, 1.2)` | SRC `kwin/src/plugins/zoom/zoom.kcfg` |
| A11Y.MAG.3 | Start Magnifier after sign-in / before sign-in | — | N/A — hide |
| A11Y.MAG.4 | Invert colors | effect `invert` (`[Plugins] invertEnabled`) | SRC |
| A11Y.MAG.5 | Smooth edges of images and text | `[Effect-zoom] UsePatternUpscaler (Bool)` | PARTIAL · SRC |
| A11Y.MAG.6 | View: Full screen / Lens | Full screen = `zoom`; Lens = effect `magnifier` (`[Plugins] magnifierEnabled`, `[Effect-magnifier] Width, Height`) | SRC |
| A11Y.MAG.7 | Have Magnifier follow: mouse pointer / keyboard focus / text cursor | `[Effect-zoom] MouseTracking (0 proportional, 1 centred, 2 push, 3 disabled)`, `EnableFocusTracking`, `EnableTextCaretTracking` | SRC (`zoom.h:79-82`) |
| A11Y.MAG.8 | Reading (Narrator reads) | — | N/A — hide |
| A11Y.CF.1 | Color filters (toggle) | effect `colorblindnesscorrection` and/or `invert` | SRC |
| A11Y.CF.2 | Filter: Inverted / Grayscale / Grayscale inverted | invert / `[Effect-colorblindnesscorrection] Mode=3` (Monochrome) / both | SRC (`colorblindnesscorrection.h:25-29`) |
| A11Y.CF.3 | Filter: Red-green (deuteranopia) / Red-green (protanopia) / Blue-yellow (tritanopia) | `Mode` = 1 / 0 / 2 | SRC |
| A11Y.CF.4 | Color intensity / Color boost | `[Effect-colorblindnesscorrection] Intensity (Double 1.0)` | SRC |
| A11Y.CF.5 | Color filters keyboard shortcut | — | N/A — hide |
| A11Y.CT.1 | Contrast themes: Aquatic / Desert / Dusk / Night sky + Edit | Plasma 6.7 ships only BreezeLight/BreezeDark/BreezeClassic schemes: we would ship our own high-contrast `.colors` into `~/.local/share/color-schemes` and apply with `plasma-apply-colorscheme` | PARTIAL · approach UNVERIFIED |
| A11Y.NAR.1 | Narrator (toggle) | `kaccessrc [ScreenReader] Enabled (Bool)` (kaccess starts Orca) | SRC `plasma-desktop/kcms/access/kcmaccessibilityscreenreader.kcfg` |
| A11Y.NAR.2 | Narrator settings (voice, speed, verbosity…) | — | N/A — hide |
| A11Y.AUD.1 | Mono audio | = SYS.SND.3 | N/A — disabled |
| A11Y.AUD.2 | Flash my screen during audio notifications | `kaccessrc [Bell] VisibleBell (Bool)`, `VisibleBellInvert`, `VisibleBellColor`, `VisibleBellPause` | SRC `kcmaccessibilitybell.kcfg` |
| A11Y.KB.1 | Sticky keys (toggle + ›) | `kaccessrc [Keyboard] StickyKeys`; › Lock shortcut keys when pressed twice = `StickyKeysLatch`; Turn off when two keys pressed = `StickyKeysAutoOff`; Play a sound = `StickyKeysBeep` | SRC `kcmaccessibilitykeyboard.kcfg` |
| A11Y.KB.1a | › Keyboard shortcut for Sticky keys (press Shift 5 times) | `kaccessrc [Keyboard] Gestures (Bool)`, `GestureConfirmation` | SRC `kcmaccessibilityactivationgestures.kcfg` |
| A11Y.KB.2 | Filter keys (toggle + ›: ignore quick / repeated keystrokes, beep) | `SlowKeys`, `SlowKeysDelay`, `SlowKeysPressBeep/AcceptBeep/RejectBeep`; `BounceKeys`, `BounceKeysDelay`, `BounceKeysRejectBeep` | SRC `kcmaccessibilitykeyboardfilters.kcfg` |
| A11Y.KB.3 | Toggle keys (sound on Caps/Num/Scroll Lock) | `kaccessrc [Keyboard] ToggleKeysBeep` | SRC |
| A11Y.KB.4 | On-screen keyboard | = TL.TYP.3 (`VirtualKeyboard.active`) | SRC |
| A11Y.KB.5 | Underline access keys; Use the Print screen key to open screen capture; Notification preferences | — | N/A — hide |
| A11Y.MS.1 | Mouse keys (toggle + ›: speed, acceleration) | `kaccessrc [Mouse] MouseKeys`, `MKMaxSpeed`, `MKTimeToMax`, `MKDelay`, `MKInterval`, `MKCurve` | SRC `kcmaccessibilitymouse.kcfg` |

## 10. Privacy & security  · owner: `backend/privacy.py`, `qml/pages/privacy/`, `qml/data/privacy.js`

Page order: **Security**: Windows Security · Find my device · Device encryption · (For developers moved to System) ·
**Windows permissions**: General · Speech · Inking & typing personalization · Diagnostics & feedback · Activity history ·
Search permissions · Searching Windows · **App permissions**: Location, Camera, Microphone, Voice activation, Notifications,
Account info, Contacts, Calendar, Phone calls, Call history, Email, Tasks, Messaging, Radios, Other devices, App diagnostics,
Automatic file downloads, Documents, Downloads folder, Music library, Pictures, Videos, File system, Screenshot borders,
Screenshots and apps. Hide: Find my device, General, Speech, Inking & typing, Voice activation, Account info, Contacts, Calendar,
Phone calls, Call history, Email, Tasks, Messaging, Radios, Other devices, App diagnostics, Automatic file downloads, Screenshot borders.

App permissions apply to **Flatpak apps only** (native packages are unsandboxed); every permission page says so.
Portal permission store: session bus `org.freedesktop.impl.portal.PermissionStore /org/freedesktop/impl/portal/PermissionStore`,
methods `Lookup, Set, Delete, SetValue, SetPermission, DeletePermission, GetPermission, List` (SRC
`flatpak-kcm/org.freedesktop.impl.portal.PermissionStore.xml`); CLI `flatpak permissions [table]`, `flatpak permission-set`,
`flatpak permission-remove` (CLI). Table names (SRC `xdg-desktop-portal/desktop-portal/*.c`): camera → `devices`,
location → `location`, notifications → `notifications` (id `notification`), screenshot → `screenshot`, background → `background`,
wallpaper → `wallpaper`, gamemode → `gamemode`, realtime → `realtime`. Static sandbox holes: `flatpak override --user
[--nofilesystem=… | --filesystem=…] [--nosocket=pulseaudio] [--nodevice=…] <app>` (CLI).

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| PRV.SEC.1 | Windows Security (virus, account protection, device security…) | — | N/A — disabled (keep row, link to Firewall) |
| PRV.SEC.2 | Firewall & network protection | `ufw status verbose / enable / disable / allow / deny / delete` ⚠root (what plasma-firewall drives) | CLI |
| PRV.SEC.3 | Device encryption | read-only: `lsblk -J -o NAME,TYPE,FSTYPE` (`crypto_LUKS` → "Encrypted") | CLI |
| PRV.DIA.1 | Diagnostics & feedback: Diagnostic data (Required / Optional) | `PlasmaUserFeedback [Global] FeedbackLevel (Int)`: 0 off, 0x10 basic system, 0x20 basic usage, 0x30 detailed system, 0x40 detailed usage | SRC `plasma-workspace/kcms/feedback/feedbacksettings.kcfg`, `kuserfeedback/src/provider/core/provider.h:162-165` |
| PRV.DIA.2 | Improve inking & typing, Tailored experiences, View diagnostic data, Delete diagnostic data, Feedback frequency | — | N/A — hide |
| PRV.DIA.3 | (extra) Crash reports | `drkonqirc [DrKonqi]` keys `Sentry`, `DownloadSymbols` | SRC `drkonqi/src/settings.kcfg` (file name UNVERIFIED) |
| PRV.ACT.1 | Activity history: Store my activity history on this device | `kactivitymanagerd-pluginsrc [Plugin-org.kde.ActivityManager.Resources.Scoring] what-to-remember (0 all apps, 1 specific apps, 2 none)` | SRC `plasma-desktop/kcms/recentFiles/kactivitymanagerd_plugins_settings.kcfg`, enum `kcm_recentFiles.h:45-48` |
| PRV.ACT.2 | (extra) Keep history for N months; blocked apps | `keep-history-for (Int months, 4)`, `blocked-applications`, `blocked-by-default` | SRC |
| PRV.ACT.3 | Clear activity history | `org.kde.ActivityManager /ActivityManager/Resources/Scoring org.kde.ActivityManager.ResourcesScoring.DeleteRecentStats / DeleteEarlierStats` | SRC `kactivitymanagerd/src/common/dbus/org.kde.ActivityManager.ResourcesScoring.xml`, `StatsPlugin.cpp:45` (argument values UNVERIFIED) |
| PRV.SRP.1 | Search permissions: SafeSearch, Cloud content search | — | N/A — hide |
| PRV.SRP.2 | Search history on this device | KRunner `krunnerrc [General] historyBehavior {Disabled, ImmediateCompletion, CompletionSuggestion}` | PARTIAL · SRC `plasma-desktop/kcms/runners/krunner/krunnersettingsbase.kcfg` |
| PRV.SRW.1 | Searching Windows: Find my files (Classic / Enhanced) | Baloo: `baloofilerc [Basic Settings] Indexing-Enabled (Bool)`; `[General] only basic indexing (Bool)`; `index hidden folders` | PARTIAL · SRC `baloo/src/lib/baloosettings.kcfg` |
| PRV.SRW.2 | Exclude folders from enhanced search (+ Add) | `[General] exclude folders (StringList)`, `folders (StringList)`; (extra) `exclude mimetypes`, `exclude filters` | SRC |
| PRV.SRW.3 | Indexer status / Advanced indexing options | `balooctl6 status` | UNVERIFIED (CLI not checked) |
| PRV.APP.1 | Location: Location services (master), Let apps access your location, per-app | per-app = `location` table; master — | PARTIAL · SRC |
| PRV.APP.2 | Camera: Camera access, Let apps access, per-app | `devices` table (entry id for camera UNVERIFIED) | PARTIAL · SRC |
| PRV.APP.3 | Microphone | no portal table; Flatpak static: `flatpak override --user --nosocket=pulseaudio <app>` | PARTIAL · CLI |
| PRV.APP.4 | Notifications: per-app | `notifications` table; also SYS.NOT.5 | SRC |
| PRV.APP.5 | Documents / Downloads folder / Music library / Pictures / Videos / File system | `flatpak override --user --filesystem=xdg-documents|xdg-download|xdg-music|xdg-pictures|xdg-videos|home|host[:ro] <app>` / `--nofilesystem=` | SRC `flatpak-kcm/flatpakpermission.cpp:78,100-135` · CLI |
| PRV.APP.6 | Screenshots and apps | `screenshot` table | SRC |
| PRV.APP.7 | (Win: Installed apps › Advanced › Background apps) Let this app run in background | `background` table | SRC |

## 11. System updates (Windows Update)  · owner: `backend/updates.py`, `qml/pages/updates/`, `qml/data/updates.js`

Page order: status hero + Check for updates / Download & install · Pause updates · Update history · Advanced options ·
Windows Insider Program · "Get the latest updates as soon as they're available". Hide: Windows Insider Program, "Get the latest…".
Sources: PackageKit (distro), Flatpak, fwupd (firmware = Win "driver/optional updates").

| ID | Win11 setting | Linux equivalent / how | Status |
|---|---|---|---|
| UPD.1 | Check for updates (status: "You're up to date", last checked) | `pkcon refresh` then `pkcon get-updates`; `flatpak remote-ls --updates`; `fwupdmgr get-updates` (long-running → `_async`) | CLI |
| UPD.2 | Download & install all / Restart now | `pkcon -p -y update` ⚠polkit; `flatpak update -y --noninteractive`; restart `org.kde.LogoutPrompt /LogoutPrompt promptReboot` | CLI · SRC `plasma-workspace/kcms/region_language/kcmregionandlang.cpp:275-278` |
| UPD.3 | Pause updates (1–5 weeks) | stop Discover's notifier from nagging: `PlasmaDiscoverUpdates [Global] RequiredNotificationInterval (Int s)` | PARTIAL · SRC `discover/kcm/updatessettings.kcfg` |
| UPD.4 | Update history: Quality / Driver / Definition / Other updates | packages: `/var/log/apt/history.log` (Ubuntu); firmware: `fwupdmgr get-history`; Flatpak: `flatpak history` | CLI (fwupd, flatpak) · apt log UNVERIFIED |
| UPD.4a | Uninstall updates; Recovery | — | N/A — hide |
| UPD.5 | Advanced options › Receive updates for other Microsoft products | — | N/A — hide |
| UPD.5a | › Get me up to date (restart ASAP) | — | N/A — hide |
| UPD.5b | › Download updates over metered connections | — | N/A — hide |
| UPD.5c | › Notify me when a restart is required | `/var/run/reboot-required` (Ubuntu) | UNVERIFIED |
| UPD.5d | › Active hours | — | N/A — hide |
| UPD.5e | › Optional updates (driver updates) | firmware: `fwupdmgr get-updates / update` | CLI |
| UPD.5f | › Delivery Optimization; Configured update policies | — | N/A — hide |
| UPD.6 | (Plasma) Automatic updates | `PlasmaDiscoverUpdates [Global] UseUnattendedUpdates (Bool)` | SRC |
| UPD.7 | (Plasma) Apply system updates on restart (offline updates) | `discoverrc [Software] UseOfflineUpdates (Bool)` | SRC `discover/kcm/discoversettings.kcfg` |

---

## Summary

Updated after Phase 1: rows the section agents verified from source or real output were re-tagged.

Primary status per row (a row tagged "APP · SRC" counts as APP; anything with a remaining UNVERIFIED part in its
first clause counts as UNVERIFIED). Rows marked (extra) are Plasma features with no Win11 row; they are counted too.

| Section | Rows | APP | SRC | CLI | PARTIAL | UNVERIFIED | N/A (hide / disabled) |
|---|---|---|---|---|---|---|---|
| 1. System | 139 | 23 | 53 | 7 | 12 | 7 | 37 |
| 2. Bluetooth & devices | 56 | 2 | 29 | 4 | 4 | 5 | 12 |
| 3. Network & internet | 38 | 5 | 12 | 7 | 2 | 1 | 11 |
| 4. Personalization | 57 | 4 | 25 | 1 | 6 | 4 | 17 |
| 5. Apps | 12 | 0 | 4 | 4 | 1 | 0 | 3 |
| 6. Accounts | 20 | 1 | 10 | 1 | 0 | 1 | 7 |
| 7. Time & language | 29 | 2 | 16 | 3 | 3 | 2 | 3 |
| 8. Gaming | 7 | 0 | 3 | 0 | 0 | 1 | 3 |
| 9. Accessibility | 34 | 1 | 22 | 0 | 3 | 1 | 7 |
| 10. Privacy & security | 21 | 0 | 10 | 3 | 5 | 0 | 3 |
| 11. System updates (Windows Update) | 14 | 0 | 3 | 3 | 1 | 1 | 6 |
| **Total** | **427** | **38** | **187** | **33** | **37** | **23** | **109** |

**Hand-offs that remain by design** (no verified non-KCM way): Online accounts (ACC.EML.1), printer properties
dialog (BT.PRN.3c, `configure-printer`). Everything else is either native, partial-native, or hidden/disabled as N/A.
