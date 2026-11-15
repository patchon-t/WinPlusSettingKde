.pragma library

// BlueZ `Icon:` value -> bundled Fluent icon (values: SRC bluez src/dbus-common.c)
function deviceIcon(icon) {
    switch (icon) {
    case "audio-headset": return "fl:headset_20_regular"
    case "audio-headphones": return "fl:headphones_20_regular"
    case "audio-card": return "fl:speaker_bluetooth_20_regular"
    case "input-keyboard": return "fl:keyboard_20_regular"
    case "input-mouse": return "fl:cursor_20_regular"
    case "input-tablet": return "fl:tablet_20_regular"
    case "input-gaming": return "fl:xbox_controller_20_regular"
    case "phone": return "fl:phone_20_regular"
    case "computer": return "fl:laptop_20_regular"
    case "video-display": return "fl:desktop_20_regular"
    case "printer": return "fl:print_20_regular"
    case "camera-photo":
    case "camera-video": return "fl:camera_20_regular"
    case "scanner": return "fl:scan_20_regular"
    default: return "fl:bluetooth_20_regular"
    }
}

// "Connected" / "Paired" (+ battery)
function deviceStatus(d, compact) {
    var s = d.connected ? "Connected" : "Paired"
    if (d.battery >= 0)
        s += " · " + d.battery + (compact ? "%" : "% battery")
    return s
}

// Win11 mouse-speed slider (1-20, 10 = default) <-> libinput acceleration (-1..1, 0 = default)
function speedFromAccel(a) {
    var s = a >= 0 ? a * 10 + 10 : a * 9 + 10
    return Math.max(1, Math.min(20, Math.round(s)))
}
function accelFromSpeed(s) {
    return s >= 10 ? (s - 10) / 10 : (s - 10) / 9
}
