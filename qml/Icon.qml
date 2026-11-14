import QtQuick
import QtQuick.Layouts
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
    // Image's implicitWidth/Height are read-only, so tell Layouts the size here
    Layout.preferredWidth: size
    Layout.preferredHeight: size
    sourceSize: Qt.size(size * 2, size * 2)
    source: name.length ? "image://icon/" + name + "?" + (Theme.dark ? "d" : "l") : ""
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    cache: false
}
