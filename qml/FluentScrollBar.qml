import QtQuick
import QtQuick.Controls
import "."

ScrollBar {
    id: sb
    padding: 2
    implicitWidth: (hovered || pressed) ? 10 : 6
    policy: ScrollBar.AsNeeded
    contentItem: Rectangle {
        radius: width / 2
        color: Theme.textSecondary
        opacity: sb.size < 1.0 ? ((sb.hovered || sb.pressed) ? 0.8 : 0.5) : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
    background: Item {}
    Behavior on implicitWidth { NumberAnimation { duration: 120 } }
}
