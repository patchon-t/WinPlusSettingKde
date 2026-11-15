import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    property string appId: "org.kde.sample"
    property string appName: "Sample app"
    property string appIcon: ""
    property string kind: "app"
    crumbs: ["System", "Notifications", appName]

    readonly property string rc: "plasmanotifyrc"
    readonly property string grp: Backend.sysNotifGroup(kind, appId)
    readonly property bool popups: {
        Backend.sysCfgRev
        return Backend.sysCfg(rc, grp, "ShowPopups", "true") === "true"
    }
    readonly property bool history: {
        Backend.sysCfgRev
        return Backend.sysCfg(rc, grp, "ShowInHistory", "true") === "true"
    }
    readonly property bool master: popups || history

    Component.onCompleted: Backend.sysCfgReload()

    ExpanderCard {
        icon: page.appIcon + "|applications-other"
        title: "Notifications"
        description: page.appName
        expanded: page.master
        headerControls: [
            FluentToggle {
                checked: page.master
                onToggled: (c) => Backend.sysNotifSetAll(page.kind, page.appId, c)
            }
        ]
        ExpanderRow {
            title: "Show notification banners"
            divider: false
            SysCfgToggle { cfgFile: page.rc; cfgGroup: page.grp; cfgKey: "ShowPopups"; cfgDefault: true; showLabel: false }
        }
        ExpanderRow {
            title: "Show notifications in notification center"
            SysCfgToggle { cfgFile: page.rc; cfgGroup: page.grp; cfgKey: "ShowInHistory"; cfgDefault: true; showLabel: false }
        }
        ExpanderRow {
            title: "Show badge on the app icon in the task manager"
            visible: page.kind === "app"
            SysCfgToggle { cfgFile: page.rc; cfgGroup: page.grp; cfgKey: "ShowBadges"; cfgDefault: true; showLabel: false }
        }
        ExpanderRow {
            title: "Show banners while do not disturb is on"
            description: "Treat this app's notifications as priority notifications"
            SysCfgToggle { cfgFile: page.rc; cfgGroup: page.grp; cfgKey: "ShowPopupsInDndMode"; cfgDefault: false; showLabel: false }
        }
        ExpanderRow {
            title: "Play a sound when a notification arrives"
            description: "Not available yet"
            enabled: false
            FluentToggle { checked: false; showLabel: false }
        }
    }
}
