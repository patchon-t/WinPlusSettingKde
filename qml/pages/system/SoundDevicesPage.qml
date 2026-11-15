import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Sound", "All sound devices"]

    Component.onCompleted: Backend.refreshSound()
    readonly property var disabledCards: Backend.sysSoundCards.filter(c => c.disabled)

    SectionHeader { text: "Output devices"; Layout.topMargin: 0 }
    FText {
        visible: Backend.sysSinkDevices.length === 0
        text: "No output devices found"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
    }
    Repeater {
        model: Backend.sysSinkDevices
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:speaker_2_20_regular"
            title: modelData.desc
            description: modelData.isDefault ? "Default" : ""
            clickable: true
            onClicked: Router.open("pages/system/SoundDevicePage.qml",
                                   { kind: "sink", name: modelData.name, card: modelData.card })
        }
    }

    SectionHeader { text: "Input devices" }
    FText {
        visible: Backend.sysSourceDevices.length === 0
        text: "No input devices found"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
    }
    Repeater {
        model: Backend.sysSourceDevices
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:mic_20_regular"
            title: modelData.desc
            description: modelData.isDefault ? "Default" : ""
            clickable: true
            onClicked: Router.open("pages/system/SoundDevicePage.qml",
                                   { kind: "source", name: modelData.name, card: modelData.card })
        }
    }

    SectionHeader { text: "Disabled devices"; visible: page.disabledCards.length > 0 }
    Repeater {
        model: page.disabledCards
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:headphones_20_regular"
            title: modelData.desc
            description: "Not allowed to be used by apps and the system"
            clickable: true
            onClicked: Router.open("pages/system/SoundDevicePage.qml",
                                   { kind: "sink", name: "", card: modelData.name })
        }
    }
}
