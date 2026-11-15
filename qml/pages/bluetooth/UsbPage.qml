import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > USB (BT.USB.2): USB4 / Thunderbolt devices via bolt
SettingsPage {
    id: page
    crumbs: ["Bluetooth & devices", "USB"]

    function status(d) {
        const s = d.status
        return s === "authorized" ? "Connected and authorized"
             : s === "connected" ? "Connected, not authorized"
             : s === "authorizing" ? "Authorizing…"
             : s === "auth-error" ? "Authorization failed"
             : s === "disconnected" ? (d.stored ? "Remembered, not connected" : "Not connected") : s
    }

    Component.onCompleted: Backend.refreshThunderbolt()
    Timer { interval: 6000; repeat: true; running: true; onTriggered: Backend.refreshThunderbolt() }

    SectionHeader { text: "USB4 hubs and devices"; Layout.topMargin: 0 }
    Repeater {
        model: Backend.thunderboltDevices
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:usb_plug_20_regular"
            title: modelData.name.length ? modelData.name : "USB4 device"
            description: (modelData.vendor.length ? modelData.vendor + " · " : "") + page.status(modelData)
            FluentButton {
                visible: modelData.status === "connected" || modelData.status === "auth-error"
                text: "Authorize"
                onClicked: Backend.authorizeThunderboltDevice(modelData.uid)
            }
            FluentButton {
                visible: modelData.stored
                text: "Forget"
                onClicked: Backend.forgetThunderboltDevice(modelData.uid)
            }
        }
    }
    SettingsCard {
        visible: Backend.thunderboltDevices.length === 0
        icon: "fl:usb_plug_20_regular"
        title: "No USB4 devices"
        description: Backend.thunderboltAvailable ? "Connect a USB4 or Thunderbolt hub or device to manage it here."
                                                  : "USB4 device management isn't available on this PC."
    }
}
