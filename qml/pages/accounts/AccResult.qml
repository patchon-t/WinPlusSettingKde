import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 InfoBar: shows the outcome of the last account change, then fades.
Rectangle {
    id: bar
    property string message
    property bool good: true
    Layout.fillWidth: true
    implicitHeight: 48
    visible: message.length > 0
    radius: Theme.radius
    color: Theme.cardBg
    border.color: Theme.cardBorder

    Connections {
        target: Backend
        function onAccOpFinished(ok, msg) {
            bar.good = ok
            bar.message = msg
            hide.restart()
        }
    }
    Timer { id: hide; interval: 7000; onTriggered: bar.message = "" }

    Rectangle {
        width: 4; height: 20; radius: 2
        x: 0; anchors.verticalCenter: parent.verticalCenter
        color: bar.good ? "#2e9c3c" : "#d13438"
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 8
        spacing: 12
        Rectangle {
            Layout.preferredWidth: 18; Layout.preferredHeight: 18; radius: 9
            color: bar.good ? "#2e9c3c" : "#d13438"
            Glyph {
                anchors.centerIn: parent
                width: 10; height: 10
                lines: bar.good ? Theme.gCheck : Theme.gClose
                color: "#ffffff"
            }
        }
        FText { text: bar.message; Layout.fillWidth: true; elide: Text.ElideRight }
        IconButton { icon: "fl:dismiss_20_regular"; iconSize: 14; onClicked: bar.message = "" }
    }
}
