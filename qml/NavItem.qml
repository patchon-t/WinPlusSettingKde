import QtQuick
import "."

Item {
    id: root
    property string icon
    property string text
    property bool selected: false
    signal clicked()
    implicitHeight: 36

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: ma.pressed ? Theme.subtlePressed
               : (root.selected || ma.containsMouse) ? Theme.subtleHover : "transparent"
    }
    Rectangle {  // accent pill
        width: 3
        radius: 1.5
        height: root.selected ? (ma.pressed ? 10 : 16) : 0
        visible: height > 0
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.accent
        Behavior on height { NumberAnimation { duration: 167; easing.type: Easing.OutCubic } }
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
