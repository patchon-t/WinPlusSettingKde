import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Time & language", "Typing", "Advanced keyboard settings"]

    Component.onCompleted: Backend.refreshTyping()

    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Override for default input method"
        description: Backend.keyboardLayouts.length > 1 ? "Choose the keyboard layout used by default" : "Add another keyboard layout to choose a default"
        enabled: Backend.keyboardLayouts.length > 1
        FluentCombo {
            minWidth: 240
            model: Backend.keyboardLayouts.map(d => d.name)
            currentIndex: Backend.keyboardLayouts.length ? 0 : -1
            onActivated: (i) => Backend.setDefaultKeyboardLayout(i)
        }
    }
    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Let me use a different input method for each app window"
        description: "Remember the keyboard layout separately for every app window"
        FluentToggle {
            checked: Backend.keyboardSwitchMode !== 0
            onToggled: (c) => Backend.setKeyboardSwitchMode(c ? 1 : 0)
        }
    }
    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Use the desktop language bar when it's available"
        description: "Show a pop-up when the keyboard layout changes"
        FluentToggle {
            checked: Backend.keyboardOsd
            onToggled: (c) => Backend.setKeyboardOsd(c)
        }
    }
    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Input language hot keys"
        description: "Shortcut for switching between keyboard layouts"
        FluentCombo {
            minWidth: 160
            model: Backend.keyboardHotkeyNames
            currentIndex: Backend.keyboardHotkey
            onActivated: (i) => Backend.setKeyboardHotkey(i)
        }
    }

    SectionHeader { text: "Keyboard" }
    SettingsCard {
        icon: "fl:arrow_repeat_all_20_regular"
        title: "Repeat keys while held"
        description: "Keep typing a character while its key is held down"
        FluentToggle {
            checked: Backend.keyRepeatEnabled
            onToggled: (c) => Backend.setKeyRepeatEnabled(c)
        }
    }
    SettingsCard {
        icon: "fl:history_20_regular"
        title: "Repeat delay"
        description: "How long to hold a key before it starts repeating"
        enabled: Backend.keyRepeatEnabled
        FluentSlider {
            from: 100; to: 2000; stepSize: 50
            value: Backend.keyRepeatDelay
            onMoved: Backend.setKeyRepeatDelay(Math.round(value))
        }
        FText { text: Backend.keyRepeatDelay + " ms"; color: Theme.textSecondary; Layout.preferredWidth: 60 }
    }
    SettingsCard {
        icon: "fl:timer_20_regular"
        title: "Repeat rate"
        description: "How fast characters repeat while a key is held"
        enabled: Backend.keyRepeatEnabled
        FluentSlider {
            from: 2; to: 100; stepSize: 1
            value: Backend.keyRepeatRate
            onMoved: Backend.setKeyRepeatRate(Math.round(value))
        }
        FText { text: Math.round(Backend.keyRepeatRate) + " / s"; color: Theme.textSecondary; Layout.preferredWidth: 60 }
    }
    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Num Lock at startup"
        description: "State of the Num Lock key when you log in"
        FluentCombo {
            minWidth: 160
            model: ["Turn on", "Turn off", "Leave unchanged"]
            currentIndex: Backend.numLockState
            onActivated: (i) => Backend.setNumLockState(i)
        }
    }
}
