import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Themes", "Splash screen"]

    readonly property var ch: Backend.themeChoices.splash || ({ items: [], current: "" })

    Component.onCompleted: Backend.refreshThemeChoices("splash")

    FText {
        text: "Choose the screen shown while Plasma starts."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 8
    }

    PerChoiceList {
        items: page.ch.items
        current: page.ch.current
        emptyText: "No splash screens found"
        onPicked: (id) => Backend.chooseTheme("splash", id)
    }
}
