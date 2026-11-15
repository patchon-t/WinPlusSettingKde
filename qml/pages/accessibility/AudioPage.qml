import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accessibility", "Audio"]

    readonly property bool flash: {
        Backend.a11yCfgRev
        return Backend.a11yCfg("kaccessrc", "Bell", "VisibleBell", "false") === "true"
    }

    Component.onCompleted: Backend.a11yCfgReload()

    SettingsCard {
        icon: "fl:speaker_2_20_regular"
        title: "Mono audio"
        description: "Not available on Linux"
        enabled: false
        FluentToggle { checked: false }
    }

    ExpanderCard {
        icon: "fl:alert_20_regular"
        title: "Flash my screen during audio notifications"
        description: "Flash the screen when the system plays a notification sound"
        expanded: page.flash
        headerControls: [
            A11yCfgToggle { group: "Bell"; key: "VisibleBell" }
        ]
        ExpanderRow {
            title: "Invert screen colors when flashing"
            description: "Instead of flashing a color"
            A11yCfgToggle { group: "Bell"; key: "VisibleBellInvert" }
        }
        ExpanderRow {
            title: "Flash duration"
            A11yIntSlider { group: "Bell"; key: "VisibleBellPause"; fallback: 500; from: 100; to: 2000; stepSize: 50; suffix: " ms" }
        }
    }
}
