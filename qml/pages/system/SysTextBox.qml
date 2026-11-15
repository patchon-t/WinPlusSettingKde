import QtQuick
import QtQuick.Controls
import "../.."

// Win11 TextBox (single line)
TextField {
    id: field
    implicitHeight: 32
    implicitWidth: 160
    color: Theme.text
    placeholderTextColor: Theme.textSecondary
    font.pixelSize: Theme.fontBody
    leftPadding: 11
    selectByMouse: true
    opacity: enabled ? 1 : 0.5
    background: Rectangle {
        radius: Theme.radius
        color: field.activeFocus ? Theme.controlBgFocus : Theme.controlBg
        border.color: Theme.controlBorder
        clip: true
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: field.activeFocus ? 2 : 1
            color: field.activeFocus ? Theme.accent : Theme.controlBorderBottom
        }
    }
}
