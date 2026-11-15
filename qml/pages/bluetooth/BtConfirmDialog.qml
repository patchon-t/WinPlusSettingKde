import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."

// Win11 ContentDialog: title, message, accent primary button + Cancel
Popup {
    id: dlg
    property string title
    property string message
    property string acceptText: "OK"
    signal accepted()

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: 440
    padding: 0
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

    contentItem: ColumnLayout {
        spacing: 0
        ColumnLayout {
            Layout.margins: 24
            spacing: 12
            FText { text: dlg.title; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            FText {
                text: dlg.message
                visible: text.length > 0
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
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
                FluentButton { text: dlg.acceptText; accent: true; Layout.fillWidth: true
                    onClicked: { dlg.close(); dlg.accepted() } }
                FluentButton { text: "Cancel"; Layout.fillWidth: true; onClicked: dlg.close() }
            }
        }
    }
}
