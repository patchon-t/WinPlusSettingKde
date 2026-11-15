import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."

// Labelled single-line text field in Win11 style (section-local).
ColumnLayout {
    id: f
    property string label
    property string placeholder
    property bool password: false
    property alias text: field.text
    signal edited()
    signal accepted()

    Layout.fillWidth: true
    spacing: 4
    FText { text: f.label; visible: text.length > 0; font.pixelSize: Theme.fontCaption }
    TextField {
        id: field
        Layout.fillWidth: true
        implicitHeight: 32
        enabled: f.enabled
        color: Theme.text
        placeholderText: f.placeholder
        placeholderTextColor: Theme.textSecondary
        font.pixelSize: Theme.fontBody
        leftPadding: 11
        echoMode: f.password ? TextInput.Password : TextInput.Normal
        selectByMouse: true
        onTextEdited: f.edited()
        onAccepted: f.accepted()
        background: Rectangle {
            radius: Theme.radius
            color: field.enabled ? Theme.controlBgFocus : Theme.controlBgDisabled
            border.color: Theme.controlBorder
            clip: true
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: field.activeFocus ? 2 : 1
                color: field.activeFocus ? Theme.accent : Theme.controlBorderBottom
            }
        }
    }
}
