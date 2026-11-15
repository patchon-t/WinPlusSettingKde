import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > Mobile devices (BT.MOB.*): phones and tablets through KDE Connect
SettingsPage {
    id: page
    crumbs: ["Bluetooth & devices", "Mobile devices"]

    function status(d) {
        return d.paired ? (d.reachable ? "Paired · Connected" : "Paired · Not reachable")
                        : (d.reachable ? "Available to pair" : "Not paired")
    }

    Component.onCompleted: Backend.refreshMobileDevices()
    Timer { interval: 10000; repeat: true; running: true; onTriggered: if (!Backend.mobileBusy) Backend.refreshMobileDevices() }

    SettingsCard {
        icon: "fl:phone_laptop_20_regular"
        title: "Allow this PC to access your mobile devices"
        description: Backend.mobileAvailable ? "Uses KDE Connect to share files, ring and ping your phone"
                                             : "KDE Connect isn't installed"
        enabled: Backend.mobileAvailable
        FluentButton { text: "Refresh"; enabled: !Backend.mobileBusy; onClicked: Backend.refreshMobileDevices() }
    }

    SectionHeader { text: "Your devices"; visible: Backend.mobileDevices.length > 0 }
    Repeater {
        model: Backend.mobileDevices
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:phone_20_regular"
            title: modelData.name
            description: page.status(modelData)
            clickable: modelData.paired
            onClicked: Router.open("pages/bluetooth/MobileDevicePage.qml", { deviceId: modelData.id, deviceName: modelData.name })
            FluentButton {
                visible: !modelData.paired
                enabled: modelData.reachable
                text: "Pair"
                onClicked: Backend.mobilePair(modelData.id)
            }
        }
    }

    SettingsCard {
        visible: Backend.mobileAvailable && Backend.mobileDevices.length === 0
        Layout.topMargin: 12
        icon: "fl:phone_20_regular"
        title: Backend.mobileBusy ? "Looking for devices…" : "No mobile devices found"
        description: "Install KDE Connect on your phone and connect it to the same network as this PC."
    }
}
