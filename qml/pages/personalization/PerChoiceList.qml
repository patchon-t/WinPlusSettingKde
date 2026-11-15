import QtQuick
import QtQuick.Layouts
import "../.."

// Vertical list of selectable rows (Plasma style, icons, cursors...).
// items: [{ id, name, preview? }]
ColumnLayout {
    id: list
    property var items: []
    property string current
    property string emptyText: "Nothing found"
    signal picked(string themeId)
    Layout.fillWidth: true
    spacing: 4

    FText {
        visible: list.items.length === 0
        text: list.emptyText
        color: Theme.textSecondary
        Layout.topMargin: 8
    }

    Repeater {
        model: list.items
        delegate: Rectangle {
            id: row
            required property var modelData
            readonly property bool selected: modelData.id === list.current
            Layout.fillWidth: true
            implicitHeight: 48
            radius: Theme.radius
            color: rma.pressed ? Theme.cardBgPressed : rma.containsMouse ? Theme.cardBgHover : Theme.cardBg
            Behavior on color { ColorAnimation { duration: Theme.durFaster } }
            border.color: Theme.cardBorder

            Rectangle {
                visible: row.selected
                width: 3
                height: 16
                radius: 1.5
                color: Theme.accent
                x: 4
                anchors.verticalCenter: parent.verticalCenter
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12
                Image {
                    visible: !!row.modelData.preview
                    source: row.modelData.preview || ""
                    sourceSize.height: 64
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: 52
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                FText { text: row.modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
                Glyph {
                    visible: row.selected
                    lines: Theme.gCheck
                    width: 14
                    height: 14
                    color: Theme.accent
                    stroke: 1.5
                }
            }
            MouseArea {
                id: rma
                anchors.fill: parent
                hoverEnabled: true
                onClicked: list.picked(row.modelData.id)
            }
        }
    }
}
