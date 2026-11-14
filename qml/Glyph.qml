import QtQuick
import QtQuick.Shapes
import "."

// Crisp vector glyph. lines = list of polylines on a 16x16 grid (see Theme.g*).
Shape {
    id: g
    property var lines: []
    property color color: Theme.text
    property real stroke: 1
    width: 16
    height: 16
    layer.enabled: true
    layer.samples: 4

    ShapePath {
        strokeColor: g.color
        strokeWidth: g.stroke
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathMultiline {
            paths: g.lines.map(l => l.map(p => Qt.point(p[0] * g.width / 16, p[1] * g.height / 16)))
        }
    }
}
