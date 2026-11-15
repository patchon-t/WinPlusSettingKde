import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 › Windows Update › Advanced options. Rows with no Linux equivalent are
// hidden; the Plasma Discover options sit under Additional options.
SettingsPage {
    crumbs: ["System updates", "Advanced options"]

    Component.onCompleted: Backend.refreshUpdates()

    SettingsCard {
        enabled: false
        icon: "fl:arrow_clockwise_20_regular"
        title: "Notify me when a restart is required to finish updating"
        description: "Not available yet"
        FluentToggle { checked: false }
    }

    SectionHeader { text: "Additional options" }
    SettingsCard {
        icon: "fl:developer_board_20_regular"
        title: "Optional updates"
        description: Backend.firmwareUpdates.length
                     ? Backend.firmwareUpdates.length + " firmware update(s) available: "
                       + Backend.firmwareUpdates.map(function (f) { return f.name }).join(", ")
                     : "Firmware updates from your device maker (check for updates first)"
        FluentButton {
            text: "Install"
            enabled: Backend.firmwareUpdates.length > 0 && Backend.updatesState !== "installing"
            onClicked: Backend.installFirmwareUpdates()
        }
    }
    SettingsCard {
        icon: "fl:arrow_sync_20_regular"
        title: "Install updates automatically"
        description: "Let Discover download and install updates in the background"
        FluentToggle {
            checked: Backend.updatesAutomatic
            onToggled: (v) => Backend.setUpdatesAutomatic(v)
        }
    }
    SettingsCard {
        icon: "fl:arrow_clockwise_20_regular"
        title: "Apply system updates when restarting"
        description: "Install system packages during the next restart instead of right away"
        FluentToggle {
            checked: Backend.updatesOffline
            onToggled: (v) => Backend.setUpdatesOffline(v)
        }
    }
}
