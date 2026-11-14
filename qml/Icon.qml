import QtQuick
import "."

// Theme icon via the Python image provider. name = "icon|fallback|fallback"
Image {
    property string name
    property int size: 16
    width: size
    height: size
    sourceSize: Qt.size(size * 2, size * 2)
    source: name.length ? "image://icon/" + name + "?" + (Theme.dark ? "d" : "l") : ""
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    cache: false
}
