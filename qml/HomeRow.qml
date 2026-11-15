import QtQuick
import QtQuick.Layouts
import "."

// Full-width row inside a HomeCard, divider on top
Item {
    id: r
    property string icon
    property string title
    property string subtitle
    property bool clickable: true
    property bool chevron: clickable
    default property alias trailing: tr.data
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: subtitle.length ? 62 : 52

    Rectangle { width: parent.width; height: 1; color: Theme.divider }
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 1
        color: r.clickable && ma.pressed ? Theme.subtlePressed
               : r.clickable && ma.containsMouse ? Theme.subtleHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durFaster } }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: r.clickable
        onClicked: r.clicked()
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 0
        Icon {
            name: r.icon
            size: 16
            visible: r.icon.length > 0
            Layout.rightMargin: 16
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            FText { text: r.title; Layout.fillWidth: true; elide: Text.ElideRight }
            FText {
                text: r.subtitle
                visible: text.length > 0
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
        RowLayout { id: tr; spacing: 12 }
        Glyph {
            visible: r.chevron
            lines: Theme.gChevronRight
            width: 14
            height: 14
            Layout.leftMargin: 12
        }
    }
}
