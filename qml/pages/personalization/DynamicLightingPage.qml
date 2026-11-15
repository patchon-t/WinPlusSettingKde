import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Dynamic Lighting"]

    SettingsCard {
        icon: "fl:lightbulb_20_regular"
        title: "Use Dynamic Lighting on my devices"
        description: "Not available on Linux. Plasma has no RGB device control."
        enabled: false
        FluentToggle { checked: false }
    }
    SettingsCard {
        icon: "fl:apps_20_regular"
        title: "Compatible apps in the foreground always control lighting"
        description: "Not available on Linux"
        enabled: false
        FluentToggle { checked: false }
    }
    SettingsCard {
        icon: "fl:color_20_regular"
        title: "Background light control"
        description: "Not available on Linux"
        enabled: false
    }
}
