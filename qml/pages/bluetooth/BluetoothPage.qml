import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices (top page, Win11 24H2): Bluetooth toggle, device tiles, then one card per sub page
SettingsPage {
    id: page
    property string pageTitle: "Bluetooth & devices"
    property var items: []
    crumbs: [pageTitle]

    property string removeMac: ""
    property string removeName: ""

    Component.onCompleted: Backend.refreshBluetoothDevices()
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
        icon: "fl:bluetooth_20_regular"
        title: "Bluetooth"
        description: !Backend.bluetoothAvailable ? "No Bluetooth adapter found"
                     : Backend.bluetoothOn ? "Discoverable as \"" + Backend.hostname + "\"" : "Off"
        FluentToggle {
            enabled: Backend.bluetoothAvailable
            checked: Backend.bluetoothOn
            onToggled: (c) => { Backend.setBluetooth(c); Backend.refreshBluetoothDevices() }
        }
    }

    // ---- device tiles
    Flow {
        id: tiles
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        spacing: 4

        Rectangle {
            id: addTile
            width: 172
            height: 120
            radius: Theme.radius
            enabled: Backend.bluetoothOn
            opacity: enabled ? 1 : 0.5
            color: addMa.pressed ? Theme.cardBgPressed : addMa.containsMouse ? Theme.cardBgHover : Theme.cardBg
            Behavior on color { ColorAnimation { duration: Theme.durFaster } }
            border.color: Theme.cardBorder
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                Icon { name: "fl:add_20_regular"; size: 32; Layout.alignment: Qt.AlignHCenter }
                FText { text: "Add device"; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
            }
            MouseArea {
                id: addMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: addDialog.open()
            }
        }
        Repeater {
            model: Backend.bluetoothOn ? Backend.bluetoothDevices.slice(0, 7) : []
            delegate: BtDeviceTile {
                required property var modelData
                device: modelData
                onRemoveRequested: (mac, name) => { page.removeMac = mac; page.removeName = name; removeDialog.open() }
            }
        }
    }

    Repeater {
        model: page.items
        delegate: SettingsCard {
            required property var modelData
            icon: modelData.icon || ""
            title: modelData.title
            description: modelData.desc || ""
            clickable: true
            onClicked: Router.activate(modelData)
        }
    }
}
