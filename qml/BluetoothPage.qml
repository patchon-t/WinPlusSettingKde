import QtQuick
import QtQuick.Layouts
import WinSettings
import "."

KcmListPage {
    id: page
    pageTitle: "Bluetooth & devices"
    listTitle: "Other devices & settings"

    Component.onCompleted: Backend.refreshBluetoothDevices()
    Timer { interval: 5000; repeat: true; running: true; onTriggered: Backend.refreshBluetoothDevices() }

    header: Component {
        ColumnLayout {
            spacing: 4

            // Big Bluetooth header card like Win11
            SettingsCard {
                icon: "fl:bluetooth_20_regular"
                title: "Bluetooth"
                description: !Backend.bluetoothAvailable ? "No Bluetooth adapter found"
                             : Backend.bluetoothOn ? "Discoverable as \"" + Backend.hostname + "\"" : "Off"
                FluentButton {
                    text: "Add device"
                    enabled: Backend.bluetoothOn
                    onClicked: Backend.runCommand(["bluedevil-wizard"])
                }
                FluentToggle {
                    enabled: Backend.bluetoothAvailable
                    checked: Backend.bluetoothOn
                    onToggled: (c) => { Backend.setBluetooth(c); Backend.refreshBluetoothDevices() }
                }
            }

            SectionHeader {
                text: "Devices"
                visible: Backend.bluetoothOn && Backend.bluetoothDevices.length > 0
            }
            Repeater {
                model: Backend.bluetoothOn ? Backend.bluetoothDevices : []
                delegate: SettingsCard {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: modelData.connected ? "fl:bluetooth_connected_20_regular" : "fl:headphones_20_regular"
                    title: modelData.name
                    description: modelData.connected ? "Connected" : "Paired"
                    FluentButton {
                        text: modelData.connected ? "Disconnect" : "Connect"
                        onClicked: modelData.connected ? Backend.bluetoothDisconnect(modelData.mac)
                                                       : Backend.bluetoothConnect(modelData.mac)
                    }
                    IconButton {
                        icon: "fl:delete_20_regular"
                        onClicked: Backend.bluetoothRemove(modelData.mac)
                    }
                }
            }
        }
    }
}
