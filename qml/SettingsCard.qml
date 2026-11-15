import QtQuick
import QtQuick.Layouts
import "."

// The workhorse row: [icon] Title / description ........ [controls] [>]
Rectangle {
    id: card
    property string icon
    property string title
    property string description
    property bool clickable: false
    property bool chevron: clickable
    default property alias trailing: trailingRow.data
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(description.length ? 68 : 56, row.implicitHeight + 24)
    radius: Theme.radius
    color: clickable && ma.pressed ? Theme.cardBgPressed
           : clickable && ma.containsMouse ? Theme.cardBgHover : Theme.cardBg
    Behavior on color { ColorAnimation { duration: Theme.durFaster } }
    border.color: Theme.cardBorder
    opacity: enabled ? 1 : 0.5

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: card.clickable
        onClicked: card.clicked()
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 0

        Icon {
            name: card.icon
            size: 20
            visible: card.icon.length > 0
            Layout.rightMargin: 20
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            FText {
                text: card.title
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            FText {
                text: card.description
                visible: text.length > 0
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
        RowLayout {
            id: trailingRow
            spacing: 12
            Layout.leftMargin: 12
        }
        Glyph {
            visible: card.chevron
            lines: Theme.gChevronRight
            width: 14
            height: 14
            Layout.leftMargin: 16
        }
    }
}
