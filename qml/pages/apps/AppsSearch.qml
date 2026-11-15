import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."

// Win11 search box: text field with a magnifier on the right
TextField {
    id: f
    implicitHeight: 32
    placeholderTextColor: Theme.textSecondary
    color: Theme.text
    font.pixelSize: Theme.fontBody
    leftPadding: 11
    rightPadding: 34
    selectByMouse: true
    selectionColor: Theme.accent
    background: Rectangle {
        radius: Theme.radius
        color: f.activeFocus ? Theme.controlBgFocus : f.hovered ? Theme.controlBgHover : Theme.controlBg
        Behavior on color { ColorAnimation { duration: Theme.durFaster } }
        border.color: Theme.controlBorder
        clip: true
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: f.activeFocus ? 2 : 1
            color: f.activeFocus ? Theme.accent : Theme.controlBorderBottom
        }
        Icon {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            name: "fl:search_20_regular"
            size: 14
            opacity: 0.8
        }
    }
}
