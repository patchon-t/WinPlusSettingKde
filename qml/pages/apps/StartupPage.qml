import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Apps > Startup  (APP.STA.1, APP.STA.3)
SettingsPage {
    id: page
    crumbs: ["Apps", "Startup"]
    property var scripts: []

    Component.onCompleted: {
        Backend.appsRefreshStartup(sortBox.currentIndex)
        scripts = Backend.appsStartupScripts()
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        spacing: 12
        FText { text: "Startup apps"; font.weight: Font.DemiBold; Layout.fillWidth: true }
        FText { text: "Sort by:"; color: Theme.textSecondary }
        FluentCombo {
            id: sortBox
            autoSelect: true
            minWidth: 150
            model: ["Name", "Status"]
            onActivated: Backend.appsRefreshStartup(currentIndex)
        }
    }

    FText {
        visible: Backend.appsStartup.length === 0
        text: "No apps start automatically when you sign in."
        color: Theme.textSecondary
        Layout.leftMargin: 4
    }
    Repeater {
        model: Backend.appsStartup
        delegate: SettingsCard {
            required property var modelData
            icon: modelData.icon
            title: modelData.name
            description: modelData.comment.length ? modelData.comment
                         : modelData.system ? "System-wide startup entry" : ""
            FluentToggle {
                checked: modelData.enabled
                onToggled: (c) => Backend.appsSetStartup(modelData.file, c)
            }
        }
    }

    SectionHeader { text: "Sign-in and sign-out scripts"; visible: page.scripts.length > 0 }
    ExpanderCard {
        visible: page.scripts.length > 0
        icon: "fl:window_console_20_regular"
        title: "Plasma scripts"
        description: "Scripts that run when your session starts or ends"
        headerControls: [
            FluentButton { text: "Open folder"; onClicked: Backend.appsOpenFolder(page.scripts[0].dir) }
        ]
        Repeater {
            model: page.scripts
            delegate: ExpanderRow {
                required property var modelData
                title: modelData.name
                description: modelData.desc
            }
        }
    }
}
