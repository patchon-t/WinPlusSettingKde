import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Themes", "Plasma style"]

    readonly property var ch: Backend.themeChoices.plasma || ({ items: [], current: "" })

    Component.onCompleted: Backend.refreshThemeChoices("plasma")

    FText {
        text: "Choose how the panel, menus and widgets look."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 8
    }

    PerChoiceList {
        items: page.ch.items
        current: page.ch.current
        emptyText: "No Plasma styles found"
        onPicked: (id) => Backend.chooseTheme("plasma", id)
    }
}
