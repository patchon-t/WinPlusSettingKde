import QtQuick
import QtQuick.Effects
import "."

// Rounded flyout surface with a soft shadow (popups, combo lists)
Item {
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.flyoutBg
        border.color: Theme.flyoutBorder
    }
    MultiEffect {
        anchors.fill: surface
        source: surface
        z: -1
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, Theme.dark ? 0.55 : 0.2)
        shadowBlur: 0.9
        shadowVerticalOffset: 6
        autoPaddingEnabled: true
    }
}
