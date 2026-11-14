import QtQuick
import "."

// Win11 ToggleSwitch. Controlled: emits toggled(newValue), parent updates `checked`.
Item {
    id: t
    property bool checked: false
    property bool showLabel: true
    property string onText: "On"
    property string offText: "Off"
    signal toggled(bool checked)

    implicitWidth: 40 + (showLabel ? 40 : 0)
    implicitHeight: 32
    opacity: enabled ? 1 : 0.5

    FText {
        visible: t.showLabel
        text: t.checked ? t.onText : t.offText
        anchors.right: track.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        id: track
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 20
        radius: 10
        color: t.checked
               ? (ma.pressed ? Theme.accentPressed : ma.containsMouse ? Theme.accentHover : Theme.accent)
               : (ma.pressed ? Theme.subtlePressed : ma.containsMouse ? Theme.subtleHover : Theme.toggleOffBg)
        border.width: t.checked ? 0 : 1
        border.color: Theme.strongStroke

        Rectangle {
            readonly property real s: (ma.containsMouse || ma.pressed) ? 14 : 12
            width: ma.pressed ? 17 : s
            height: s
            radius: s / 2
            anchors.verticalCenter: parent.verticalCenter
            x: t.checked ? parent.width - width - (parent.height - height) / 2
                         : (parent.height - height) / 2
            color: t.checked ? Theme.onAccent : Theme.textSecondary
            Behavior on x { NumberAnimation { duration: 167; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 120 } }
            Behavior on height { NumberAnimation { duration: 120 } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: t.toggled(!t.checked)
    }
}
