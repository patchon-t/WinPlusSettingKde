import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accessibility", "Mouse"]

    readonly property bool keysOn: {
        Backend.a11yCfgRev
        return Backend.a11yCfg("kaccessrc", "Mouse", "MouseKeys", "false") === "true"
    }

    Component.onCompleted: Backend.a11yCfgReload()

    ExpanderCard {
        icon: "fl:cursor_hover_20_regular"
        title: "Mouse keys"
        description: "Use the numeric keypad to move the mouse pointer"
        expanded: page.keysOn
        headerControls: [
            A11yCfgToggle { group: "Mouse"; key: "MouseKeys" }
        ]
        ExpanderRow {
            title: "Pointer speed"
            description: "Maximum speed in pixels per interval"
            A11yIntSlider { group: "Mouse"; key: "MKMaxSpeed"; fallback: 30; from: 1; to: 500 }
        }
        ExpanderRow {
            title: "Pointer acceleration"
            description: "Time to reach the maximum speed"
            A11yIntSlider { group: "Mouse"; key: "MKTimeToMax"; fallback: 30; from: 1; to: 100 }
        }
        ExpanderRow {
            title: "Delay before the pointer starts moving"
            A11yIntSlider { group: "Mouse"; key: "MKDelay"; fallback: 160; from: 0; to: 1000; stepSize: 10; suffix: " ms" }
        }
        ExpanderRow {
            title: "Repeat interval"
            A11yIntSlider { group: "Mouse"; key: "MKInterval"; fallback: 40; from: 10; to: 500; stepSize: 5; suffix: " ms" }
        }
    }
}
