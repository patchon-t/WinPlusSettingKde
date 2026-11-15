import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Time & language", "Typing"]

    Component.onCompleted: Backend.refreshTyping()

    SettingsCard {
        icon: "fl:text_grammar_wand_20_regular"
        title: "Autocorrect misspelled words"
        description: "Not available on Linux: KDE apps do not share a system-wide autocorrect setting"
        enabled: false
        FluentToggle { checked: false }
    }
    SettingsCard {
        icon: "fl:text_grammar_wand_20_regular"
        title: "Highlight misspelled words"
        description: "Underline misspelled words as you type in apps that use Sonnet spell checking"
        FluentToggle {
            checked: Backend.spellHighlight
            onToggled: (c) => Backend.setSpellHighlight(c)
        }
    }
    SettingsCard {
        icon: "fl:keyboard_dock_20_regular"
        title: "Touch keyboard"
        description: "Choose when the on-screen keyboard appears"
        clickable: true
        onClicked: Router.open("pages/time_language/TouchKeyboardPage.qml", {})
    }
    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Keyboards"
        description: Backend.keyboardLayouts.length ? Backend.keyboardLayouts.map(d => d.layout).join(", ") : "Add and arrange keyboard layouts"
        clickable: true
        onClicked: Router.open("pages/time_language/KeyboardLayoutsPage.qml", {})
    }
    SettingsCard {
        icon: "fl:settings_20_regular"
        title: "Advanced keyboard settings"
        description: "Input method switching, hot keys, key repeat"
        clickable: true
        onClicked: Router.open("pages/time_language/AdvancedKeyboardPage.qml", {})
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Emoji panel"
        description: "Press Meta + . to open it from anywhere"
        FluentButton { text: "Open"; onClicked: Backend.runCommand(["plasma-emojier"]) }
    }
    SettingsCard {
        icon: "fl:local_language_20_regular"
        title: "Language & region"
        description: "Display language, preferred languages, regional format"
        clickable: true
        onClicked: Router.open("pages/time_language/LanguageRegionPage.qml", {})
    }
}
