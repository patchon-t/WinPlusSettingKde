.pragma library
.import "helpers.js" as H

// System section. Owned by the System agent.
var P = "pages/system/"

var entry = H.list("System", "fl:laptop_20_color", [
    { icon: "fl:desktop_20_regular", title: "Display", desc: "Monitors, brightness, night light, display profile", page: P + "DisplayPage.qml" },
    { icon: "fl:speaker_2_20_regular", title: "Sound", desc: "Volume levels, output, input, sound devices", page: P + "SoundPage.qml" },
    { icon: "fl:alert_20_regular", title: "Notifications", desc: "Alerts from apps and system, do not disturb", kcm: "kcm_notifications" },
    { icon: "fl:battery_charge_20_regular", title: "Power & battery", desc: "Screen and sleep, battery usage, power mode", page: P + "PowerPage.qml" },
    { icon: "fl:storage_20_regular", title: "Storage", desc: "Storage space, drives, disk usage", cmd: ["filelight", "/"] },
    { icon: "fl:phone_laptop_20_regular", title: "Nearby sharing", desc: "KDE Connect, phones and other devices", kcm: "kcm_kdeconnect" },
    { icon: "fl:window_multiple_20_regular", title: "Multitasking", desc: "Virtual desktops, task switching, screen edges", kcm: "kcm_kwin_virtualdesktops" },
    { icon: "fl:keyboard_20_regular", title: "Shortcuts", desc: "Global and app keyboard shortcuts", kcm: "kcm_keys" },
    { icon: "fl:remote_20_regular", title: "Remote Desktop", desc: "Remote desktop users, connection permissions", kcm: "kcm_krdpserver" },
    { icon: "fl:sign_out_20_regular", title: "Session", desc: "Login, logout, restore previous session", kcm: "kcm_smserver" },
    { icon: "fl:apps_add_in_20_regular", title: "Optional features", desc: "Extra functionality for your device", cmd: ["plasma-discover"] },
    { icon: "fl:info_20_regular", title: "About", desc: "Device specifications, rename PC, OS and Plasma versions", page: P + "AboutPage.qml" }
])

// Settings inside pages, for search. nav = section title (set by Data.js)
var settings = [
    { title: "Night light", kw: "night color blue light warm", icon: "fl:desktop_20_regular", page: P + "DisplayPage.qml" },
    { title: "Display resolution", kw: "resolution screen size", icon: "fl:desktop_20_regular", page: P + "DisplayPage.qml" },
    { title: "Scale", kw: "scale dpi zoom size text", icon: "fl:desktop_20_regular", page: P + "DisplayPage.qml" },
    { title: "Refresh rate", kw: "hz refresh fps", icon: "fl:desktop_20_regular", page: P + "DisplayPage.qml" },
    { title: "Brightness", kw: "brightness dim", icon: "fl:desktop_20_regular", page: P + "DisplayPage.qml" },
    { title: "Volume", kw: "volume sound speaker output mute", icon: "fl:speaker_2_20_regular", page: P + "SoundPage.qml" },
    { title: "Microphone", kw: "mic microphone input recording", icon: "fl:mic_20_regular", page: P + "SoundPage.qml" },
    { title: "Power mode", kw: "power performance battery saver profile", icon: "fl:gauge_20_regular", page: P + "PowerPage.qml" },
    { title: "Screen and sleep", kw: "sleep screen timeout turn off", icon: "fl:desktop_20_regular", page: P + "PowerPage.qml" },
    { title: "Rename this PC", kw: "rename hostname computer name", icon: "fl:laptop_20_color", page: P + "AboutPage.qml" }
]
