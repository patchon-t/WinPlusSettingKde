import QtQuick
import QtQuick.Shapes
import "../.."

// Win11 indeterminate ProgressRing
Item {
    id: ring
    property int size: 48
    property bool running: true
    width: size
    height: size
    visible: running

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        ShapePath {
            strokeColor: Theme.accent
            strokeWidth: Math.max(3, ring.size / 12)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.size / 2
                centerY: ring.size / 2
                radiusX: ring.size / 2 - Math.max(3, ring.size / 12)
                radiusY: radiusX
                startAngle: -90
                sweepAngle: 270
            }
        }
        RotationAnimation on rotation {
            running: ring.running && ring.visible
            from: 0
            to: 360
            duration: 1100
            loops: Animation.Infinite
        }
    }
}
