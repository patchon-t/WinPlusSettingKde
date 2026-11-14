import QtQuick
import "."

FText {
    id: l
    signal clicked()
    font.pixelSize: Theme.fontCaption
    color: ma.pressed ? Qt.darker(Theme.accentText, 1.2) : Theme.accentText
    font.underline: ma.containsMouse
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: l.clicked()
    }
}
