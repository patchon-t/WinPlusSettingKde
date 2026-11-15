import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 24H2 › Gaming: Game Bar, Captures, Game Mode (+ Linux extras under Related settings)
SettingsPage {
    id: page
    crumbs: ["Gaming"]
    property string pageTitle      // set by Data.js (H.custom)
    property var items: []         // sub pages, used by search; cards below are laid out by hand

    Component.onCompleted: Backend.refreshGaming()

    SettingsCard {
        icon: "fl:xbox_controller_20_regular"
        title: "Game Bar"
        description: "Controller and keyboard shortcuts"
        clickable: true
        onClicked: Router.open("pages/gaming/GameBarPage.qml", {})
    }
    SettingsCard {
        icon: "fl:video_clip_20_regular"
        title: "Captures"
        description: "Save locations, recording preferences"
        clickable: true
        onClicked: Router.open("pages/gaming/CapturesPage.qml", {})
    }
    SettingsCard {
        icon: "fl:top_speed_20_regular"
        title: "Game Mode"
        description: "Optimize your PC for play"
        clickable: true
        onClicked: Router.open("pages/gaming/GameModePage.qml", {})
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:cursor_20_regular"
        title: "Use a game controller as a mouse"
        description: "Move the pointer and click with a connected gamepad"
        FluentToggle {
            checked: Backend.gamingControllerMouse
            onToggled: (v) => Backend.setGamingControllerMouse(v)
        }
    }
    SettingsCard {
        enabled: false
        icon: "fl:games_20_regular"
        title: "Game controllers"
        description: "Not available yet"
    }
    SettingsCard {
        icon: "fl:desktop_20_regular"
        title: "Graphics"
        description: "Variable refresh rate, screen tearing in full-screen games"
        clickable: true
        onClicked: Router.open("pages/system/GraphicsPage.qml", {})
    }
}
