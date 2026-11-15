import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "For developers"]

    readonly property string curExec: {
        Backend.sysCfgRev
        return Backend.sysCfg("kdeglobals", "General", "TerminalApplication", "konsole")
    }

    Component.onCompleted: { Backend.sysCfgReload(); Backend.sysRefreshTerminals() }

    SectionHeader { text: "Terminal"; Layout.topMargin: 0 }
    SettingsCard {
        icon: "fl:window_console_20_regular"
        title: "Terminal"
        description: Backend.sysTerminals.length ? "Choose the default terminal app for apps that open a command line"
                                                 : "No terminal apps found"
        enabled: Backend.sysTerminals.length > 0
        FluentCombo {
            minWidth: 220
            model: Backend.sysTerminals.map(t => t.name)
            currentIndex: Backend.sysTerminals.findIndex(t => t.exec === page.curExec)
            onActivated: (i) => Backend.sysSetTerminal(Backend.sysTerminals[i].exec, Backend.sysTerminals[i].service)
        }
    }

    SectionHeader { text: "File Explorer" }
    ExpanderCard {
        icon: "fl:folder_20_regular"
        title: "File Explorer"
        description: "Not available yet"
        enabled: false
        ExpanderRow { title: "Show file extensions"; divider: false; FluentToggle { checked: false; showLabel: false } }
        ExpanderRow { title: "Show hidden and system files"; FluentToggle { checked: false; showLabel: false } }
        ExpanderRow { title: "Show full path in title bar"; FluentToggle { checked: false; showLabel: false } }
    }

    SectionHeader { text: "Remote Desktop" }
    SettingsCard {
        icon: "fl:remote_20_regular"
        title: "Remote Desktop"
        description: "Connect to this PC from another device"
        clickable: true
        onClicked: Router.open("pages/system/RemoteDesktopPage.qml", {})
    }
}
