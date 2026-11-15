import QtQuick
import QtQuick.Layouts
import "../.."

// Win11 CheckBox (box + check mark). Controlled: emits toggled(checked).
Item {
    id: c
    property bool checked: false
    property string text
    signal toggled(bool checked)
    implicitHeight: 32
    implicitWidth: row.implicitWidth
    opacity: enabled ? 1 : 0.5

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 12
        Rectangle {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            radius: Theme.radius
            color: c.checked ? (ma.pressed ? Theme.accentPressed : Theme.accent)
                   : ma.pressed ? Theme.subtlePressed : ma.containsMouse ? Theme.subtleHover : Theme.toggleOffBg
            Behavior on color { ColorAnimation { duration: Theme.durFaster } }
            border.width: c.checked ? 0 : 1
            border.color: Theme.strongStroke
            Glyph {
                anchors.centerIn: parent
                width: 12
                height: 12
                visible: c.checked
                lines: Theme.gCheck
                color: Theme.onAccent
            }
        }
        FText { text: c.text; visible: text.length > 0; Layout.fillWidth: true }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: c.toggled(!c.checked)
    }
}
