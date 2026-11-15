import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Privacy & security: cards grouped under Security / Windows permissions / App permissions
SettingsPage {
    id: page
    property string pageTitle: "Privacy & security"
    property var items: []
    crumbs: [pageTitle]

    Repeater {
        model: page.items
        delegate: ColumnLayout {
            id: row
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: 4
            SectionHeader {
                text: row.modelData.group || ""
                visible: row.index === 0 || (page.items[row.index - 1].group || "") !== (row.modelData.group || "")
                Layout.topMargin: row.index === 0 ? 0 : 24
            }
            SettingsCard {
                icon: row.modelData.icon || ""
                title: row.modelData.title
                description: row.modelData.desc || ""
                clickable: true
                onClicked: Router.activate(row.modelData)
            }
        }
    }
}
