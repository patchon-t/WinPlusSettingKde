import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Network & internet", "Airplane mode"]

    Component.onCompleted: Backend.refreshAirplane()

    SettingsCard {
        icon: "fl:airplane_20_regular"
        title: "Airplane mode"
        description: "Stop all wireless communication"
        FluentToggle {
            checked: Backend.airplaneMode
            onToggled: (v) => Backend.setAirplaneMode(v)
        }
    }

    SectionHeader { text: "Wireless devices" }

    SettingsCard {
        icon: "fl:wifi_1_20_regular"
        title: "Wi-Fi"
        FluentToggle {
            checked: Backend.wifiEnabled
            onToggled: (v) => Backend.setWifiEnabled(v)
        }
    }

    SettingsCard {
        icon: "fl:bluetooth_20_regular"
        title: "Bluetooth"
        description: Backend.netBluetoothAvailable ? "" : "No Bluetooth adapter found"
        enabled: Backend.netBluetoothAvailable
        FluentToggle {
            checked: Backend.netBluetoothOn
            onToggled: (v) => Backend.netSetBluetooth(v)
        }
    }
}
