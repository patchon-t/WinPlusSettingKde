import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// One reusable page for every App-permissions entry (Location, Camera, Microphone, ...).
// Per-app state comes from Flatpak (portal permission store or sandbox overrides).
SettingsPage {
    id: page
    property string kind: "camera"
    property string title: "Camera"
    property string icon: "fl:camera_20_regular"
    property string master: ""            // Win11 master switch title; empty = none on this page
    property string masterDesc: ""
    property string letTitle: "Let apps access this"
    property string subject: "this"
    crumbs: ["Privacy & security", title]

    readonly property var apps: Backend.prvPermApps
    readonly property int allowedCount: {
        let n = 0
        for (let i = 0; i < apps.length; ++i) if (apps[i].allowed) ++n
        return n
    }

    Component.onCompleted: Backend.refreshPrvPermission(kind)

    PrvInfoBar {
        title: "Flatpak apps only"
        message: "These settings apply to Flatpak apps. Apps installed from your distribution's packages are not sandboxed and can't be restricted here."
    }

    SettingsCard {
        visible: page.master.length > 0
        enabled: false
        icon: page.icon
        title: page.master
        description: page.masterDesc
        FluentToggle { checked: true }
    }

    SettingsCard {
        icon: page.icon
        title: page.letTitle
        description: page.apps.length === 0 ? "No Flatpak apps installed"
                     : page.allowedCount + " of " + page.apps.length + " apps allowed"
        enabled: Backend.prvFlatpak && page.apps.length > 0
        FluentToggle {
            checked: page.allowedCount > 0
            onToggled: (v) => Backend.setPrvAllPermissions(page.kind, v)
        }
    }

    SectionHeader { text: "Choose which apps can access " + page.subject; visible: page.apps.length > 0 }

    Repeater {
        model: page.apps
        delegate: SettingsCard {
            required property var modelData
            title: modelData.name
            description: modelData.id
            FluentToggle {
                checked: modelData.allowed
                onToggled: (v) => Backend.setPrvAppPermission(page.kind, modelData.id, v)
            }
        }
    }

    FText {
        visible: !Backend.prvPermLoading && page.apps.length === 0
        text: Backend.prvFlatpak ? "No Flatpak apps are installed." : "Flatpak isn't installed on this system."
        color: Theme.textSecondary
        Layout.topMargin: 12
        Layout.alignment: Qt.AlignHCenter
    }
    FText {
        visible: Backend.prvPermLoading
        text: "Loading apps..."
        color: Theme.textSecondary
        Layout.topMargin: 12
        Layout.alignment: Qt.AlignHCenter
    }
}
