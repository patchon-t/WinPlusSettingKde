import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Start"]

    readonly property var ps: Backend.plasmaState
    readonly property bool hasStart: ps.kickoff === true

    Component.onCompleted: {
        Backend.refreshPlasma()
        Backend.refreshMisc()
    }

    FText {
        visible: ps.loaded === true && !page.hasStart
        text: "Couldn't find the Application Launcher widget. Start settings are unavailable."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 4
    }

    ExpanderCard {
        icon: "fl:layout_cell_four_20_regular"
        title: "Layout"
        description: "Choose how pinned and all apps are arranged in the Start menu"
        expanded: true
        enabled: page.hasStart
        opacity: enabled ? 1 : 0.5

        ExpanderRow {
            title: "Pinned apps"
            description: "Show your favorites as a grid or a list"
            FluentCombo {
                model: ["Grid", "List"]
                currentIndex: ps.favDisplay === 1 ? 1 : 0
                onActivated: (i) => Backend.setStartOption("favDisplay", i)
            }
        }
        ExpanderRow {
            title: "All apps"
            description: "Show the application list as a grid or a list"
            FluentCombo {
                model: ["Grid", "List"]
                currentIndex: ps.appDisplay === 1 ? 1 : 0
                onActivated: (i) => Backend.setStartOption("appDisplay", i)
            }
        }
        ExpanderRow {
            title: "Compact mode"
            description: "Use smaller items so more fit on screen"
            FluentToggle {
                checked: ps.compact === true
                onToggled: (c) => Backend.setStartOption("compact", c)
            }
        }
    }

    SettingsCard {
        icon: "fl:clock_20_regular"
        title: "Show recently added apps"
        enabled: page.hasStart
        FluentToggle {
            checked: ps.newApps !== false
            onToggled: (c) => Backend.setStartOption("newApps", c)
        }
    }

    SettingsCard {
        icon: "fl:history_20_regular"
        title: "Show recommended files in Start, recent files in File Explorer, and items in Jump Lists"
        description: "Let Plasma remember the files and apps you use (activity history)"
        FluentToggle {
            checked: Backend.miscState.history !== false
            onToggled: (c) => Backend.setMiscOption("history", c)
        }
    }

    SettingsCard {
        icon: "fl:folder_20_regular"
        title: "Folders"
        description: "Not available on Linux, the Start menu only holds power actions"
        enabled: false
        FluentToggle { checked: false; showLabel: false }
    }
}
