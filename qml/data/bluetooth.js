.pragma library
.import "helpers.js" as H

// Bluetooth & devices section. Owned by the Bluetooth & devices agent.
var P = "pages/bluetooth/"

var entry = H.custom("Bluetooth & devices", "fl:bluetooth_20_filled@0078d4", P + "BluetoothPage.qml", [
    { icon: "fl:bluetooth_20_regular", title: "Devices", desc: "Mouse, keyboard, pen, audio, and other devices", page: P + "DevicesPage.qml" },
    { icon: "fl:print_20_regular", title: "Printers & scanners", desc: "Preferences, troubleshoot", page: P + "PrintersPage.qml",
      items: [
        { icon: "fl:print_20_regular", title: "Printer", desc: "Default, print queue, test page", page: P + "PrinterPage.qml",
          props: { printerName: "Printer" },
          items: [{ icon: "fl:document_20_regular", title: "Print queue", desc: "Documents waiting to print",
                    page: P + "PrintQueuePage.qml", props: { printerName: "Printer" } }] }
      ] },
    { icon: "fl:phone_20_regular", title: "Mobile devices", desc: "Instantly access your mobile devices from your PC", page: P + "MobileDevicesPage.qml",
      items: [
        { icon: "fl:phone_20_regular", title: "Mobile device", desc: "Ring, ping, send files", page: P + "MobileDevicePage.qml",
          props: { deviceId: "sample", deviceName: "Phone" } }
      ] },
    { icon: "fl:camera_20_regular", title: "Cameras", desc: "Connected cameras, default image settings", page: P + "CamerasPage.qml",
      items: [
        { icon: "fl:camera_20_regular", title: "Camera", desc: "Default image settings", page: P + "CameraPage.qml",
          props: { cameraName: "Camera", cameraDevice: "/dev/video0" } }
      ] },
    { icon: "fl:cursor_20_regular", title: "Mouse", desc: "Buttons, mouse pointer speed, scrolling", page: P + "MousePage.qml" },
    { icon: "fl:tap_single_20_regular", title: "Touchpad", desc: "Taps, gestures, scrolling, zooming", page: P + "TouchpadPage.qml" },
    { icon: "fl:pen_20_regular", title: "Pen & Windows Ink", desc: "Right or left-handed, pressure, display mapping", page: P + "PenPage.qml" },
    { icon: "fl:play_circle_20_regular", title: "AutoPlay", desc: "Defaults for removable drives and memory cards", page: P + "AutoPlayPage.qml" },
    { icon: "fl:usb_plug_20_regular", title: "USB", desc: "USB4 hubs and devices", page: P + "UsbPage.qml" }
])

// Search keywords for settings inside the pages
var settings = [
    { title: "Bluetooth", kw: "bluetooth on off turn wireless adapter", icon: "fl:bluetooth_20_regular" },
    { title: "Add device", kw: "add pair bluetooth device headphones keyboard mouse speaker connect", icon: "fl:add_20_regular", page: P + "DevicesPage.qml" },
    { title: "Make this PC discoverable", kw: "bluetooth discoverable visible", icon: "fl:bluetooth_connected_20_regular", page: P + "DevicesPage.qml" },
    { title: "Bluetooth when you sign in", kw: "bluetooth login startup remember always on off", icon: "fl:bluetooth_20_regular", page: P + "DevicesPage.qml" },
    { title: "Send or receive files via Bluetooth", kw: "bluetooth send receive files share", icon: "fl:send_20_regular", page: P + "DevicesPage.qml" },
    { title: "Remove device", kw: "unpair forget bluetooth remove device", icon: "fl:delete_20_regular", page: P + "DevicesPage.qml" },
    { title: "Add printer", kw: "add printer scanner cups print", icon: "fl:print_add_20_regular", page: P + "PrintersPage.qml" },
    { title: "Default printer", kw: "default printer set", icon: "fl:print_20_regular", page: P + "PrintersPage.qml" },
    { title: "Print queue", kw: "print queue cancel documents jobs test page", icon: "fl:document_20_regular", page: P + "PrintersPage.qml" },
    { title: "Find my phone", kw: "kde connect phone ring ping send file android mobile", icon: "fl:phone_vibrate_20_regular", page: P + "MobileDevicesPage.qml" },
    { title: "Primary mouse button", kw: "mouse left right handed swap buttons primary", icon: "fl:cursor_click_20_regular", page: P + "MousePage.qml" },
    { title: "Mouse pointer speed", kw: "mouse pointer cursor speed sensitivity acceleration", icon: "fl:cursor_hover_20_regular", page: P + "MousePage.qml" },
    { title: "Enhance pointer precision", kw: "mouse acceleration adaptive flat precision", icon: "fl:cursor_20_regular", page: P + "MousePage.qml" },
    { title: "Lines to scroll at a time", kw: "mouse wheel scroll lines speed", icon: "fl:arrow_sync_20_regular", page: P + "MousePage.qml" },
    { title: "Scroll inactive windows when hovering over them", kw: "mouse wheel scroll inactive windows hover", icon: "fl:arrow_sync_20_regular", page: P + "MousePage.qml" },
    { title: "Double-click speed", kw: "mouse double click interval speed", icon: "fl:tap_single_20_regular", page: P + "MousePage.qml" },
    { title: "Touchpad", kw: "touchpad trackpad on off disable external mouse", icon: "fl:tap_single_20_regular", page: P + "TouchpadPage.qml" },
    { title: "Tap to click", kw: "touchpad tap click right-click drag two fingers corner", icon: "fl:tap_single_20_regular", page: P + "TouchpadPage.qml" },
    { title: "Touchpad scrolling direction", kw: "touchpad natural scroll direction two fingers scroll", icon: "fl:arrow_sync_20_regular", page: P + "TouchpadPage.qml" },
    { title: "Reset your touchpad", kw: "touchpad reset default", icon: "fl:arrow_reset_20_regular", page: P + "TouchpadPage.qml" },
    { title: "Choose which hand you write with", kw: "pen tablet left right handed drawing wacom", icon: "fl:hand_draw_20_regular", page: P + "PenPage.qml" },
    { title: "Pen pressure", kw: "pen tablet pressure range drawing map display", icon: "fl:pen_20_regular", page: P + "PenPage.qml" },
    { title: "Use AutoPlay for all media and devices", kw: "autoplay automount removable drives usb memory card plug in", icon: "fl:play_circle_20_regular", page: P + "AutoPlayPage.qml" },
    { title: "USB4 hubs and devices", kw: "usb4 thunderbolt authorize bolt hub dock", icon: "fl:usb_plug_20_regular", page: P + "UsbPage.qml" }
]
