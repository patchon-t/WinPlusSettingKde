import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Text input"]

    Component.onCompleted: Backend.refreshMisc()

    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Input language switcher"
        description: "Show a pop-up when you switch the keyboard layout"
        FluentToggle {
            checked: Backend.miscState.kbdIndicator !== false
            onToggled: (c) => Backend.setMiscOption("kbdIndicator", c)
        }
    }

    FText {
        text: "Keyboard layouts are added under Time & language."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.topMargin: 8
    }
}
