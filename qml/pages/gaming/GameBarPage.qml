import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 › Gaming › Game Bar. Linux has no Game Bar; the row is kept, disabled.
SettingsPage {
    crumbs: ["Gaming", "Game Bar"]

    SettingsCard {
        enabled: false
        icon: "fl:xbox_controller_20_regular"
        title: "Allow your controller to open Game Bar"
        description: "Not available on Linux"
        FluentToggle { checked: false }
    }
}
