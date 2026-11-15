import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 language options: language pack + keyboards for one language
SettingsPage {
    id: page
    property string code: ""
    property string name: ""
    crumbs: ["Time & language", "Language & region", name]

    readonly property int position: {
        for (let i = 0; i < Backend.preferredLanguages.length; ++i)
            if (Backend.preferredLanguages[i].code === page.code) return i
        return -1
    }
    readonly property string base: code.split("_")[0]

    Component.onCompleted: { Backend.refreshLanguage(); Backend.refreshTyping() }

    SettingsCard {
        icon: "fl:local_language_20_regular"
        title: "Windows display language"
        description: page.position === 0 ? "This is your display language" : "Use this language for Plasma and apps"
        FluentButton {
            text: "Set as display language"
            enabled: page.position > 0
            onClicked: Backend.setDisplayLanguage(page.position)
        }
    }
    SettingsCard {
        icon: "fl:arrow_sync_20_regular"
        title: "Language pack"
        description: "Installed through your distribution's package manager (language-pack-" + page.base + ")"
        enabled: false
        FluentButton { text: "Download"; enabled: false }
    }

    SectionHeader { text: "Keyboards" }
    ExpanderCard {
        icon: "fl:keyboard_20_regular"
        title: "Installed keyboards"
        description: Backend.keyboardLayouts.length + " keyboard layout(s)"
        expanded: true
        headerControls: [
            FluentButton { text: "Add a keyboard"; onClicked: Router.open("pages/time_language/KeyboardLayoutsPage.qml", {}) }
        ]
        Repeater {
            model: Backend.keyboardLayouts
            delegate: ExpanderRow {
                required property var modelData
                title: modelData.name
                description: modelData.layout + (modelData.variant.length ? " (" + modelData.variant + ")" : "")
            }
        }
    }
}
