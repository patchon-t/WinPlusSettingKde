import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    property string kind: "sink"       // "sink" (output) or "source" (input)
    property string name: ""           // pulse device name ("" when the device is disabled)
    property string card: ""           // owning card
    crumbs: ["System", "Sound", "All sound devices", "Properties"]

    readonly property bool isOut: kind === "sink"
    readonly property var dev: {
        const lst = isOut ? Backend.sysSinkDevices : Backend.sysSourceDevices
        return lst.find(d => d.name === name) || null
    }
    readonly property var cardInfo: Backend.sysSoundCards.find(c => c.name === card) || null
    readonly property string title: dev ? dev.desc : (cardInfo ? cardInfo.desc : "Sound device")

    Component.onCompleted: Backend.refreshSound()

    // header
    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        implicitHeight: 72
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            spacing: 16
            Icon { name: page.isOut ? "fl:speaker_2_20_regular" : "fl:mic_20_regular"; size: 32 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                FText { text: page.title; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                FText {
                    text: page.dev ? (page.dev.isDefault ? "Default " + (page.isOut ? "output" : "input") + " device" : "")
                                   : "Disabled"
                    visible: text.length > 0
                    font.pixelSize: Theme.fontCaption
                    color: Theme.textSecondary
                }
            }
        }
    }

    // ---------------------------------------------------------- general
    SectionHeader { text: "General"; Layout.topMargin: 0 }
    SettingsCard {
        icon: "fl:apps_20_regular"
        title: "Allow apps and system to use this device"
        description: page.card.length ? "" : "Can't tell which sound card owns this device"
        enabled: page.card.length > 0
        RowLayout {
            spacing: 8
            FluentButton {
                text: "Don't allow"
                enabled: !!page.dev
                onClicked: Backend.sysDisableCard(page.card)
            }
            FluentButton {
                text: "Allow"
                accent: !page.dev
                enabled: !page.dev
                onClicked: Backend.sysEnableCard(page.card)
            }
        }
    }
    SettingsCard {
        visible: !!page.dev
        icon: "fl:checkmark_20_regular"
        title: page.isOut ? "Set as default output device" : "Set as default input device"
        description: page.dev && page.dev.isDefault ? "This is the default device" : ""
        enabled: !!(page.dev && !page.dev.isDefault)
        FluentButton { text: "Set as default"; onClicked: Backend.sysMakeDefault(page.kind, page.name) }
    }

    // ---------------------------------------------------------- volume
    SectionHeader { text: page.isOut ? "Output settings" : "Input settings"; visible: !!page.dev }
    SettingsCard {
        visible: !!page.dev
        icon: page.dev && page.dev.mute ? (page.isOut ? "fl:speaker_mute_20_regular" : "fl:mic_off_20_regular")
                                        : (page.isOut ? "fl:speaker_2_20_regular" : "fl:mic_20_regular")
        title: "Volume"
        IconButton {
            icon: page.dev && page.dev.mute ? (page.isOut ? "fl:speaker_mute_20_regular" : "fl:mic_off_20_regular")
                                            : (page.isOut ? "fl:speaker_2_20_regular" : "fl:mic_20_regular")
            onClicked: Backend.sysSetDeviceMute(page.kind, page.name, !page.dev.mute)
        }
        FluentSlider {
            id: vol
            from: 0; to: 100; stepSize: 1
            value: page.dev ? Math.min(100, page.dev.volume) : 0
            onMoved: Backend.sysSetDeviceVolume(page.kind, page.name, Math.round(value), page.dev.balance)
        }
        FText { text: Math.round(vol.value); Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
    }
    SettingsCard {
        visible: !!(page.dev && page.dev.canBalance)
        icon: "fl:speaker_2_20_regular"
        title: "Left / right balance"
        description: "Make one channel louder than the other"
        FText { text: "L"; color: Theme.textSecondary }
        FluentSlider {
            id: bal
            from: -100; to: 100; stepSize: 1
            value: page.dev ? page.dev.balance : 0
            onMoved: Backend.sysSetDeviceVolume(page.kind, page.name, page.dev.volume, Math.round(value))
        }
        FText { text: "R"; color: Theme.textSecondary }
    }
    SettingsCard {
        visible: !!(page.dev && page.dev.ports.length > 1)
        icon: "fl:headphones_20_regular"
        title: "Port"
        description: page.isOut ? "Where the sound is sent, for example speakers or headphones"
                                : "Which input is used, for example the internal or a headset microphone"
        FluentCombo {
            minWidth: 220
            model: page.dev ? page.dev.ports : []
            currentIndex: page.dev ? page.dev.portIndex : -1
            onActivated: (i) => Backend.sysSetDevicePort(page.kind, page.name, i)
        }
    }
    SettingsCard {
        visible: !!page.dev && !page.isOut
        enabled: false
        icon: "fl:mic_20_regular"
        title: "Test your microphone"
        description: "Not available yet"
        FluentButton { text: "Start test" }
    }
}
