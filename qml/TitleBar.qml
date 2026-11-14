import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import "."

// Custom Win11 title bar: back arrow, "Settings", min / max / close
Item {
    id: bar
    property var window
    property bool canGoBack: false
    signal backClicked()
    implicitHeight: 48

    function toggleMax() {
        if (window.visibility === Window.Maximized) window.showNormal()
        else window.showMaximized()
    }

    DragHandler {
        target: null
        onActiveChanged: if (active) bar.window.startSystemMove()
    }
    TapHandler {
        onDoubleTapped: bar.toggleMax()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        CaptionButton {
            Layout.leftMargin: 4
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 40
            implicitHeight: 36
            radius: Theme.radius
            glyphSize: 14
            lines: Theme.gBack
            enabled: bar.canGoBack
            onClicked: bar.backClicked()
        }
        FText {
            text: "Settings"
            font.pixelSize: Theme.fontCaption
            Layout.leftMargin: 10
        }
        Item { Layout.fillWidth: true }
        CaptionButton {
            Layout.alignment: Qt.AlignTop
            lines: Theme.gMinimize
            onClicked: bar.window.showMinimized()
        }
        CaptionButton {
            Layout.alignment: Qt.AlignTop
            lines: bar.window && bar.window.visibility === Window.Maximized ? Theme.gRestore : Theme.gMaximize
            onClicked: bar.toggleMax()
        }
        CaptionButton {
            Layout.alignment: Qt.AlignTop
            isClose: true
            lines: Theme.gClose
            topRightRadius: bar.window && bar.window.cornerRadius ? bar.window.cornerRadius : 0
            onClicked: bar.window.close()
        }
    }
}
