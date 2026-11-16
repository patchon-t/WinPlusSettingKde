import QtQuick
import QtQuick.Layouts
import "."

// A sub-row inside ExpanderCard (indented, divider on top)
Item {
    id: r
    opacity: enabled ? 1 : 0.5
    property string title
    property string description
    property bool divider: true
    default property alias trailing: tr.data

    Layout.fillWidth: true
    implicitHeight: Math.max(description.length ? 64 : 52, rl.implicitHeight + 16)

    Rectangle {
        visible: r.divider
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Theme.divider
    }
    RowLayout {
        id: rl
        anchors.fill: parent
        anchors.leftMargin: 56
        anchors.rightMargin: 48
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
            }
        }
        RowLayout { id: tr; spacing: 12 }
    }
}
