import QtQuick
import QtQuick.Layouts
import WinSettings
import "."
import "Data.js" as Data

Item {
    id: pane
    property int currentIndex: 0
    signal navigate(int index)
    function focusSearch() { search.forceActiveFocus() }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 0

        RowLayout {  // profile
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.topMargin: 4
            Layout.bottomMargin: 18
            spacing: 14
            Avatar { size: 60 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                FText {
                    text: Backend.userName
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                FText {
                    text: Backend.userLogin + "@" + Backend.hostname
                    font.pixelSize: Theme.fontCaption
                    color: Theme.textSecondary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        SearchBox {
            id: search
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.bottomMargin: 14
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: Data.nav
            spacing: 4
            clip: true
            interactive: contentHeight > height
            delegate: NavItem {
                required property var modelData
                required property int index
                width: ListView.view.width
                icon: modelData.icon
                text: modelData.title
                selected: index === pane.currentIndex
                onClicked: pane.navigate(index)
            }

            // One shared selection pill. Like WinUI NavigationView, the edge
            // facing the new item leads and the trailing edge catches up, so
            // the pill stretches toward its target and then shrinks into place.
            readonly property int rowPitch: 36 + spacing
            Rectangle {
                id: pill
                // plain values (no bindings): the handler below needs the OLD position
                property real edgeTop: 10
                property real edgeBottom: 26
                property bool downward: true
                property real squeeze: {
                    const it = list.itemAtIndex(pane.currentIndex)
                    return it && it.pressed ? 3 : 0
                }
                z: 10
                x: 0
                width: 3
                radius: 1.5
                color: Theme.accent
                y: edgeTop + squeeze
                height: edgeBottom - edgeTop - 2 * squeeze
                Behavior on edgeTop { NumberAnimation { duration: pill.downward ? Theme.durSlow + 100 : Theme.durFast
                    easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
                Behavior on edgeBottom { NumberAnimation { duration: pill.downward ? Theme.durFast : Theme.durSlow + 100
                    easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
                Behavior on squeeze { NumberAnimation { duration: Theme.durFaster } }
            }
            Connections {
                target: pane
                function onCurrentIndexChanged() {
                    const t = pane.currentIndex * list.rowPitch + 10
                    pill.downward = t > pill.edgeTop
                    pill.edgeTop = t
                    pill.edgeBottom = t + 16
                }
            }
        }
    }
}
