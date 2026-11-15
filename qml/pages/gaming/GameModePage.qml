import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 › Gaming › Game Mode. Linux's GameMode (gamemoderun) is started per game,
// so there is no system-wide switch; the row is kept, disabled, with the reason.
SettingsPage {
    crumbs: ["Gaming", "Game Mode"]

    SettingsCard {
        enabled: false
        icon: "fl:top_speed_20_regular"
        title: "Game Mode"
        description: "On Linux, Game Mode is turned on for each game (gamemoderun)"
        FluentToggle { checked: false }
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:desktop_20_regular"
        title: "Graphics"
        description: "Variable refresh rate, screen tearing in full-screen games"
        clickable: true
        onClicked: Router.open("pages/system/GraphicsPage.qml", {})
    }
}
