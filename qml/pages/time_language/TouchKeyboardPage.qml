import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Time & language", "Typing", "Touch keyboard"]

    Component.onCompleted: Backend.refreshTyping()

    SettingsCard {
        icon: "fl:keyboard_dock_20_regular"
        title: "Show the touch keyboard"
        description: Backend.touchKeyboardAvailable ? "Show the on-screen keyboard when you tap a text field"
                     : "Not available: needs a Wayland session with a virtual keyboard (KWin)"
        enabled: Backend.touchKeyboardAvailable
        FluentToggle {
            checked: Backend.touchKeyboardActive
            onToggled: (c) => Backend.setTouchKeyboardActive(c)
        }
    }
}
