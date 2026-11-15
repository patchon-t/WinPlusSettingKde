import QtQuick
import "../.."

// Theme / picture thumbnail tile with selection ring
Item {
    id: t
    property url source
    property string label
    property bool selected: false
    property int thumbWidth: 112
    property int thumbHeight: 68
    signal clicked()
    implicitWidth: thumbWidth
    implicitHeight: thumbHeight + (label.length ? 24 : 0)

    Rectangle {
        id: frame
        width: t.thumbWidth
        height: t.thumbHeight
        radius: Theme.radius + 2
        color: Theme.monitorIdle
        border.width: t.selected || ma.containsMouse ? 2 : 1
        border.color: t.selected ? Theme.accent : (ma.containsMouse ? Theme.strongStroke : Theme.cardBorder)
        Behavior on border.color { ColorAnimation { duration: Theme.durFaster } }
        clip: true
        Image {
            anchors.fill: parent
            anchors.margins: 2
            source: t.source
            sourceSize.width: t.thumbWidth * 2
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
    FText {
        visible: t.label.length > 0
        anchors.top: frame.bottom
        anchors.topMargin: 4
        width: t.thumbWidth
        text: t.label
        font.pixelSize: Theme.fontCaption
        color: t.selected ? Theme.text : Theme.textSecondary
        elide: Text.ElideRight
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: t.clicked()
    }
}
