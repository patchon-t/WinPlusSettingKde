import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."

// Labelled Win11 text box (used inside AccDialog)
ColumnLayout {
    id: f
    property string label
    property string placeholder
    property bool password: false
    property alias text: tf.text
    property alias field: tf
    signal accepted()
    Layout.fillWidth: true
    spacing: 4

    FText { text: f.label; visible: text.length > 0; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary }
    TextField {
        id: tf
        Layout.fillWidth: true
        implicitHeight: 32
        color: Theme.text
        placeholderText: f.placeholder
        placeholderTextColor: Theme.textSecondary
        font.pixelSize: Theme.fontBody
        leftPadding: 11
        echoMode: f.password ? TextInput.Password : TextInput.Normal
        selectByMouse: true
        background: Rectangle {
            radius: Theme.radius
            color: Theme.controlBgFocus
            border.color: Theme.controlBorder
            clip: true
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: tf.activeFocus ? 2 : 1
                color: tf.activeFocus ? Theme.accent : Theme.controlBorderBottom
            }
        }
        onAccepted: f.accepted()
    }
}
