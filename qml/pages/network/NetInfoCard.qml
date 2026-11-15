import QtQuick
import QtQuick.Layouts
import "../.."

// Read-only [label ..... value] rows in one card (section-local).
Rectangle {
    id: c
    property var rows: []        // [{label, value}]
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight
    radius: Theme.radius
    color: Theme.cardBg
    border.color: Theme.cardBorder

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 0
        Repeater {
            model: c.rows
            delegate: Item {
                id: r
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: Math.max(44, rl.implicitHeight + 20)
                Rectangle { visible: r.index > 0; width: parent.width; height: 1; color: Theme.divider }
                RowLayout {
                    id: rl
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 16
                    FText { text: r.modelData.label; Layout.preferredWidth: 220; elide: Text.ElideRight }
                    FText {
                        text: r.modelData.value.length ? r.modelData.value : "—"
                        color: Theme.textSecondary
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }
}
