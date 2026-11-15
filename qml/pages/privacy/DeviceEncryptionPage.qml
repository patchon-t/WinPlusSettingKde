import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Read-only LUKS status from lsblk
SettingsPage {
    id: page
    crumbs: ["Privacy & security", "Device encryption"]

    Component.onCompleted: Backend.refreshPrvEncryption()

    PrvInfoBar {
        title: Backend.prvEncRoot === 1 ? "Your system drive is encrypted"
               : Backend.prvEncRoot === 0 ? "Your system drive is not encrypted"
               : Backend.prvEncLoaded ? "Couldn't determine the encryption state of your system drive" : "Checking drives..."
        severity: Backend.prvEncRoot === 1 ? "success" : Backend.prvEncRoot === 0 ? "warning" : "info"
        message: "This page only shows status. Drives are encrypted with LUKS when the system is installed or with cryptsetup."
    }

    SectionHeader { text: "Drives" }

    Repeater {
        model: Backend.prvEncDevices
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:storage_20_regular"
            title: "/dev/" + modelData.name
            description: modelData.size
            FText {
                text: modelData.encrypted ? "Encrypted" : "Not encrypted"
                color: modelData.encrypted ? Theme.text : Theme.textSecondary
            }
            Icon {
                name: modelData.encrypted ? "fl:lock_closed_20_regular" : "fl:warning_20_regular"
                size: 20
            }
        }
    }

    FText {
        visible: Backend.prvEncLoaded && Backend.prvEncDevices.length === 0
        text: "No drives were found."
        color: Theme.textSecondary
        Layout.topMargin: 8
        Layout.alignment: Qt.AlignHCenter
    }
}
