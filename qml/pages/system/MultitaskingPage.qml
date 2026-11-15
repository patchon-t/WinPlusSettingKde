import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Multitasking"]

    readonly property bool snapOn: {
        Backend.sysCfgRev
        return Backend.sysCfg("kwinrc", "Windows", "ElectricBorderMaximize", "true") === "true"
            || Backend.sysCfg("kwinrc", "Windows", "ElectricBorderTiling", "true") === "true"
    }

    Component.onCompleted: { Backend.sysCfgReload(); Backend.sysRefreshTaskbar(); Backend.sysRefreshDesktops() }

    // ---------------------------------------------------------- snap
    ExpanderCard {
        icon: "fl:window_multiple_20_regular"
        title: "Snap windows"
        description: "Drag a window to a screen edge or corner to maximize it or tile it"
        expanded: page.snapOn
        headerControls: [
            FluentToggle {
                checked: page.snapOn
                onToggled: (c) => {
                    Backend.sysCfgSet("kwinrc", "Windows", "ElectricBorderMaximize", c ? "true" : "false", "bool", true)
                    Backend.sysCfgSet("kwinrc", "Windows", "ElectricBorderTiling", c ? "true" : "false", "bool", true)
                }
            }
        ]
        ExpanderRow {
            title: "Maximize by dragging to the top edge"
            divider: false
            SysCfgToggle { cfgFile: "kwinrc"; cfgGroup: "Windows"; cfgKey: "ElectricBorderMaximize"; cfgDefault: true; reconfigure: true; showLabel: false }
        }
        ExpanderRow {
            title: "Tile by dragging to the left or right edge"
            SysCfgToggle { cfgFile: "kwinrc"; cfgGroup: "Windows"; cfgKey: "ElectricBorderTiling"; cfgDefault: true; reconfigure: true; showLabel: false }
        }
        ExpanderRow {
            title: "Show snap layouts when I hover over a window's maximize button"
            description: "Not available on Linux"
            enabled: false
            FluentToggle { checked: false; showLabel: false }
        }
    }

    // ---------------------------------------------------------- desktops
    SectionHeader { text: "Desktops" }
    SettingsCard {
        icon: "fl:window_20_regular"
        title: "On the taskbar, show all open windows"
        description: Backend.sysTaskbarAllDesktops < 0 ? "No task manager found in your panels" : ""
        enabled: Backend.sysTaskbarAllDesktops >= 0
        FluentCombo {
            minWidth: 230
            model: ["On all desktops", "Only on the desktop I'm using"]
            currentIndex: Math.max(0, Backend.sysTaskbarAllDesktops === 1 ? 0 : 1)
            onActivated: (i) => Backend.sysSetTaskbarAllDesktops(i === 0)
        }
    }
    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Show all open windows when I press Alt + Tab"
        SysCfgCombo {
            cfgFile: "kwinrc"; cfgGroup: "TabBox"; cfgKey: "DesktopMode"; cfgDefault: "1"; reconfigure: true
            minWidth: 230
            model: ["On all desktops", "Only on the desktop I'm using"]
            values: ["0", "1"]
        }
    }

    ExpanderCard {
        icon: "fl:apps_list_20_regular"
        title: "Virtual desktops"
        description: Backend.sysDesktops.length + (Backend.sysDesktops.length === 1 ? " desktop" : " desktops")
        enabled: Backend.sysDesktops.length > 0
        headerControls: [
            FluentButton { text: "Add desktop"; onClicked: Backend.sysAddDesktop() }
        ]
        Repeater {
            model: Backend.sysDesktops
            delegate: ExpanderRow {
                id: dr
                required property var modelData
                required property int index
                divider: index > 0
                title: "Desktop " + (index + 1)
                SysTextBox {
                    implicitWidth: 200
                    text: dr.modelData.name
                    onEditingFinished: if (text !== dr.modelData.name) Backend.sysRenameDesktop(dr.modelData.id, text)
                }
                IconButton {
                    icon: "fl:delete_20_regular"
                    enabled: Backend.sysDesktops.length > 1
                    onClicked: Backend.sysRemoveDesktop(dr.modelData.id)
                }
            }
        }
    }
}
