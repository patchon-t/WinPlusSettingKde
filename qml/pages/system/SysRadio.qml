import QtQuick
import QtQuick.Layouts
import "../.."

// Win11 RadioButton row (circle + label). Controlled: emits clicked().
Item {
    id: r
    property bool checked: false
    property string text
    signal clicked()
    implicitHeight: 32
    implicitWidth: rl.implicitWidth
    opacity: enabled ? 1 : 0.5

    RowLayout {
        id: rl
        anchors.fill: parent
        spacing: 12
        Rectangle {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            radius: 10
            color: r.checked ? Theme.accent
                   : ma.pressed ? Theme.subtlePressed : ma.containsMouse ? Theme.subtleHover : Theme.toggleOffBg
            Behavior on color { ColorAnimation { duration: Theme.durFaster } }
            border.width: r.checked ? 0 : 1
            border.color: Theme.strongStroke
            Rectangle {
                anchors.centerIn: parent
                width: r.checked ? (ma.pressed ? 8 : 10) : (ma.containsMouse ? 8 : 0)
                height: width
                radius: width / 2
                color: r.checked ? Theme.textOnAccent : Theme.strongStroke
                Behavior on width { NumberAnimation { duration: Theme.durFaster } }
            }
        }
        FText { text: r.text; Layout.fillWidth: true }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: r.clicked()
    }
}
