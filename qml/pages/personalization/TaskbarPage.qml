import QtQuick
import QtQuick.Controls
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

    // Search = the Search Pill widget (github.com/patchon-t/SearchPillKDEWidget,
    // plugin com.techbypatch.searchpill); settings are its own config keys.
    component PillSlider: RowLayout {
        id: psl
        property string key
        property int from: 0
        property int to: 100
        property string unit: ""
        spacing: 12
        FText {
            text: psl.unit.length ? Math.round(sl.value) + " " + psl.unit : Math.round(sl.value)
            color: Theme.textSecondary
            Layout.preferredWidth: 64
            horizontalAlignment: Text.AlignRight
        }
        FluentSlider {
            id: sl
            from: psl.from; to: psl.to; stepSize: 1
            value: Backend.plasmaState["pill_" + psl.key] || 0
            onMoved: Backend.setSearchPillOption(psl.key, Math.round(value))
        }
    }

    ExpanderCard {
        icon: "fl:search_20_regular"
        title: "Search"
        description: page.ps.pill ? "Search Pill on your taskbar" : "Add the Search Pill widget to your panel to change these"
        enabled: !!page.ps.pill
        ExpanderRow {
            title: "Type in the search box on the taskbar"
            description: "Off: the box opens a search window instead"
            divider: false
            FluentToggle {
                checked: !!page.ps.pill_inlineSearch
                onToggled: (v) => Backend.setSearchPillOption("inlineSearch", v)
            }
        }
        ExpanderRow {
            title: "Show search icon"
            FluentToggle {
                checked: !!page.ps.pill_showIcon
                onToggled: (v) => Backend.setSearchPillOption("showIcon", v)
            }
        }
        ExpanderRow {
            title: "Placeholder text"
            description: "Empty shows \"Search\""
            TextField {
                implicitWidth: 200
                implicitHeight: 32
                color: Theme.text
                placeholderText: "Search"
                placeholderTextColor: Theme.textSecondary
                font.pixelSize: Theme.fontBody
                leftPadding: 11
                selectByMouse: true
                text: page.ps.pill_placeholderText || ""
                onEditingFinished: Backend.setSearchPillOption("placeholderText", text)
                background: Rectangle {
                    radius: Theme.radius
                    color: Theme.controlBg
                    border.color: Theme.controlBorder
                }
            }
        }
        ExpanderRow {
            title: "Search box width"
            PillSlider { key: "pillWidth"; from: 4; to: 60; unit: "units" }
        }
        ExpanderRow {
            title: "Search box height"
            description: "0 = fit the taskbar"
            PillSlider { key: "pillHeight"; from: 0; to: 120; unit: "px" }
        }
        ExpanderRow {
            title: "Floating search window"
            description: "Keep the window away from the taskbar and screen edges"
            FluentToggle {
                checked: !!page.ps.pill_floatingPopup
                onToggled: (v) => Backend.setSearchPillOption("floatingPopup", v)
            }
        }
        ExpanderRow {
            title: "Search window width"
            PillSlider { key: "popupWidth"; from: 14; to: 80; unit: "units" }
        }
        ExpanderRow {
            title: "Search window height"
            PillSlider { key: "popupHeight"; from: 10; to: 80; unit: "units" }
        }
        ExpanderRow {
            title: "Gap from edges"
            PillSlider { key: "popupGap"; from: 0; to: 64; unit: "px" }
        }
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
