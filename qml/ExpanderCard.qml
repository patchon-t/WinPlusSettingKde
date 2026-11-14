import QtQuick
import QtQuick.Layouts
import "."

// Win11 SettingsExpander: header card + collapsible body
ColumnLayout {
    id: ex
    property string icon
    property string title
    property string description
    property bool expanded: false
    property alias headerControls: hdrRow.data
    default property alias content: body.data

    Layout.fillWidth: true
    spacing: 0

    Rectangle {
        id: header
        Layout.fillWidth: true
        implicitHeight: Math.max(ex.description.length ? 68 : 56, hrow.implicitHeight + 24)
        radius: Theme.radius
        color: hma.pressed ? Theme.cardBgPressed : hma.containsMouse ? Theme.cardBgHover : Theme.cardBg
        border.color: Theme.cardBorder

        // square the bottom corners while open so header + body join
        Item {
            visible: ex.expanded
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.radius
            Rectangle { anchors.fill: parent; color: header.color }
            Rectangle { width: 1; height: parent.height; color: Theme.cardBorder }
            Rectangle { width: 1; height: parent.height; color: Theme.cardBorder; anchors.right: parent.right }
        }

        MouseArea {
            id: hma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: ex.expanded = !ex.expanded
        }

        RowLayout {
            id: hrow
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 8
            spacing: 0
            Icon {
                name: ex.icon
                size: 20
                visible: ex.icon.length > 0
                Layout.rightMargin: 20
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                FText { text: ex.title; Layout.fillWidth: true; elide: Text.ElideRight }
                FText {
                    text: ex.description
                    visible: text.length > 0
                    font.pixelSize: Theme.fontCaption
                    color: Theme.textSecondary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            RowLayout { id: hdrRow; spacing: 12; Layout.leftMargin: 12 }
            Rectangle {
                Layout.leftMargin: 8
                implicitWidth: 32
                implicitHeight: 32
                radius: Theme.radius
                color: chevMa.containsMouse ? Theme.subtleHover : "transparent"
                Glyph {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    lines: Theme.gChevronDown
                    rotation: ex.expanded ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: 167; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    id: chevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: ex.expanded = !ex.expanded
                }
            }
        }
    }

    Rectangle {
        id: bodyBox
        Layout.fillWidth: true
        implicitHeight: ex.expanded ? body.implicitHeight : 0
        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        visible: implicitHeight > 0
        clip: true
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder

        Item {  // square the top corners
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Theme.radius
            Rectangle { anchors.fill: parent; color: bodyBox.color }
            Rectangle { width: 1; height: parent.height; color: Theme.cardBorder }
            Rectangle { width: 1; height: parent.height; color: Theme.cardBorder; anchors.right: parent.right }
        }

        ColumnLayout {
            id: body
            width: parent.width
            spacing: 0
        }
    }
}
