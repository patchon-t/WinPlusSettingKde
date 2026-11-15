import QtQuick
import QtQuick.Layouts
import "../.."

// Sub-row for an ExpanderCard that opens another page (title, description, chevron).
Item {
    id: r
    property string title
    property string description
    property bool divider: true
    default property alias trailing: tr.data
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(description.length ? 64 : 52, rl.implicitHeight + 16)
    opacity: enabled ? 1 : 0.5

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: r.divider ? 1 : 0
        color: ma.pressed ? Theme.subtlePressed : ma.containsMouse ? Theme.subtleHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durFaster } }
    }
    Rectangle {
        visible: r.divider
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Theme.divider
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: r.clicked()
    }
    RowLayout {
        id: rl
        anchors.fill: parent
        anchors.leftMargin: 56
        anchors.rightMargin: 24
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            FText { text: r.title; Layout.fillWidth: true; elide: Text.ElideRight }
            FText {
                text: r.description
                visible: text.length > 0
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
        RowLayout { id: tr; spacing: 12 }
        Glyph { lines: Theme.gChevronRight; width: 14; height: 14 }
    }
}
