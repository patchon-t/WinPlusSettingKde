import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."

// Win11 "..." flyout menu. entries: [{ text, icon, enabled }]
Popup {
    id: m
    property var entries: []
    signal chosen(int index)

    padding: 4
    width: 220
    y: parent ? parent.height + 2 : 0
    x: parent ? parent.width - width : 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: FlyoutBackground {}
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durFaster }
        NumberAnimation { property: "y"; from: (m.parent ? m.parent.height : 0) - 8; to: (m.parent ? m.parent.height : 0) + 2
            duration: Theme.durNormal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decelerate }
    }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFaster } }

    contentItem: ColumnLayout {
        spacing: 2
        Repeater {
            model: m.entries
            delegate: Rectangle {
                id: it
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.radius
                enabled: modelData.enabled !== false
                opacity: enabled ? 1 : 0.4
                color: ima.pressed ? Theme.subtlePressed : ima.containsMouse ? Theme.subtleHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durFaster } }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12
                    Icon { name: it.modelData.icon || ""; size: 16; visible: !!it.modelData.icon }
                    FText { text: it.modelData.text; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                MouseArea {
                    id: ima
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: { m.close(); m.chosen(it.index) }
                }
            }
        }
    }
}
