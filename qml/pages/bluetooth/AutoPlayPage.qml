import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > AutoPlay (BT.AP.1): kded device automounter
SettingsPage {
    id: page
    crumbs: ["Bluetooth & devices", "AutoPlay"]

    Component.onCompleted: Backend.refreshAutoplay()

    SettingsCard {
        icon: "fl:play_circle_20_regular"
        title: "Use AutoPlay for all media and devices"
        description: "Automatically mount removable drives and memory cards when you plug them in"
        FluentToggle {
            checked: Backend.autoplayEnabled
            onToggled: (c) => Backend.setAutoplay(c)
        }
    }
}
