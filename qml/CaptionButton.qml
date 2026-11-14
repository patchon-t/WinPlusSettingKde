import QtQuick
import "."

Rectangle {
    id: b
    property var lines: []
    property bool isClose: false
    property real glyphSize: 10
    signal clicked()

    implicitWidth: 46
    implicitHeight: 32
    color: !enabled ? "transparent"
           : ma.pressed ? (isClose ? Qt.rgba(0.77, 0.17, 0.11, 0.9) : Theme.subtlePressed)
           : ma.containsMouse ? (isClose ? "#c42b1c" : Theme.subtleHover) : "transparent"

    Glyph {
        anchors.centerIn: parent
        width: b.glyphSize
        height: b.glyphSize
        lines: b.lines
        color: b.isClose && ma.containsMouse ? "#ffffff" : (b.enabled ? Theme.text : Theme.textDisabled)
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: b.clicked()
    }
}
