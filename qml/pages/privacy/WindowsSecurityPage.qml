import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Windows Security overview: only the areas Linux has are active.
SettingsPage {
    id: page
    crumbs: ["Privacy & security", "Windows Security"]

    Component.onCompleted: { Backend.refreshPrvFirewall(); Backend.refreshPrvEncryption() }

    readonly property bool fwOk: Backend.prvUfwInstalled && Backend.prvUfwEnabled

    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        implicitHeight: 96
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 20
            Icon { name: page.fwOk ? "fl:shield_checkmark_20_regular" : "fl:shield_error_20_regular"; size: 48 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                FText {
                    text: page.fwOk ? "Your device is being protected" : "Your device may need attention"
                    font.pixelSize: Theme.fontSubtitle
                    font.weight: Font.DemiBold
                }
                FText {
                    text: page.fwOk ? "The firewall is on." : (Backend.prvUfwInstalled ? "The firewall is off." : "The firewall (ufw) isn't installed.")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                }
            }
        }
    }

    SectionHeader { text: "Protection areas"; Layout.topMargin: 12 }

    SettingsCard {
        enabled: false
        icon: "fl:shield_20_regular"
        title: "Virus & threat protection"
        description: "Not available on Linux"
    }
    SettingsCard {
        enabled: false
        icon: "fl:person_20_regular"
        title: "Account protection"
        description: "Not available on Linux. Sign-in options are in Accounts."
    }
    SettingsCard {
        icon: "fl:fire_20_regular"
        title: "Firewall & network protection"
        description: !Backend.prvUfwInstalled ? "ufw isn't installed" : Backend.prvUfwEnabled ? "Firewall is on" : "Firewall is off"
        clickable: true
        onClicked: Router.open("pages/privacy/FirewallPage.qml", {})
    }
    SettingsCard {
        icon: "fl:laptop_shield_20_regular"
        title: "Device security"
        description: Backend.prvEncRoot === 1 ? "System drive is encrypted"
                     : Backend.prvEncRoot === 0 ? "System drive is not encrypted" : "Check drive encryption"
        clickable: true
        onClicked: Router.open("pages/privacy/DeviceEncryptionPage.qml", {})
    }
}
