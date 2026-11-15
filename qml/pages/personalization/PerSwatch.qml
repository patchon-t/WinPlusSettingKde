import QtQuick
import "../.."

// Color swatch with check badge (accent palette, solid background colors)
Rectangle {
    id: sw
    property string swatchColor
    property string selectedColor
    readonly property bool selected: swatchColor.toLowerCase() === selectedColor.toLowerCase()
    signal picked(string color)
    implicitWidth: 40
    implicitHeight: 40
    radius: Theme.radius
    color: "transparent"
    border.width: selected || sma.containsMouse ? 2 : 0
    border.color: Theme.text

    Rectangle {
        anchors.fill: parent
        anchors.margins: sw.selected || sma.containsMouse ? 3 : 0
        radius: 2
        color: sw.swatchColor
    }
    Rectangle {  // check badge
        visible: sw.selected
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 3
        width: 16
        height: 16
        radius: 2
        color: Theme.text
        Glyph {
            anchors.centerIn: parent
            width: 12
            height: 12
            lines: Theme.gCheck
            color: Theme.windowBg
            stroke: 1.5
        }
    }
    MouseArea {
        id: sma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: sw.picked(sw.swatchColor)
    }
}
