import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."

// Win11 confirmation flyout ("This app and its related info will be uninstalled.")
Popup {
    id: c
    property string message
    property string acceptText: "Uninstall"
    signal accepted()

    padding: 0
    width: 300
    y: parent ? parent.height + 2 : 0
    x: parent ? parent.width - width : 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: FlyoutBackground {}
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durFast }
        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Theme.durNormal
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decelerate }
    }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFaster } }

    contentItem: ColumnLayout {
        spacing: 16
        FText {
            text: c.message
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.bottomMargin: 0
        }
        FluentButton {
            text: c.acceptText
            accent: true
            Layout.margins: 16
            Layout.topMargin: 0
            onClicked: { c.close(); c.accepted() }
        }
    }
}
