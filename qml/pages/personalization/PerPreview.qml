import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Desktop preview used at the top of Personalization pages
Rectangle {
    id: pv
    property url source: Backend.wallpaperUrl
    property color backdrop: "transparent"
    implicitWidth: 268
    implicitHeight: 160
    radius: Theme.radiusLarge
    color: "#111111"

    Item {
        anchors.fill: parent
        anchors.margins: 6
        clip: true
        Rectangle { anchors.fill: parent; color: pv.backdrop }
        Image {
            anchors.fill: parent
            source: pv.source
            sourceSize.width: 540
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Rectangle {  // sample window
            width: parent.width * 0.42
            height: parent.height * 0.55
            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.1
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -6
            radius: 3
            color: Theme.cardBg
            Column {
                x: 10
                y: 12
                spacing: 6
                Repeater {
                    model: [60, 50, 60, 36]
                    Rectangle { required property int modelData; width: modelData; height: 2; color: Theme.textSecondary; opacity: 0.6 }
                }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
                width: 20
                height: 7
                radius: 2
                color: Theme.accent
            }
        }
        Rectangle {  // taskbar
            anchors.bottom: parent.bottom
            width: parent.width
            height: 14
            color: Theme.dark ? "#d0202020" : "#d0f3f3f3"
            Row {
                anchors.centerIn: parent
                spacing: 5
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        width: 7; height: 7; radius: 1.5
                        color: index === 0 ? Theme.accent : Theme.textSecondary
                        opacity: index === 0 ? 1 : 0.6
                    }
                }
            }
        }
    }
}
