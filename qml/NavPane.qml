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
        }
    }
}
