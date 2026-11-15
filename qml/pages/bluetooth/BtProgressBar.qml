import QtQuick
import "../.."

// Win11 indeterminate ProgressBar (thin accent bar sliding across)
Item {
    id: pb
    property bool running: true
    implicitHeight: 4
    clip: true
    opacity: running ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

    Rectangle { anchors.fill: parent; radius: 2; color: Theme.sliderTrack; opacity: 0.35 }
    Rectangle {
        id: bar
        height: parent.height
        width: parent.width * 0.35
        radius: 2
        color: Theme.accent
        SequentialAnimation on x {
            running: pb.running && pb.visible
            loops: Animation.Infinite
            NumberAnimation { from: -bar.width; to: pb.width; duration: 1400
                easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard }
        }
    }
}
