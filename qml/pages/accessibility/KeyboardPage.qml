import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accessibility", "Keyboard"]

    function kb(key, def) {
        Backend.a11yCfgRev
        return Backend.a11yCfg("kaccessrc", "Keyboard", key, def) === "true"
    }
    readonly property bool sticky: kb("StickyKeys", "false")
    readonly property bool slow: kb("SlowKeys", "false")
    readonly property bool bounce: kb("BounceKeys", "false")
    readonly property bool filters: slow || bounce

    Component.onCompleted: Backend.a11yCfgReload()

    ExpanderCard {
        icon: "fl:keyboard_20_regular"
        title: "Sticky keys"
        description: "Press keyboard shortcuts one key at a time"
        expanded: page.sticky
        headerControls: [
            A11yCfgToggle { group: "Keyboard"; key: "StickyKeys" }
        ]
        ExpanderRow {
            title: "Keyboard shortcut for Sticky keys"
            description: "Press the Shift key five times to turn Sticky keys on or off"
            A11yCfgToggle { group: "Keyboard"; key: "Gestures" }
        }
        ExpanderRow {
            title: "Lock modifier keys when pressed twice in a row"
            A11yCfgToggle { group: "Keyboard"; key: "StickyKeysLatch"; fallback: true }
        }
        ExpanderRow {
            title: "Turn off Sticky keys when two keys are pressed at once"
            A11yCfgToggle { group: "Keyboard"; key: "StickyKeysAutoOff" }
        }
        ExpanderRow {
            title: "Play a sound when a modifier key is pressed"
            A11yCfgToggle { group: "Keyboard"; key: "StickyKeysBeep" }
        }
    }

    ExpanderCard {
        icon: "fl:keyboard_20_regular"
        title: "Filter keys"
        description: "Ignore brief or repeated keystrokes and change keyboard repeat rates"
        expanded: page.filters
        headerControls: [
            FluentToggle {
                checked: page.filters
                onToggled: (c) => {
                    if (c) {
                        Backend.a11yKaccessSet("Keyboard", "BounceKeys", "true", "bool")
                    } else {
                        Backend.a11yKaccessSet("Keyboard", "BounceKeys", "false", "bool")
                        Backend.a11yKaccessSet("Keyboard", "SlowKeys", "false", "bool")
                    }
                }
            }
        ]
        ExpanderRow {
            title: "Ignore repeated keystrokes"
            description: "Bounce keys: ignore a key pressed again within the delay"
            A11yCfgToggle { group: "Keyboard"; key: "BounceKeys" }
        }
        ExpanderRow {
            title: "Bounce keys delay"
            visible: page.bounce
            A11yIntSlider { group: "Keyboard"; key: "BounceKeysDelay"; fallback: 500; from: 100; to: 2000; stepSize: 50; suffix: " ms" }
        }
        ExpanderRow {
            title: "Beep when a keystroke is ignored"
            visible: page.bounce
            A11yCfgToggle { group: "Keyboard"; key: "BounceKeysRejectBeep" }
        }
        ExpanderRow {
            title: "Ignore quick keystrokes"
            description: "Slow keys: keys must be held down before they are accepted"
            A11yCfgToggle { group: "Keyboard"; key: "SlowKeys" }
        }
        ExpanderRow {
            title: "Slow keys delay"
            visible: page.slow
            A11yIntSlider { group: "Keyboard"; key: "SlowKeysDelay"; fallback: 500; from: 100; to: 2000; stepSize: 50; suffix: " ms" }
        }
        ExpanderRow {
            title: "Beep when a key is pressed"
            visible: page.slow
            A11yCfgToggle { group: "Keyboard"; key: "SlowKeysPressBeep" }
        }
        ExpanderRow {
            title: "Beep when a key is accepted"
            visible: page.slow
            A11yCfgToggle { group: "Keyboard"; key: "SlowKeysAcceptBeep" }
        }
        ExpanderRow {
            title: "Beep when a key is rejected"
            visible: page.slow
            A11yCfgToggle { group: "Keyboard"; key: "SlowKeysRejectBeep" }
        }
    }

    SettingsCard {
        icon: "fl:keyboard_123_20_regular"
        title: "Toggle keys"
        description: "Play a sound when you press Caps Lock, Num Lock and Scroll Lock"
        A11yCfgToggle { group: "Keyboard"; key: "ToggleKeysBeep" }
    }

    SettingsCard {
        icon: "fl:keyboard_dock_20_regular"
        title: "On-screen keyboard"
        description: Backend.a11yVkAvailable ? "Use the on-screen keyboard to type" : "No on-screen keyboard is available"
        FluentToggle {
            enabled: Backend.a11yVkAvailable
            checked: Backend.a11yVkActive
            onToggled: (c) => Backend.a11yVkSet(c)
        }
    }
}
