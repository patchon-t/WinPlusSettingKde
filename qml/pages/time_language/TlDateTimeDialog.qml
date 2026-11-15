import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."

// "Set the date and time" ContentDialog (manual time, only works with NTP off)
Popup {
    id: dlg
    signal submitted(string date, string time)

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: 440
    padding: 0
    onOpened: {
        const n = new Date()
        dateField.text = Qt.formatDate(n, "yyyy-MM-dd")
        timeField.text = Qt.formatTime(n, "HH:mm:ss")
        dateField.forceActiveFocus()
    }
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

    component Field: TextField {
        id: f
        Layout.fillWidth: true
        implicitHeight: 32
        color: Theme.text
        placeholderTextColor: Theme.textSecondary
        font.pixelSize: Theme.fontBody
        leftPadding: 11
        selectByMouse: true
        background: Rectangle {
            radius: Theme.radius
            color: Theme.controlBgFocus
            border.color: Theme.controlBorder
            clip: true
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: f.activeFocus ? 2 : 1
                color: f.activeFocus ? Theme.accent : Theme.controlBorderBottom
            }
        }
    }

    function accept() {
        dlg.submitted(dateField.text.trim(), timeField.text.trim())
        dlg.close()
    }

    contentItem: ColumnLayout {
        spacing: 0
        ColumnLayout {
            Layout.margins: 24
            spacing: 8
            FText { text: "Set the date and time"; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold; Layout.bottomMargin: 8 }
            FText { text: "Date"; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary }
            Field { id: dateField; placeholderText: "YYYY-MM-DD" }
            FText { text: "Time"; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary; Layout.topMargin: 4 }
            Field { id: timeField; placeholderText: "HH:MM:SS"; onAccepted: dlg.accept() }
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
                FluentButton { text: "Change"; accent: true; Layout.fillWidth: true; onClicked: dlg.accept() }
                FluentButton { text: "Cancel"; Layout.fillWidth: true; onClicked: dlg.close() }
            }
        }
    }
}
