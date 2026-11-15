.pragma library
.import "helpers.js" as H

// System section. Owned by the System agent.
// Top page = Windows 11 24H2 order. N/A pages (Activation, Troubleshoot, Recovery, Projecting
// to this PC, System components, Optional features) are hidden.
var P = "pages/system/"

var entry = H.list("System", "fl:laptop_20_color", [
    { icon: "fl:desktop_20_regular", title: "Display", desc: "Monitors, brightness, night light, display profile", page: P + "DisplayPage.qml",
      items: [
        { icon: "fl:weather_moon_20_regular", title: "Night light", desc: "Use warmer colors to help block blue light", page: P + "NightLightPage.qml" },
        { icon: "fl:hdr_20_regular", title: "HDR", desc: "Brighter, more vivid picture in HDR content", page: P + "HdrPage.qml" },
        { icon: "fl:desktop_20_regular", title: "Advanced display", desc: "Display information, refresh rate", page: P + "AdvancedDisplayPage.qml" },
        { icon: "fl:developer_board_20_regular", title: "Graphics", desc: "Variable refresh rate, screen tearing", page: P + "GraphicsPage.qml" },
        { icon: "fl:resize_20_regular", title: "Custom scaling", desc: "Enter a custom scaling size", page: P + "CustomScalingPage.qml" }
      ] },
    { icon: "fl:speaker_2_20_regular", title: "Sound", desc: "Volume levels, output, input, sound devices", page: P + "SoundPage.qml",
      items: [
        { icon: "fl:headphones_20_regular", title: "All sound devices", desc: "Turn devices on or off, troubleshoot, other options", page: P + "SoundDevicesPage.qml" },
        { icon: "fl:speaker_2_20_regular", title: "Sound device properties", desc: "Volume, balance, port, allow or block a device", page: P + "SoundDevicePage.qml",
          props: { kind: "sink", name: "alsa_output.pci-0000_00_1f.3.analog-stereo", card: "alsa_card.pci-0000_00_1f.3" } },
        { icon: "fl:options_20_regular", title: "Volume mixer", desc: "App volume mix, app input & output devices", page: P + "VolumeMixerPage.qml" }
      ] },
    { icon: "fl:alert_20_regular", title: "Notifications", desc: "Alerts from apps and system, do not disturb", page: P + "NotificationsPage.qml",
      items: [
        { icon: "fl:alert_urgent_20_regular", title: "Set priority notifications", desc: "Choose which notifications can break through do not disturb", page: P + "NotificationPriorityPage.qml" },
        { icon: "fl:alert_20_regular", title: "App notification settings", desc: "Banners, notification center, badges", page: P + "NotificationAppPage.qml",
          props: { appId: "org.kde.dolphin", appName: "Dolphin", appIcon: "system-file-manager", kind: "app" } }
      ] },
    { icon: "fl:timer_20_regular", title: "Focus", desc: "Reduce distractions with a focus session and do not disturb", page: P + "FocusPage.qml" },
    { icon: "fl:battery_charge_20_regular", title: "Power & battery", desc: "Screen and sleep, battery usage, power mode", page: P + "PowerPage.qml" },
    { icon: "fl:storage_20_regular", title: "Storage", desc: "Storage space, drives, disk usage", page: P + "StoragePage.qml",
      items: [
        { icon: "fl:delete_20_regular", title: "Temporary files", desc: "Trash, thumbnails and app cache", page: P + "StorageTempFilesPage.qml" },
        { icon: "fl:hard_drive_20_regular", title: "Disks & volumes", desc: "View drives, partitions and free space", page: P + "StorageDisksPage.qml" },
        { icon: "fl:folder_20_regular", title: "Where new content is saved", desc: "Documents, music, pictures and videos folders", page: P + "StoragePathsPage.qml" }
      ] },
    { icon: "fl:phone_laptop_20_regular", title: "Nearby sharing", desc: "KDE Connect, phones and other devices", page: P + "NearbySharingPage.qml" },
    { icon: "fl:window_multiple_20_regular", title: "Multitasking", desc: "Snap windows, desktops, Alt + Tab", page: P + "MultitaskingPage.qml" },
    { icon: "fl:code_20_regular", title: "For developers", desc: "Terminal and other developer settings", page: P + "DevelopersPage.qml" },
    { icon: "fl:remote_20_regular", title: "Remote Desktop", desc: "Remote desktop users, connection permissions", page: P + "RemoteDesktopPage.qml" },
    { icon: "fl:clipboard_20_regular", title: "Clipboard", desc: "Clipboard history, clear clipboard data", page: P + "ClipboardPage.qml" },
    { icon: "fl:info_20_regular", title: "About", desc: "Device specifications, rename PC, OS and Plasma versions", page: P + "AboutPage.qml" }
])

// Settings inside pages, for search. nav = section title (set by Data.js)
var D = "fl:desktop_20_regular"
var settings = [
    // Display
    { title: "Night light", kw: "night color blue light warm strength schedule sunset sunrise", icon: "fl:weather_moon_20_regular", page: P + "NightLightPage.qml" },
    { title: "Brightness", kw: "brightness dim backlight", icon: "fl:brightness_high_20_regular", page: P + "DisplayPage.qml" },
    { title: "Change brightness based on content", kw: "adaptive backlight abm content power saving", icon: "fl:dark_theme_20_regular", page: P + "DisplayPage.qml" },
    { title: "Display resolution", kw: "resolution screen size", icon: D, page: P + "DisplayPage.qml" },
    { title: "Scale", kw: "scale dpi zoom size text", icon: "fl:resize_20_regular", page: P + "DisplayPage.qml" },
    { title: "Custom scaling", kw: "scale percent zoom xwayland legacy x11", icon: "fl:resize_20_regular", page: P + "CustomScalingPage.qml" },
    { title: "Display orientation", kw: "rotate rotation portrait landscape", icon: "fl:rotate_right_20_regular", page: P + "DisplayPage.qml" },
    { title: "Multiple displays", kw: "extend duplicate mirror second monitor main display identify detect", icon: "fl:desktop_pulse_20_regular", page: P + "DisplayPage.qml" },
    { title: "Color profile", kw: "icc color management srgb profile", icon: "fl:color_background_20_regular", page: P + "DisplayPage.qml" },
    { title: "HDR", kw: "hdr high dynamic range sdr brightness wide color gamut wcg", icon: "fl:hdr_20_regular", page: P + "HdrPage.qml" },
    { title: "Refresh rate", kw: "hz refresh fps", icon: "fl:top_speed_20_regular", page: P + "AdvancedDisplayPage.qml" },
    { title: "Dynamic refresh rate", kw: "vrr variable adaptive sync freesync gsync", icon: "fl:top_speed_20_regular", page: P + "AdvancedDisplayPage.qml" },
    { title: "Variable refresh rate", kw: "vrr adaptive sync freesync gsync games", icon: "fl:top_speed_20_regular", page: P + "GraphicsPage.qml" },
    { title: "Allow tearing in full-screen games", kw: "tearing latency games vsync", icon: "fl:games_20_regular", page: P + "GraphicsPage.qml" },
    { title: "Maximum bits per color", kw: "bpc bit depth color depth", icon: "fl:color_20_regular", page: P + "AdvancedDisplayPage.qml" },
    // Sound
    { title: "Volume", kw: "volume sound speaker output mute", icon: "fl:speaker_2_20_regular", page: P + "SoundPage.qml" },
    { title: "Microphone", kw: "mic microphone input recording", icon: "fl:mic_20_regular", page: P + "SoundPage.qml" },
    { title: "Volume mixer", kw: "app volume per app sound mix", icon: "fl:options_20_regular", page: P + "VolumeMixerPage.qml" },
    { title: "Raise maximum volume to 150%", kw: "volume boost overamplification max volume", icon: "fl:speaker_2_20_regular", page: P + "SoundPage.qml" },
    { title: "Play system sounds", kw: "sound theme startup beep event sounds", icon: "fl:speaker_2_20_regular", page: P + "SoundPage.qml" },
    { title: "All sound devices", kw: "audio devices enable disable balance port", icon: "fl:headphones_20_regular", page: P + "SoundDevicesPage.qml" },
    // Notifications / Focus
    { title: "Do not disturb", kw: "dnd quiet silence notifications", icon: "fl:alert_snooze_20_regular", page: P + "NotificationsPage.qml" },
    { title: "Priority notifications", kw: "breakthrough critical calls reminders dnd", icon: "fl:alert_urgent_20_regular", page: P + "NotificationPriorityPage.qml" },
    { title: "Focus session", kw: "focus timer concentrate", icon: "fl:timer_20_regular", page: P + "FocusPage.qml" },
    // Power
    { title: "Power mode", kw: "power performance battery saver profile balanced", icon: "fl:gauge_20_regular", page: P + "PowerPage.qml" },
    { title: "Screen and sleep", kw: "sleep screen timeout turn off hibernate idle", icon: D, page: P + "PowerPage.qml" },
    { title: "Energy saver", kw: "battery saver low battery", icon: "fl:leaf_two_20_regular", page: P + "PowerPage.qml" },
    { title: "Lid & power controls", kw: "lid close power button shutdown suspend", icon: "fl:plug_connected_20_regular", page: P + "PowerPage.qml" },
    // Storage
    { title: "Temporary files", kw: "trash recycle bin cache thumbnails clean free up space", icon: "fl:delete_20_regular", page: P + "StorageTempFilesPage.qml" },
    { title: "Disks & volumes", kw: "drives partitions mount lsblk", icon: "fl:hard_drive_20_regular", page: P + "StorageDisksPage.qml" },
    { title: "Where new content is saved", kw: "documents pictures music videos downloads folders xdg", icon: "fl:folder_20_regular", page: P + "StoragePathsPage.qml" },
    { title: "Low disk space warning", kw: "free space notification", icon: "fl:alert_20_regular", page: P + "StoragePage.qml" },
    // Others
    { title: "Snap windows", kw: "tile maximize screen edge corner", icon: "fl:window_multiple_20_regular", page: P + "MultitaskingPage.qml" },
    { title: "Virtual desktops", kw: "workspaces desktops add remove rename", icon: "fl:apps_list_20_regular", page: P + "MultitaskingPage.qml" },
    { title: "Alt + Tab", kw: "task switcher windows desktops", icon: "fl:keyboard_20_regular", page: P + "MultitaskingPage.qml" },
    { title: "Terminal", kw: "default terminal konsole developer", icon: "fl:window_console_20_regular", page: P + "DevelopersPage.qml" },
    { title: "Clipboard history", kw: "klipper copy paste history clear", icon: "fl:clipboard_20_regular", page: P + "ClipboardPage.qml" },
    { title: "Remote Desktop port", kw: "rdp krdp remote connect port users", icon: "fl:remote_20_regular", page: P + "RemoteDesktopPage.qml" },
    { title: "Save files I receive to", kw: "bluetooth receive kde connect share", icon: "fl:folder_20_regular", page: P + "NearbySharingPage.qml" },
    { title: "Device specifications", kw: "processor ram cpu gpu graphics card device id model", icon: "fl:info_20_regular", page: P + "AboutPage.qml" },
    { title: "Rename this PC", kw: "rename hostname computer name", icon: "fl:laptop_20_color", page: P + "AboutPage.qml" }
]
