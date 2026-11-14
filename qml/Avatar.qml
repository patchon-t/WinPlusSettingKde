import QtQuick
import QtQuick.Effects
import WinSettings
import "."

Item {
    id: av
    property int size: 60
    property string source: Backend.avatar
    implicitWidth: size
    implicitHeight: size

    Rectangle {  // default "person" avatar
        anchors.fill: parent
        radius: width / 2
        color: Theme.dark ? "#3c3c3c" : "#d9d9d9"
        visible: img.status !== Image.Ready
        Icon {
            anchors.centerIn: parent
            name: "user-identity|im-user|avatar-default"
            size: Math.round(av.size * 0.5)
        }
    }
    Image {
        id: img
        anchors.fill: parent
        source: av.source
        sourceSize: Qt.size(av.size * 2, av.size * 2)
        fillMode: Image.PreserveAspectCrop
        visible: false
        layer.enabled: true
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: width / 2
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        visible: img.status === Image.Ready
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
