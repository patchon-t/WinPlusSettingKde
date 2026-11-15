import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Accessibility top page: cards grouped under Vision / Hearing / Interaction
SettingsPage {
    id: page
    property string pageTitle
    property var items: []
    crumbs: [pageTitle]

    Repeater {
        model: ["Vision", "Hearing", "Interaction"]
        delegate: ColumnLayout {
            id: grp
            required property string modelData
            Layout.fillWidth: true
            spacing: 4
            SectionHeader { text: grp.modelData; Layout.topMargin: grp.modelData === "Vision" ? 0 : 12 }
            Repeater {
                model: page.items.filter(i => i.section === grp.modelData)
                delegate: SettingsCard {
                    required property var modelData
                    icon: modelData.icon || ""
                    title: modelData.title
                    description: modelData.desc || ""
                    clickable: true
                    onClicked: Router.activate(modelData)
                }
            }
        }
    }
}
