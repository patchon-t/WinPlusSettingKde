import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Remote Desktop"]

    readonly property var users: {
        Backend.sysCfgRev
        const raw = Backend.sysCfg("krdpserverrc", "General", "Users", "")
        return raw.length ? raw.split(",").filter(u => u.length) : []
    }
    readonly property string port: {
        Backend.sysCfgRev
        return Backend.sysCfg("krdpserverrc", "General", "ListenPort", "3389")
    }

    Component.onCompleted: { Backend.sysCfgReload(); Backend.sysRefreshRdp() }
    Timer { interval: 4000; repeat: true; running: true; onTriggered: Backend.sysRefreshRdp() }

    SettingsCard {
        icon: "fl:remote_20_regular"
        title: "Remote Desktop"
        description: Backend.sysRdpActive ? "Connect to this PC at " + Backend.sysRdpAddress()
                                          : "Connect to and use this PC from a remote device using a Remote Desktop client"
        FluentToggle {
            checked: Backend.sysRdpEnabled || Backend.sysRdpActive
            onToggled: (c) => Backend.sysSetRdp(c)
        }
    }

    SettingsCard {
        icon: "fl:people_20_regular"
        title: "Remote Desktop users"
        description: page.users.length ? page.users.join(", ") : "No users have been added"
        SysCfgToggle {
            cfgFile: "krdpserverrc"; cfgGroup: "General"; cfgKey: "SystemUserEnabled"; cfgDefault: false
            showLabel: false
        }
        FText { text: "Allow system users"; color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
    }
    SettingsCard {
        enabled: false
        icon: "fl:lock_closed_20_regular"
        title: "Require devices to use Network Level Authentication to connect"
        description: "Not available on Linux"
        FluentToggle { checked: false }
    }
    SettingsCard {
        icon: "fl:globe_20_regular"
        title: "Remote Desktop port"
        description: "The port other devices connect to. Restart Remote Desktop after changing it"
        SysTextBox {
            id: portField
            implicitWidth: 100
            text: page.port
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 1; top: 65535 }
            onAccepted: Backend.sysCfgSet("krdpserverrc", "General", "ListenPort", text, "")
        }
        FluentButton {
            text: "Apply"
            enabled: portField.text.length > 0 && portField.text !== page.port
            onClicked: Backend.sysCfgSet("krdpserverrc", "General", "ListenPort", portField.text, "")
        }
    }
    SettingsCard {
        icon: "fl:desktop_20_regular"
        title: "Video quality"
        description: "Higher quality uses more bandwidth"
        SysCfgCombo {
            cfgFile: "krdpserverrc"; cfgGroup: "General"; cfgKey: "Quality"; cfgDefault: "75"
            model: ["Low", "Medium", "High", "Best"]
            values: ["25", "50", "75", "100"]
        }
    }
}
