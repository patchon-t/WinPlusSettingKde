import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."

// Searchable list in a Win11 ContentDialog. model = [{ code, name }].
Popup {
    id: dlg
    property string title
    property string message
    property var model: []
    property string acceptText: "Add"
    property int selected: -1
    signal picked(string code, string name)

    readonly property var shown: {
        const f = search.text.trim().toLowerCase()
        if (!f.length)
            return model
        return model.filter(d => d.name.toLowerCase().indexOf(f) >= 0 || d.code.toLowerCase().indexOf(f) >= 0)
    }

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: 440
    padding: 0
    onOpened: { search.text = ""; selected = -1; search.forceActiveFocus() }
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
        const d = dlg.shown[dlg.selected]
        if (d) {
            dlg.picked(d.code, d.name)
            dlg.close()
        }
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
                id: search
                Layout.fillWidth: true
                implicitHeight: 32
                color: Theme.text
                placeholderText: "Search"
                placeholderTextColor: Theme.textSecondary
                font.pixelSize: Theme.fontBody
                leftPadding: 11
                selectByMouse: true
                onTextChanged: dlg.selected = -1
                background: Rectangle {
                    radius: Theme.radius
                    color: Theme.controlBgFocus
                    border.color: Theme.controlBorder
                    clip: true
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: search.activeFocus ? 2 : 1
                        color: search.activeFocus ? Theme.accent : Theme.controlBorderBottom
                    }
                }
            }
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: 280
                clip: true
                model: dlg.shown
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: FluentScrollBar {}
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 40
                    radius: Theme.radius
                    color: rma.pressed ? Theme.subtlePressed
                           : (rma.containsMouse || dlg.selected === row.index) ? Theme.subtleHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durFaster } }
                    Rectangle {
                        visible: dlg.selected === row.index
                        width: 3; height: 16; radius: 1.5
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    FText {
                        x: 12
                        width: parent.width - 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.name
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        id: rma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: dlg.selected = row.index
                        onDoubleClicked: { dlg.selected = row.index; dlg.accept() }
                    }
                }
                FText {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "No results"
                    color: Theme.textSecondary
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
                    text: dlg.acceptText
                    accent: true
                    Layout.fillWidth: true
                    enabled: dlg.selected >= 0
                    onClicked: dlg.accept()
                }
                FluentButton { text: "Cancel"; Layout.fillWidth: true; onClicked: dlg.close() }
            }
        }
    }
}
