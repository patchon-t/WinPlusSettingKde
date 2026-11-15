import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accessibility", "Visual effects"]

    readonly property var timeouts: [5000, 7000, 15000, 30000, 60000, 300000]
    readonly property var timeoutLabels: ["5 seconds", "7 seconds", "15 seconds", "30 seconds", "1 minute", "5 minutes"]

    readonly property bool transparency: {
        Backend.a11yCfgRev
        return Backend.a11yCfg("kwinrc", "Plugins", "blurEnabled", "true") === "true"
    }
    readonly property bool animations: {
        Backend.a11yCfgRev
        return parseFloat(Backend.a11yCfg("kdeglobals", "KDE", "AnimationDurationFactor", "1")) !== 0
    }
    readonly property int timeoutIndex: {
        Backend.a11yCfgRev
        const v = parseInt(Backend.a11yCfg("plasmanotifyrc", "Notifications", "PopupTimeout", "5000"))
        const i = timeouts.indexOf(v)
        return i >= 0 ? i : 0
    }

    Component.onCompleted: Backend.a11yCfgReload()

    SettingsCard {
        icon: "fl:transparency_square_20_regular"
        title: "Transparency effects"
        description: "Windows and surfaces appear translucent"
        FluentToggle {
            checked: page.transparency
            onToggled: (c) => Backend.a11yTransparencySet(c)
        }
    }

    SettingsCard {
        icon: "fl:play_20_regular"
        title: "Animation effects"
        description: "Show animations in Plasma and apps"
        FluentToggle {
            checked: page.animations
            onToggled: (c) => Backend.a11yAnimationFactor(c ? 1.0 : 0.0)
        }
    }

    SettingsCard {
        icon: "fl:alert_20_regular"
        title: "Dismiss notifications after this amount of time"
        FluentCombo {
            model: page.timeoutLabels
            currentIndex: page.timeoutIndex
            onActivated: (i) => Backend.a11yCfgSet("plasmanotifyrc", "Notifications", "PopupTimeout",
                                                   String(page.timeouts[i]), "int")
        }
    }
}
