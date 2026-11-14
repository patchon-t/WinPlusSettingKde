import QtQuick
import "."

// Icon via the Python image provider.
//   "fl:desktop_20_regular"          bundled Fluent icon, follows light/dark
//   "fl:bluetooth_20_filled@0078d4"  bundled Fluent icon with a fixed tint
//   "video-display|monitor"          system icon theme (fallback chain)
Image {
    property string name
    property int size: 16
    width: size
    height: size
    implicitWidth: size      // without these, Layouts use the image's
    implicitHeight: size     // native size -> giant icons
    sourceSize: Qt.size(size * 2, size * 2)
    source: name.length ? "image://icon/" + name + "?" + (Theme.dark ? "d" : "l") : ""
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    cache: false
}
