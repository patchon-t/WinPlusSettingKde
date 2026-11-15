import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Privacy & security", "Search permissions"]

    // krunnerrc [General] historyBehavior: 0 Disabled, 1 ImmediateCompletion, 2 CompletionSuggestion
    readonly property var modes: ["Complete as you type", "Show suggestions"]

    Component.onCompleted: Backend.refreshPrvSearch()

    SectionHeader { text: "History"; Layout.topMargin: 0 }

    SettingsCard {
        icon: "fl:history_20_regular"
        title: "Search history on this device"
        description: "Let KRunner remember what you search for on this device"
        FluentToggle {
            checked: Backend.prvSearchHistory !== 0
            onToggled: (v) => Backend.setPrvSearchHistory(v ? 2 : 0)
        }
    }

    SettingsCard {
        icon: "fl:search_20_regular"
        title: "Use history"
        description: "How remembered searches are offered"
        enabled: Backend.prvSearchHistory !== 0
        FluentCombo {
            minWidth: 180
            model: page.modes
            currentIndex: Backend.prvSearchHistory === 1 ? 0 : 1
            onActivated: (i) => Backend.setPrvSearchHistory(i === 0 ? 1 : 2)
        }
    }
}
