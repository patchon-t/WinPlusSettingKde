import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Notifications"]

    property int dndLeft: 0      // seconds left, 0 = off, -1 = until turned off
    function refreshDnd() { dndLeft = Backend.sysDndRemaining() }
    Component.onCompleted: { Backend.sysCfgReload(); Backend.sysRefreshNotifApps(); refreshDnd() }
    Connections { target: Backend; function onSysCfgChanged() { page.refreshDnd() } }
    Timer { interval: 1000; repeat: true; running: page.dndLeft > 0; onTriggered: page.refreshDnd() }

    readonly property var nf: "plasmanotifyrc"

    // ---------------------------------------------------------- master + DND
    ExpanderCard {
        icon: "fl:alert_20_regular"
        title: "Notifications"
        description: "Get notifications from apps and other senders"
        headerControls: [
            FluentToggle {
                checked: page.dndLeft === 0
                onToggled: (c) => Backend.sysDndSet(!c)
            }
        ]
        ExpanderRow {
            title: "Play a sound when a notification arrives"
            description: "Uses the system sounds setting"
            divider: false
            SysCfgToggle { cfgFile: "kdeglobals"; cfgGroup: "Sounds"; cfgKey: "Enable"; cfgDefault: true }
        }
    }

    SettingsCard {
        icon: "fl:alert_snooze_20_regular"
        title: "Do not disturb"
        description: page.dndLeft > 0 ? "On for " + Math.ceil(page.dndLeft / 60) + " more minutes"
                                      : "Notifications will be sent directly to notification center"
        FluentToggle {
            checked: page.dndLeft !== 0
            onToggled: (c) => Backend.sysDndSet(c)
        }
    }

    ExpanderCard {
        icon: "fl:alert_snooze_20_regular"
        title: "Turn on do not disturb automatically"
        description: "Choose when notifications are silenced"
        ExpanderRow {
            title: "During these times"
            description: "Not available on Linux"
            divider: false
            enabled: false
            FluentToggle { checked: false; showLabel: false }
        }
        ExpanderRow {
            title: "When duplicating your display"
            SysCfgToggle { cfgFile: page.nf; cfgGroup: "DoNotDisturb"; cfgKey: "WhenScreensMirrored"; cfgDefault: true; showLabel: false }
        }
        ExpanderRow {
            title: "When playing a game or using an app in full-screen mode"
            SysCfgToggle { cfgFile: page.nf; cfgGroup: "DoNotDisturb"; cfgKey: "WhenFullscreen"; cfgDefault: true; showLabel: false }
        }
        ExpanderRow {
            title: "When sharing your screen"
            SysCfgToggle { cfgFile: page.nf; cfgGroup: "DoNotDisturb"; cfgKey: "WhenScreenSharing"; cfgDefault: true; showLabel: false }
        }
    }

    SettingsCard {
        icon: "fl:alert_urgent_20_regular"
        title: "Set priority notifications"
        description: "Choose which notifications can break through do not disturb"
        clickable: true
        onClicked: Router.open("pages/system/NotificationPriorityPage.qml", {})
    }

    // ---------------------------------------------------------- apps and senders
    SectionHeader { text: "Notifications from apps and other senders" }
    FText {
        visible: Backend.sysNotifApps.length === 0
        text: "No apps have sent notifications yet"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
    }
    component SenderRow: SettingsCard {
        id: sr
        property var app
        readonly property string grp: Backend.sysNotifGroup(app.kind, app.id)
        readonly property bool popups: {
            Backend.sysCfgRev
            return Backend.sysCfg(page.nf, grp, "ShowPopups", "true") === "true"
        }
        readonly property bool history: {
            Backend.sysCfgRev
            return Backend.sysCfg(page.nf, grp, "ShowInHistory", "true") === "true"
        }
        icon: sr.app.icon + "|applications-other"
        title: sr.app.name
        description: sr.popups || sr.history ? (sr.popups ? "Banners" : "Notification center only") : "Off"
        clickable: true
        onClicked: Router.open("pages/system/NotificationAppPage.qml",
                               { appId: sr.app.id, appName: sr.app.name, appIcon: sr.app.icon, kind: sr.app.kind })
        FluentToggle {
            checked: sr.popups || sr.history
            onToggled: (c) => Backend.sysNotifSetAll(sr.app.kind, sr.app.id, c)
        }
    }
    Repeater {
        model: Backend.sysNotifApps
        delegate: SenderRow { required property var modelData; app: modelData }
    }

    // ---------------------------------------------------------- extras
    SectionHeader { text: "Additional settings" }
    ExpanderCard {
        icon: "fl:settings_20_regular"
        title: "Pop-up behavior"
        description: "Where banners appear and which ones are shown"
        ExpanderRow {
            title: "Pop-up position"
            divider: false
            SysCfgCombo {
                cfgFile: page.nf; cfgGroup: "Notifications"; cfgKey: "PopupPosition"; cfgDefault: "CloseToWidget"
                minWidth: 190
                model: ["Near the notification icon", "Top left", "Top center", "Top right",
                        "Bottom left", "Bottom center", "Bottom right"]
                values: ["CloseToWidget", "TopLeft", "TopCenter", "TopRight", "BottomLeft", "BottomCenter", "BottomRight"]
            }
        }
        ExpanderRow {
            title: "Show low priority notifications as banners"
            SysCfgToggle { cfgFile: page.nf; cfgGroup: "Notifications"; cfgKey: "LowPriorityPopups"; cfgDefault: true; showLabel: false }
        }
        ExpanderRow {
            title: "Keep low priority notifications in notification center"
            SysCfgToggle { cfgFile: page.nf; cfgGroup: "Notifications"; cfgKey: "LowPriorityHistory"; cfgDefault: false; showLabel: false }
        }
    }
}
