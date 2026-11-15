import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accessibility", "Narrator"]

    Component.onCompleted: Backend.a11yCfgReload()

    SettingsCard {
        icon: "fl:person_voice_20_regular"
        title: "Narrator"
        description: "Hear text and controls on the screen read aloud (Orca screen reader)"
        A11yCfgToggle { group: "ScreenReader"; key: "Enabled" }
    }
}
