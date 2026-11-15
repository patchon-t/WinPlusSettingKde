.pragma library
.import "helpers.js" as H

// Bluetooth & devices section. Owned by the Bluetooth & devices agent.
var P = "pages/bluetooth/"

var entry = H.custom("Bluetooth & devices", "fl:bluetooth_20_filled@0078d4", P + "BluetoothPage.qml", [
    { icon: "fl:print_20_regular", title: "Printers & scanners", desc: "Preferences, troubleshoot", kcm: "kcm_printer_manager" },
    { icon: "fl:cursor_20_regular", title: "Mouse", desc: "Buttons, pointer speed, scrolling", kcm: "kcm_mouse" },
    { icon: "fl:cursor_20_regular", title: "Touchpad", desc: "Taps, gestures, scrolling, zooming", kcm: "kcm_touchpad" },
    { icon: "fl:keyboard_20_regular", title: "Keyboard", desc: "Layouts, repeat rate, NumLock", kcm: "kcm_keyboard" },
    { icon: "fl:tablet_20_regular", title: "Drawing tablet", desc: "Pen buttons, screen mapping", kcm: "kcm_tablet" },
    { icon: "fl:usb_stick_20_regular", title: "Removable storage", desc: "What happens when you plug in drives", kcm: "kcm_device_automounter" },
    { icon: "fl:xbox_controller_20_regular", title: "Game controllers", desc: "Test and set up gamepads", kcm: "kcm_gamecontroller" }
])

var settings = []
