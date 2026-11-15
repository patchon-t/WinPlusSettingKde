import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 Accounts header: big picture, name, e-mail / local account, account type
RowLayout {
    id: h
    property int pictureSize: 72
    Layout.fillWidth: true
    Layout.bottomMargin: 12
    spacing: 20

    Avatar { size: h.pictureSize }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        FText {
            text: Backend.userName
            font.pixelSize: Theme.fontSubtitle
            font.weight: Font.DemiBold
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        FText {
            text: Backend.userEmail.length ? Backend.userEmail : Backend.userLogin
            color: Theme.textSecondary
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        FText {
            text: Backend.accountTypeText
            font.pixelSize: Theme.fontCaption
            color: Theme.textSecondary
        }
    }
}
