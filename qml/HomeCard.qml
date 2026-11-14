import QtQuick
import QtQuick.Layouts
import "."

// Big rounded card used on the Home page
Rectangle {
    id: hc
    property string title
    property string subtitle
    property string icon
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight
    radius: Theme.radiusLarge
    color: Theme.cardBg
    border.color: Theme.cardBorder

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 0
        Icon {
            visible: hc.icon.length > 0
            name: hc.icon
            size: 28
            Layout.leftMargin: 18
            Layout.topMargin: 20
        }
        FText {
            text: hc.title
            font.pixelSize: Theme.fontSubtitle
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            Layout.topMargin: hc.icon.length ? 12 : 22
        }
        FText {
            visible: hc.subtitle.length > 0
            text: hc.subtitle
            font.pixelSize: 13
            color: Theme.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            Layout.topMargin: 8
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.topMargin: 16
            spacing: 0
        }
    }
}
