import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > Devices (BT.2, BT.3, BT.4*)
SettingsPage {
    id: page
    crumbs: ["Bluetooth & devices", "Devices"]

    property string removeMac: ""
    property string removeName: ""
    readonly property var all: Backend.bluetoothDevices
    function group(kind) { return all.filter(d => d.kind === kind) }

    Component.onCompleted: { Backend.refreshBluetoothDevices(); Backend.refreshBluetoothSettings() }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: Backend.refreshBluetoothDevices() }

    BtAddDeviceDialog { id: addDialog }
    BtConfirmDialog {
        id: removeDialog
        title: "Remove this device?"
        message: "\"" + page.removeName + "\" will be unpaired from this PC. You'll need to pair it again to use it."
        acceptText: "Remove"
        onAccepted: Backend.bluetoothRemove(page.removeMac)
    }

    SettingsCard {
        icon: "fl:add_20_regular"
        title: "Add device"
        description: !Backend.bluetoothAvailable ? "No Bluetooth adapter found"
                     : Backend.bluetoothOn ? "Bluetooth" : "Turn on Bluetooth to add a device"
        enabled: Backend.bluetoothOn
        FluentButton { text: "Add device"; accent: true; onClicked: addDialog.open() }
    }

    // ---- groups
    SectionHeader { text: "Mouse, keyboard & pen"; visible: mouseRep.count > 0 }
    Repeater {
        id: mouseRep
        model: page.group("input")
        delegate: BtDeviceCard {
            required property var modelData
            device: modelData
            onRemoveRequested: (mac, name) => { page.removeMac = mac; page.removeName = name; removeDialog.open() }
        }
    }

    SectionHeader { text: "Audio"; visible: audioRep.count > 0 }
    Repeater {
        id: audioRep
        model: page.group("audio")
        delegate: BtDeviceCard {
            required property var modelData
            device: modelData
            onRemoveRequested: (mac, name) => { page.removeMac = mac; page.removeName = name; removeDialog.open() }
        }
    }

    SectionHeader { text: "Other devices"; visible: otherRep.count > 0 }
    Repeater {
        id: otherRep
        model: page.group("other")
        delegate: BtDeviceCard {
            required property var modelData
            device: modelData
            onRemoveRequested: (mac, name) => { page.removeMac = mac; page.removeName = name; removeDialog.open() }
        }
    }

    SettingsCard {
        visible: page.all.length === 0
        Layout.topMargin: 12
        icon: "fl:bluetooth_searching_20_regular"
        title: Backend.bluetoothOn ? "No paired devices" : "Bluetooth is off"
        description: Backend.bluetoothOn ? "Select Add device to pair a mouse, keyboard, headphones, or anything else."
                                         : "Turn on Bluetooth on the previous page to see your devices."
    }

    // ---- device settings
    SectionHeader { text: "Device settings" }
    SettingsCard {
        icon: "fl:bluetooth_connected_20_regular"
        title: "Make this PC discoverable"
        description: "Let nearby Bluetooth devices find \"" + Backend.hostname + "\" while this is on"
        enabled: Backend.bluetoothOn
        FluentToggle {
            checked: Backend.bluetoothDiscoverable
            onToggled: (c) => Backend.setBluetoothDiscoverable(c)
        }
    }
    SettingsCard {
        icon: "fl:power_20_regular"
        title: "Bluetooth when you sign in"
        description: "Whether Bluetooth is on after you log in"
        enabled: Backend.bluetoothAvailable
        FluentCombo {
            minWidth: 160
            model: ["Remember last state", "Always on", "Always off"]
            currentIndex: Backend.bluetoothLaunchState
            onActivated: (i) => Backend.setBluetoothLaunchState(i)
        }
    }
    SettingsCard {
        icon: "fl:send_20_regular"
        title: "Send or receive files via Bluetooth"
        description: "Send files to a paired device"
        enabled: Backend.bluetoothOn
        FluentButton { text: "Send files"; onClicked: Backend.bluetoothSendFiles() }
    }
}
