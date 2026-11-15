import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Network & internet", "Advanced network settings", "Network reset"]

    NetToast {}

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: info.implicitHeight + 40
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        ColumnLayout {
            id: info
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8
            FText { text: "Network reset"; font.weight: Font.DemiBold }
            FText {
                text: "This turns networking off and on again, which disconnects and restarts every connection. "
                      + "Your saved networks, passwords and settings are kept. You may need to reconnect to Wi-Fi afterwards."
                color: Theme.textSecondary
                font.pixelSize: Theme.fontCaption
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    SettingsCard {
        icon: "fl:arrow_reset_20_regular"
        title: "Reset now"
        FluentButton { text: "Reset now"; onClicked: confirm.open() }
    }

    NetFormDialog {
        id: confirm
        title: "Are you sure you want to reset your network settings?"
        message: "Networking will restart. You'll be briefly disconnected."
        acceptText: "Yes"
        onConfirmed: { Backend.netReset(); close() }
    }
}
