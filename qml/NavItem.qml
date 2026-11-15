import QtQuick
import "."

Item {
    id: root
    property string icon
    property string text
    property bool selected: false
    readonly property bool pressed: ma.pressed   // NavPane shrinks the pill while pressed
    signal clicked()
    implicitHeight: 36

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: ma.pressed ? Theme.subtlePressed
               : (root.selected || ma.containsMouse) ? Theme.subtleHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durFaster } }
    }
    Icon {
        name: root.icon
        size: 16
        x: 16
        anchors.verticalCenter: parent.verticalCenter
    }
    FText {
        text: root.text
        x: 48
        width: parent.width - 56
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
