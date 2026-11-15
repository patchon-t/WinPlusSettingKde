import QtQuick
import QtQuick.Layouts
import "../.."

// Win11 CheckBox. Controlled: emits toggled(newValue); the parent updates `checked`.
Item {
    id: cb
    property bool checked: false
    property string text
    signal toggled(bool checked)

    implicitWidth: 20 + (text.length ? 8 + label.implicitWidth : 0)
    implicitHeight: 32
    opacity: enabled ? 1 : 0.5

    Rectangle {
        id: box
        width: 20
        height: 20
        radius: Theme.radius
        anchors.verticalCenter: parent.verticalCenter
        color: cb.checked ? (ma.pressed ? Theme.accentPressed : ma.containsMouse ? Theme.accentHover : Theme.accent)
                          : (ma.pressed ? Theme.subtlePressed : ma.containsMouse ? Theme.subtleHover : Theme.toggleOffBg)
        Behavior on color { ColorAnimation { duration: Theme.durFaster } }
        border.width: cb.checked ? 0 : 1
        border.color: Theme.strongStroke
        Glyph {
            anchors.centerIn: parent
            width: 12
            height: 12
            lines: Theme.gCheck
            stroke: 1.6
            color: Theme.textOnAccent
            opacity: cb.checked ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFaster } }
        }
    }
    FText {
        id: label
        visible: cb.text.length > 0
        text: cb.text
        anchors.left: box.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: cb.toggled(!cb.checked)
    }
}
