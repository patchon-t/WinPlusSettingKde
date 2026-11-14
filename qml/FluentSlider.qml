import QtQuick
import QtQuick.Controls
import "."

Slider {
    id: s
    implicitWidth: 200
    implicitHeight: 32
    opacity: enabled ? 1 : 0.5

    background: Rectangle {
        x: s.leftPadding
        y: s.topPadding + s.availableHeight / 2 - height / 2
        width: s.availableWidth
        height: 4
        radius: 2
        color: Theme.sliderTrack
        Rectangle {
            width: s.visualPosition * parent.width
            height: parent.height
            radius: 2
            color: Theme.accent
        }
    }
    handle: Rectangle {
        x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
        y: s.topPadding + s.availableHeight / 2 - height / 2
        width: 20
        height: 20
        radius: 10
        color: Theme.controlBgSolid
        border.color: Theme.controlBorder
        Rectangle {
            anchors.centerIn: parent
            width: s.pressed ? 10 : s.hovered ? 14 : 12
            height: width
            radius: width / 2
            color: Theme.accent
            Behavior on width { NumberAnimation { duration: 100 } }
        }
    }
}
