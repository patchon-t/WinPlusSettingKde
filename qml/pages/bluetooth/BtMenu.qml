import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."

// Win11 context flyout (the "..." menu on device cards). model = [{ text, icon, enabled }]
Popup {
    id: menu
    property var model: []
    signal chosen(int index)

    padding: 4
    margins: 8
    width: 220
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: FlyoutBackground {}
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durFaster }
        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Theme.durFast
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decelerate }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFaster }
    }

    contentItem: ColumnLayout {
        spacing: 2
        Repeater {
            model: menu.model
            delegate: Rectangle {
                id: item
                required property var modelData
                required property int index
                readonly property bool on: modelData.enabled !== false
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.radius
                color: !on ? "transparent" : ima.pressed ? Theme.subtlePressed : ima.containsMouse ? Theme.subtleHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durFaster } }
                opacity: on ? 1 : 0.5
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12
                    Icon { name: item.modelData.icon || ""; size: 16; visible: !!item.modelData.icon }
                    FText { text: item.modelData.text; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                MouseArea {
                    id: ima
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: item.on
                    onClicked: { menu.close(); menu.chosen(item.index) }
                }
            }
        }
    }
}
