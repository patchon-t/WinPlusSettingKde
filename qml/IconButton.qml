import QtQuick
import "."

// Small square button with an icon (mute, refresh, delete...)
Rectangle {
    id: b
    property string icon
    property int iconSize: 16
    property string tooltip
    signal clicked()
    implicitWidth: 32
    implicitHeight: 32
    radius: Theme.radius
    color: ma.pressed ? Theme.subtlePressed : ma.containsMouse ? Theme.subtleHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.durFaster } }
    opacity: enabled ? 1 : 0.4
    Icon { anchors.centerIn: parent; name: b.icon; size: b.iconSize }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: b.clicked()
    }
}
