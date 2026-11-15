import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Display", "Graphics"]

    Component.onCompleted: { Backend.reloadOutputs(); Backend.sysCfgReload() }

    SysDisplayPicker { id: picker }
    readonly property var cur: picker.current

    SectionHeader { text: "Default settings"; Layout.topMargin: 12 }
    SettingsCard {
        icon: "fl:top_speed_20_regular"
        title: "Variable refresh rate"
        description: page.cur && page.cur.vrrSupported
                     ? "Lets the display match its refresh rate to the frame rate, for smoother games"
                     : "Not supported on this display"
        enabled: !!(page.cur && page.cur.vrrSupported)
        FluentCombo {
            minWidth: 140
            model: ["Off", "Automatic", "Always"]
            currentIndex: page.cur ? page.cur.vrrIndex : 0
            onActivated: (i) => Backend.sysSetVrr(page.cur.name, i)
        }
    }
    SettingsCard {
        icon: "fl:games_20_regular"
        title: "Allow tearing in full-screen games"
        description: "Reduces input lag in full-screen games, but may show screen tearing"
        SysCfgToggle {
            cfgFile: "kwinrc"; cfgGroup: "Compositing"; cfgKey: "AllowTearing"; cfgDefault: true
            reconfigure: true
        }
    }

    SectionHeader { text: "Custom options for apps" }
    SettingsCard {
        enabled: false
        icon: "fl:apps_20_regular"
        title: "Choose which graphics card each app uses"
        description: "Not available yet"
    }
}
