import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Themes", "Cursors"]

    readonly property var ch: Backend.themeChoices.cursors || ({ items: [], current: "" })

    Component.onCompleted: Backend.refreshThemeChoices("cursors")

    FText {
        text: "Choose the pointer theme and size."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 8
    }

    SettingsCard {
        icon: "fl:cursor_20_regular"
        title: "Cursor size"
        description: "Size of the mouse pointer"
        Layout.bottomMargin: 8
        FluentCombo {
            readonly property var sizes: [16, 24, 32, 48, 64, 96]
            model: ["16", "24", "32", "48", "64", "96"]
            currentIndex: Math.max(0, sizes.indexOf(page.ch.size))
            onActivated: (i) => Backend.setCursorSize(sizes[i])
        }
    }

    PerChoiceList {
        items: page.ch.items
        current: page.ch.current
        emptyText: "No cursor themes found"
        onPicked: (id) => Backend.chooseTheme("cursors", id)
    }
}
