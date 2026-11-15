import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Nearby sharing"]

    readonly property string saveUrl: {
        Backend.sysCfgRev
        return Backend.sysCfg("bluedevilreceiverrc", "General", "saveUrl", "")
    }
    readonly property string savePath: saveUrl.length ? decodeURIComponent(saveUrl.replace(/^file:\/\//, "")) : ""

    Component.onCompleted: { Backend.sysCfgReload(); Backend.sysRefreshNearby() }

    SettingsCard {
        icon: "fl:phone_laptop_20_regular"
        title: "Nearby sharing"
        description: Backend.sysKdeConnectAvailable
                     ? "Share files, links and text with devices paired through KDE Connect"
                     : "KDE Connect isn't installed, so sharing with phones and PCs isn't available"
        FluentButton {
            text: "Refresh"
            enabled: Backend.sysKdeConnectAvailable
            onClicked: Backend.sysNearbyRefresh()
        }
    }

    SettingsCard {
        icon: "fl:folder_20_regular"
        title: "Save files I receive to"
        description: "Where files received over Bluetooth are saved"
        SysTextBox {
            id: pathField
            implicitWidth: 280
            text: page.savePath
            onAccepted: Backend.sysCfgSet("bluedevilreceiverrc", "General", "saveUrl", "file://" + encodeURI(text), "")
        }
        FluentButton {
            text: "Apply"
            enabled: pathField.text.startsWith("/") && pathField.text !== page.savePath
            onClicked: Backend.sysCfgSet("bluedevilreceiverrc", "General", "saveUrl", "file://" + encodeURI(pathField.text), "")
        }
    }
    SettingsCard {
        enabled: false
        icon: "fl:laptop_20_color"
        title: "Rename your device"
        description: "Not available yet"
        FluentButton { text: "Rename" }
    }

    SectionHeader { text: "Paired devices" }
    FText {
        visible: Backend.sysKdeConnectAvailable && Backend.sysKdeConnectDevices.length === 0
        text: "No devices found. Pair a phone or PC in the KDE Connect app."
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
    }
    Repeater {
        model: Backend.sysKdeConnectDevices
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:phone_20_regular"
            title: modelData.name
            description: modelData.state
        }
    }
    SettingsCard {
        icon: "fl:bluetooth_20_regular"
        title: "Bluetooth & devices"
        description: "Pair a new device"
        clickable: true
        onClicked: Router.open("pages/bluetooth/BluetoothPage.qml", {})
    }
}
