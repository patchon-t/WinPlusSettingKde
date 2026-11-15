import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Network & internet", "Mobile hotspot"]

    readonly property var bands: ["Any available", "5 GHz", "2.4 GHz"]

    Component.onCompleted: { Backend.refreshHotspot(); Backend.refreshWifi(); Backend.refreshNetDevices() }

    NetToast {}

    SettingsCard {
        icon: "fl:phone_laptop_20_regular"
        title: "Mobile hotspot"
        description: "Share your internet connection with other devices over Wi-Fi"
        enabled: Backend.wifiEnabled
        FluentToggle {
            checked: Backend.hotspotOn
            enabled: !Backend.netBusy
            onToggled: (v) => Backend.setHotspot(v)
        }
    }

    FText {
        text: "The hotspot uses your Wi-Fi adapter, so connect to the internet another way, for example with Ethernet."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.topMargin: 4
    }

    SectionHeader { text: "Properties" }

    SettingsCard {
        icon: "fl:edit_20_regular"
        title: "Edit network name, password and band"
        description: "Changes restart the hotspot if it is on"
        FluentButton { text: "Edit"; onClicked: editDlg.openFor() }
    }

    NetInfoCard {
        rows: [
            { label: "Network name", value: Backend.hotspotName },
            { label: "Network password", value: Backend.hotspotPassword },
            { label: "Network band", value: page.bands[Backend.hotspotBand] || page.bands[0] }
        ]
    }

    NetFormDialog {
        id: editDlg
        title: "Edit properties"
        acceptText: "Save"
        function openFor() {
            nameField.text = Backend.hotspotName
            pwdField.text = Backend.hotspotPassword
            bandBox.currentIndex = Backend.hotspotBand
            error = ""
            open()
        }
        onConfirmed: {
            const err = Backend.netValidateHotspot(nameField.text, pwdField.text)
            if (err.length) { error = err; return }
            Backend.applyHotspotProperties(nameField.text, pwdField.text, bandBox.currentIndex)
            close()
        }
        NetField { id: nameField; label: "Network name" }
        NetField { id: pwdField; label: "Network password (8 to 63 characters)" }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            FText { text: "Network band"; font.pixelSize: Theme.fontCaption }
            FluentCombo {
                id: bandBox
                model: page.bands
                Layout.fillWidth: true
                onActivated: (i) => currentIndex = i
            }
        }
    }
}
