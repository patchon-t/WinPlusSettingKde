import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WinSettings
import "../.."

// "How do you want to open <type> from now on?" content dialog
Popup {
    id: dlg
    property string mime
    property string label
    property var apps: []
    property string picked: ""

    function openFor(m, l) {
        mime = m
        label = l
        apps = Backend.appsHandlersFor(m)
        const cur = Backend.appsDefaults[m]
        picked = cur ? cur.id : ""
        open()
    }

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
            FText {
                text: "How do you want to open " + dlg.label + " from now on?"
                font.pixelSize: Theme.fontSubtitle
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            FText {
                visible: dlg.apps.length === 0
                text: "No installed app can open this type."
                color: Theme.textSecondary
            }
            ListView {
                id: list
                visible: dlg.apps.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 280)
                clip: true
                spacing: 2
                model: dlg.apps
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: FluentScrollBar {}
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    width: ListView.view.width
                    height: 48
                    radius: Theme.radius
                    color: rma.pressed ? Theme.subtlePressed
                           : (rma.containsMouse || dlg.picked === modelData.id) ? Theme.subtleHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durFaster } }
                    Rectangle {
                        visible: dlg.picked === row.modelData.id
                        width: 3
                        height: 16
                        radius: 1.5
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 12
                        Icon { name: row.modelData.icon; size: 28 }
                        FText { text: row.modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                    MouseArea {
                        id: rma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: dlg.picked = row.modelData.id
                    }
                }
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
                    text: "Set default"
                    accent: true
                    Layout.fillWidth: true
                    enabled: dlg.picked.length > 0
                    onClicked: { Backend.appsSetDefault(dlg.mime, dlg.picked); dlg.close() }
                }
                FluentButton { text: "Cancel"; Layout.fillWidth: true; onClicked: dlg.close() }
            }
        }
    }
}
