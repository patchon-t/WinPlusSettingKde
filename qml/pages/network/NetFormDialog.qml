import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."

// Win11 ContentDialog with a free-form body (section-local; candidate for sharing).
// Put fields inside; set `error` to show a validation message; handle `confirmed()`.
Popup {
    id: dlg
    property string title
    property string message
    property string error
    property string acceptText: "Save"
    property bool acceptEnabled: true
    property bool showAccept: true
    default property alias body: bodyCol.data
    signal confirmed()

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: 460
    height: Math.min(80 + bodyBox.implicitHeight, parent ? parent.height - 48 : 600)
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
        Flickable {
            id: fl
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: bodyBox.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: FluentScrollBar {}
            ColumnLayout {
                id: bodyBox
                width: fl.width
                spacing: 12
                FText {
                    text: dlg.title
                    font.pixelSize: Theme.fontSubtitle
                    font.weight: Font.DemiBold
                    Layout.topMargin: 24
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                FText {
                    text: dlg.message
                    visible: text.length > 0
                    font.pixelSize: Theme.fontCaption
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.fillWidth: true
                }
                ColumnLayout {
                    id: bodyCol
                    spacing: 12
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.fillWidth: true
                }
                FText {
                    text: dlg.error
                    visible: text.length > 0
                    color: Theme.dark ? "#ff99a4" : "#c42b1c"
                    font.pixelSize: Theme.fontCaption
                    wrapMode: Text.WordWrap
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.fillWidth: true
                }
                Item { implicitHeight: 12 }
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
                    visible: dlg.showAccept
                    text: dlg.acceptText
                    accent: true
                    Layout.fillWidth: true
                    enabled: dlg.acceptEnabled
                    onClicked: dlg.confirmed()
                }
                FluentButton { text: dlg.showAccept ? "Cancel" : "Close"; Layout.fillWidth: true; onClicked: dlg.close() }
            }
        }
    }
}
