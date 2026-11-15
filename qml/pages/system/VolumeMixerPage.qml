import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Sound", "Volume mixer"]

    readonly property var outApps: Backend.sysMixerApps.filter(a => a.kind === "out")
    readonly property var inApps: Backend.sysMixerApps.filter(a => a.kind === "in")

    Component.onCompleted: Backend.sysRefreshMixer()
    Timer {
        interval: 2500
        repeat: true
        running: true
        onTriggered: if (!mixOut.pressed && !mixIn.pressed && !page.anyPressed) Backend.sysRefreshMixer()
    }
    property bool anyPressed: false

    // ---------------------------------------------------------- system
    SectionHeader { text: "System"; Layout.topMargin: 0 }
    SettingsCard {
        icon: "fl:speaker_2_20_regular"
        title: "System volume"
        description: Backend.sinks.length ? Backend.sinks[Backend.sinkIndex] || "" : "No output devices found"
        IconButton {
            icon: Backend.outputMuted ? "fl:speaker_mute_20_regular" : "fl:speaker_2_20_regular"
            onClicked: Backend.setOutputMuted(!Backend.outputMuted)
        }
        FluentSlider {
            id: mixOut
            from: 0; to: 100; stepSize: 1
            value: Backend.outputVolume
            onMoved: Backend.setOutputVolume(Math.round(value))
        }
        FText { text: Math.round(mixOut.value); Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
    }
    SettingsCard {
        icon: "fl:mic_20_regular"
        title: "System input volume"
        description: Backend.sources.length ? Backend.sources[Backend.sourceIndex] || "" : "No input devices found"
        IconButton {
            icon: Backend.inputMuted ? "fl:mic_off_20_regular" : "fl:mic_20_regular"
            onClicked: Backend.setInputMuted(!Backend.inputMuted)
        }
        FluentSlider {
            id: mixIn
            from: 0; to: 100; stepSize: 1
            value: Backend.inputVolume
            onMoved: Backend.setInputVolume(Math.round(value))
        }
        FText { text: Math.round(mixIn.value); Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
    }

    // ---------------------------------------------------------- apps
    component AppRow: SettingsCard {
        id: row
        property var app
        property var devices: []
        icon: "fl:apps_20_regular"
        title: app.name
        description: app.desc
        FluentCombo {
            minWidth: 190
            model: row.devices
            currentIndex: row.app.device
            onActivated: (i) => Backend.sysMoveApp(row.app.kind, row.app.index, i)
        }
        IconButton {
            icon: row.app.mute ? (row.app.kind === "out" ? "fl:speaker_mute_20_regular" : "fl:mic_off_20_regular")
                               : (row.app.kind === "out" ? "fl:speaker_2_20_regular" : "fl:mic_20_regular")
            onClicked: Backend.sysSetAppMute(row.app.kind, row.app.index, !row.app.mute)
        }
        FluentSlider {
            id: s
            implicitWidth: 160
            from: 0; to: 100; stepSize: 1
            value: Math.min(100, row.app.volume)
            onPressedChanged: page.anyPressed = pressed
            onMoved: Backend.sysSetAppVolume(row.app.kind, row.app.index, Math.round(value))
        }
        FText { text: Math.round(s.value); Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
    }

    SectionHeader { text: "Apps" }
    FText {
        visible: page.outApps.length === 0
        text: "No apps are playing sound right now"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
    }
    Repeater {
        model: page.outApps
        delegate: AppRow {
            required property var modelData
            app: modelData
            devices: Backend.sinks
        }
    }

    SectionHeader { text: "Apps using the microphone"; visible: page.inApps.length > 0 }
    Repeater {
        model: page.inApps
        delegate: AppRow {
            required property var modelData
            app: modelData
            devices: Backend.sources
        }
    }
}
