import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Taskbar"]

    readonly property var ps: Backend.plasmaState
    readonly property bool hasPanel: ps.panel === true
    readonly property var groupModes: ["always", "full", "never"]
    readonly property var trayItems: {
        const seen = {}, out = []
        const all = (ps.trayKnown || []).concat(ps.trayShown || [], ps.trayHidden || [])
        for (let i = 0; i < all.length; ++i)
            if (!seen[all[i]]) { seen[all[i]] = true; out.push(all[i]) }
        return out
    }

    function trayName(id) {
        return id.replace(/^org\.kde\.(plasma\.)?/, "")
    }

    Component.onCompleted: {
        Backend.refreshPlasma()
        Backend.refreshMisc()
    }

    FText {
        visible: ps.loaded === true && !page.hasPanel
        text: "Couldn't find the Plasma panel. Taskbar settings are unavailable."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 4
    }

    // ---------------------------------------------------------- taskbar items
    SectionHeader { text: "Taskbar items"; Layout.topMargin: 0 }

    SettingsCard {
        icon: "fl:window_apps_20_regular"
        title: "Search"
        description: "Not available on Linux"
        enabled: false
        FluentCombo { model: ["Hide"]; currentIndex: 0 }
    }
    SettingsCard {
        icon: "fl:window_apps_20_regular"
        title: "Task view"
        description: "Not available on Linux"
        enabled: false
        FluentToggle { checked: false }
    }
    SettingsCard {
        icon: "fl:window_apps_20_regular"
        title: "Widgets"
        description: "Not available on Linux"
        enabled: false
        FluentToggle { checked: false }
    }

    // ---------------------------------------------------------- tray
    ExpanderCard {
        Layout.topMargin: 16
        icon: "fl:apps_20_regular"
        title: "Other system tray icons"
        description: "Show or hide additional system tray icons"
        enabled: ps.trayFound === true
        opacity: enabled ? 1 : 0.5
        ExpanderRow {
            title: "Always show every tray icon"
            description: "Otherwise some icons stay in the hidden icon menu"
            FluentToggle {
                checked: ps.trayShowAll === true
                onToggled: (c) => Backend.setTrayShowAll(c)
            }
        }
        Repeater {
            model: page.trayItems
            delegate: ExpanderRow {
                required property string modelData
                title: page.trayName(modelData)
                FluentToggle {
                    checked: (ps.trayHidden || []).indexOf(modelData) < 0
                    onToggled: (c) => Backend.setTrayItemShown(modelData, c)
                }
            }
        }
    }

    // ---------------------------------------------------------- behaviors
    ExpanderCard {
        icon: "fl:panel_bottom_20_regular"
        title: "Taskbar behaviors"
        description: "Taskbar alignment, badging, automatically hide, and multiple displays"
        expanded: true
        enabled: page.hasPanel
        opacity: enabled ? 1 : 0.5

        ExpanderRow {
            title: "Taskbar alignment"
            description: "Takes effect when the panel isn't full width"
            FluentCombo {
                model: ["Left", "Center"]
                currentIndex: ps.alignment === "left" ? 0 : 1
                onActivated: (i) => Backend.setPanelProperty("alignment", i === 0 ? "left" : "center")
            }
        }
        ExpanderRow {
            title: "Automatically hide the taskbar"
            FluentToggle {
                checked: ps.hiding === "autohide"
                onToggled: (c) => Backend.setPanelProperty("hiding", c ? "autohide" : "none")
            }
        }
        ExpanderRow {
            title: "Show badges on taskbar apps"
            FluentToggle {
                checked: Backend.miscState.badges !== false
                onToggled: (c) => Backend.setMiscOption("badges", c)
            }
        }
        ExpanderRow {
            title: "Show smaller taskbar buttons"
            FluentToggle {
                checked: ps.height !== undefined && ps.height < 40
                onToggled: (c) => Backend.setPanelProperty("height", c ? 32 : 44)
            }
        }
        ExpanderRow {
            title: "Show my taskbar on all displays"
            description: "Not available on Linux, panels belong to one screen"
            enabled: false
            opacity: enabled ? 1 : 0.5
            FluentToggle { checked: false }
        }
        ExpanderRow {
            title: "When using multiple displays, show my taskbar apps on"
            enabled: ps.taskFound === true
            opacity: enabled ? 1 : 0.5
            FluentCombo {
                model: ["All taskbars", "Taskbar where window is open"]
                currentIndex: ps.onlyCurrentScreen ? 1 : 0
                minWidth: 220
                onActivated: (i) => Backend.setTaskOnlyCurrentScreen(i === 1)
            }
        }
        ExpanderRow {
            title: "Combine taskbar buttons and hide labels"
            enabled: ps.taskFound === true
            opacity: enabled ? 1 : 0.5
            FluentCombo {
                model: ["Always", "When taskbar is full", "Never"]
                currentIndex: Math.max(0, page.groupModes.indexOf(ps.grouping))
                onActivated: (i) => Backend.setTaskGrouping(page.groupModes[i])
            }
        }
        ExpanderRow {
            title: "Select the far corner of the taskbar to show the desktop"
            description: "Not available yet, needs the Peek at Desktop widget"
            enabled: false
            opacity: enabled ? 1 : 0.5
            FluentToggle { checked: false }
        }
    }
}
