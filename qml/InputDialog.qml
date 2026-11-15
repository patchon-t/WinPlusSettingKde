import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

// Win11 ContentDialog with one text field (Wi-Fi password, rename...)
Popup {
    id: dlg
    property string title
    property string message
    property string placeholder
    property bool password: false
    property string acceptText: "OK"
    property alias value: field.text
    signal submitted(string value)

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: 440
    padding: 0
    onOpened: { field.text = ""; field.forceActiveFocus() }
    Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.3) }
    background: FlyoutBackground {}
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durFast
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decelerate }
        NumberAnimation { property: "scale"; from: 1.05; to: 1; duration: Theme.durNormal
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decelerate }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFaster }
        NumberAnimation { property: "scale"; from: 1; to: 1.05; duration: Theme.durFast
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.accelerate }
    }

    function accept() {
        dlg.submitted(field.text)
        dlg.close()
    }

    contentItem: ColumnLayout {
        spacing: 0
        ColumnLayout {
            Layout.margins: 24
            spacing: 12
            FText { text: dlg.title; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold }
            FText {
                text: dlg.message
                visible: text.length > 0
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            TextField {
                id: field
                Layout.fillWidth: true
                implicitHeight: 32
                color: Theme.text
                placeholderText: dlg.placeholder
                placeholderTextColor: Theme.textSecondary
                font.pixelSize: Theme.fontBody
                leftPadding: 11
                echoMode: dlg.password ? TextInput.Password : TextInput.Normal
                selectByMouse: true
                background: Rectangle {
                    radius: Theme.radius
                    color: Theme.controlBgFocus
                    border.color: Theme.controlBorder
                    clip: true
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: field.activeFocus ? 2 : 1
                        color: field.activeFocus ? Theme.accent : Theme.controlBorderBottom
                    }
                }
                onAccepted: dlg.accept()
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 80
            color: Theme.dark ? "#202020" : "#f3f3f3"
            radius: Theme.radiusLarge
            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 8
                FluentButton {
                    text: dlg.acceptText
                    accent: true
                    Layout.fillWidth: true
                    enabled: field.text.length > 0
                    onClicked: dlg.accept()
                }
                FluentButton { text: "Cancel"; Layout.fillWidth: true; onClicked: dlg.close() }
            }
        }
    }
}
