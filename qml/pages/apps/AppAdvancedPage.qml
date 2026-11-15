import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Installed apps > (app) > Advanced options  (APP.INS.4)
// App details + a Flatpak app's basic permissions (flatpak override --user).
SettingsPage {
    id: page
    property string appId: ""
    property var info: ({})
    readonly property var perms: Backend.appsPerms.id === appId ? Backend.appsPerms : ({})
    readonly property bool havePerms: perms.id === appId
    crumbs: ["Apps", "Installed apps", info.name || "App"]

    Component.onCompleted: {
        Backend.appsRefresh()
        refresh()
    }
    Connections {
        target: Backend
        function onAppsChanged() { page.refresh() }
    }
    function refresh() {
        info = appId.length ? Backend.appsInfo(appId) : ({})
        if (info.isFlatpak)
            Backend.appsLoadPerms(appId)
    }

    // header card
    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        implicitHeight: 84
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            spacing: 16
            Icon { name: info.icon || "application-x-executable"; size: 40 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                FText { text: info.name || "App not found"; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold }
                FText {
                    text: info.details || info.source || ""
                    font.pixelSize: Theme.fontCaption
                    color: Theme.textSecondary
                }
            }
        }
    }

    SectionHeader { text: "App details"; visible: !!info.name }
    SettingsCard {
        visible: !!info.name
        icon: "fl:info_20_regular"
        title: "Source"
        description: (info.source || "") + (info.installation ? " (" + info.installation + " installation)" : "")
    }
    SettingsCard {
        visible: !!info.name && (info.pkg || "").length > 0
        icon: "fl:apps_list_detail_20_regular"
        title: info.isFlatpak ? "Application ID" : "Package"
        description: info.pkg || ""
        FluentButton { text: "Copy"; onClicked: Backend.copyText(info.pkg) }
    }
    SettingsCard {
        visible: !!info.name && (info.sizeText || "").length > 0
        icon: "fl:folder_20_regular"
        title: "Size"
        description: info.sizeText || ""
    }
    SettingsCard {
        visible: !!info.name && (info.dateText || "").length > 0
        icon: "fl:document_20_regular"
        title: "Installed"
        description: info.dateText || ""
    }

    // ---- Flatpak permissions
    SectionHeader { text: "App permissions"; visible: !!info.isFlatpak }
    SettingsCard {
        visible: !!info.isFlatpak && !havePerms
        icon: "fl:info_20_regular"
        title: "Loading permissions..."
        description: "Reading this app's permissions"
    }
    SettingsCard {
        visible: !!info.isFlatpak && havePerms
        icon: "fl:globe_20_regular"
        title: "Network access"
        description: "Let this app connect to the internet and your local network"
        FluentToggle {
            checked: !!page.perms.network
            onToggled: (c) => Backend.appsSetPerm(page.appId, "network", c)
        }
    }
    SettingsCard {
        visible: !!info.isFlatpak && havePerms
        icon: "fl:settings_20_regular"
        title: "Sound and microphone"
        description: "Let this app play sound and use the microphone"
        FluentToggle {
            checked: !!page.perms.sound
            onToggled: (c) => Backend.appsSetPerm(page.appId, "sound", c)
        }
    }
    SettingsCard {
        visible: !!info.isFlatpak && havePerms
        icon: "fl:apps_20_regular"
        title: "Devices"
        description: "Let this app use hardware such as the GPU, cameras and game controllers"
        FluentToggle {
            checked: !!page.perms.devices
            onToggled: (c) => Backend.appsSetPerm(page.appId, "devices", c)
        }
    }
    ExpanderCard {
        visible: !!info.isFlatpak && havePerms
        icon: "fl:folder_20_regular"
        title: "File access"
        description: "Folders this app can read and write"
        expanded: true
        Repeater {
            model: Backend.appsFsList()
            delegate: ExpanderRow {
                id: fr
                required property var modelData
                readonly property var st: (page.perms.fs || ({}))[modelData.token] || [false, false]
                title: modelData.label
                description: st[0] && st[1] ? "Read-only" : ""
                FluentToggle {
                    checked: !!fr.st[0]
                    onToggled: (c) => Backend.appsSetPerm(page.appId, "fs:" + fr.modelData.token, c)
                }
            }
        }
    }
    SettingsCard {
        visible: !!info.isFlatpak && havePerms
        icon: "fl:arrow_clockwise_20_regular"
        title: "Reset"
        description: "Remove your changes and use the permissions this app ships with"
        FluentButton { text: "Reset"; onClicked: Backend.appsResetPerms(page.appId) }
    }
    SettingsCard {
        visible: !!info.name && !info.isFlatpak
        icon: "fl:info_20_regular"
        title: "No adjustable permissions"
        description: "Only Flatpak apps run in a sandbox with permissions you can change"
    }
}
