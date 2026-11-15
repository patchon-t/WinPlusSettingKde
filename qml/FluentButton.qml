import QtQuick
import QtQuick.Controls
import "."

Button {
    id: b
    property bool accent: false
    implicitHeight: 32
    leftPadding: 12
    rightPadding: 12
    font.pixelSize: Theme.fontBody

    contentItem: FText {
        text: b.text
        horizontalAlignment: Text.AlignHCenter
        color: b.accent ? Theme.textOnAccent : (b.enabled ? Theme.text : Theme.textDisabled)
        opacity: b.pressed && !b.accent ? 0.8 : 1
    }
    background: Rectangle {
        implicitWidth: 96
        radius: Theme.radius
        color: b.accent
               ? (b.pressed ? Theme.accentPressed : b.hovered ? Theme.accentHover : Theme.accent)
               : (!b.enabled ? Theme.controlBgDisabled : b.pressed ? Theme.controlBgPressed
                  : b.hovered ? Theme.controlBgHover : Theme.controlBg)
        Behavior on color { ColorAnimation { duration: Theme.durFaster } }
        border.color: b.accent ? "transparent" : Theme.controlBorder
        Rectangle {  // Fluent "elevation" bottom edge
            visible: !b.accent && !Theme.dark && !b.pressed
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.radius
            anchors.rightMargin: Theme.radius
            height: 1
            color: Theme.controlBorderBottom
        }
    }
}
