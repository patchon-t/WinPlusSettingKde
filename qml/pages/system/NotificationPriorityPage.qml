import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Notifications", "Set priority notifications"]

    Component.onCompleted: { Backend.sysCfgReload(); Backend.sysRefreshNotifApps() }

    FText {
        text: "Priority notifications can still appear when do not disturb is on."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 8
    }

    SectionHeader { text: "Calls & reminders"; Layout.topMargin: 0 }
    SettingsCard {
        icon: "fl:alert_urgent_20_regular"
        title: "Show critical notifications"
        description: "Calls, alarms and other urgent notifications are shown even in do not disturb"
        SysCfgToggle {
            cfgFile: "plasmanotifyrc"; cfgGroup: "Notifications"; cfgKey: "CriticalInDndMode"; cfgDefault: true
        }
    }

    SectionHeader { text: "Apps" }
    FText {
        visible: Backend.sysNotifApps.length === 0
        text: "No apps have sent notifications yet"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
    }
    Repeater {
        model: Backend.sysNotifApps.filter(a => a.kind === "app")
        delegate: SettingsCard {
            required property var modelData
            icon: modelData.icon + "|applications-other"
            title: modelData.name
            SysCfgToggle {
                cfgFile: "plasmanotifyrc"
                cfgGroup: "Applications/" + modelData.id
                cfgKey: "ShowPopupsInDndMode"
                cfgDefault: false
            }
        }
    }
}
