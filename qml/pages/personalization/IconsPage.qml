import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Themes", "Icons"]

    readonly property var ch: Backend.themeChoices.icons || ({ items: [], current: "" })

    Component.onCompleted: Backend.refreshThemeChoices("icons")

    FText {
        text: "Choose the icon theme used by Plasma and your apps. Some apps need a restart to pick it up."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 8
    }

    PerChoiceList {
        items: page.ch.items
        current: page.ch.current
        emptyText: "No icon themes found"
        onPicked: (id) => Backend.chooseTheme("icons", id)
    }
}
