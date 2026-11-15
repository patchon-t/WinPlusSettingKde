import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Themes", "Application style"]

    readonly property var ch: Backend.themeChoices.style || ({ items: [], current: "" })

    Component.onCompleted: Backend.refreshThemeChoices("style")

    FText {
        text: "Choose how buttons and other controls look in apps."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 8
    }

    PerChoiceList {
        items: page.ch.items
        current: page.ch.current
        emptyText: "No application styles found"
        onPicked: (id) => Backend.chooseTheme("style", id)
    }
}
