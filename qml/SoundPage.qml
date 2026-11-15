import QtQuick
import QtQuick.Layouts
import WinSettings
import "."

SettingsPage {
    id: page
    crumbs: ["System", "Sound"]

    Component.onCompleted: Backend.refreshSound()
    Timer {  // follow volume changes made elsewhere (keyboard keys, tray)
        interval: 2000
        repeat: true
        running: true
        onTriggered: if (!outSlider.pressed && !inSlider.pressed) Backend.refreshSound()
    }

    FText {
        visible: !Backend.soundAvailable
        text: "pactl isn't installed, so sound settings can't be read."
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
    }

    // ---------------------------------------------------------- output
    SectionHeader { text: "Output"; Layout.topMargin: 0 }

    SettingsCard {
        icon: "fl:speaker_2_20_regular"
        title: "Choose where to play sound"
        description: Backend.sinks.length ? "" : "No output devices found"
        FluentCombo {
            minWidth: 260
            model: Backend.sinks
            currentIndex: Backend.sinkIndex
            onActivated: (i) => Backend.setOutputDevice(i)
        }
    }
    SettingsCard {
        icon: Backend.outputMuted ? "fl:speaker_mute_20_regular" : "fl:speaker_2_20_regular"
        title: "Volume"
        IconButton {
            icon: Backend.outputMuted ? "fl:speaker_mute_20_regular" : "fl:speaker_2_20_regular"
            onClicked: Backend.setOutputMuted(!Backend.outputMuted)
        }
        FluentSlider {
            id: outSlider
            from: 0; to: 100; stepSize: 1
            value: Backend.outputVolume
            onMoved: Backend.setOutputVolume(Math.round(value))
        }
        FText { text: Math.round(outSlider.value); Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
    }

    // ---------------------------------------------------------- input
    SectionHeader { text: "Input" }

    SettingsCard {
        icon: "fl:mic_20_regular"
        title: "Choose a device for speaking or recording"
        description: Backend.sources.length ? "" : "No input devices found"
        FluentCombo {
            minWidth: 260
            model: Backend.sources
            currentIndex: Backend.sourceIndex
            onActivated: (i) => Backend.setInputDevice(i)
        }
    }
    SettingsCard {
        icon: Backend.inputMuted ? "fl:mic_off_20_regular" : "fl:mic_20_regular"
        title: "Volume"
        IconButton {
            icon: Backend.inputMuted ? "fl:mic_off_20_regular" : "fl:mic_20_regular"
            onClicked: Backend.setInputMuted(!Backend.inputMuted)
        }
        FluentSlider {
            id: inSlider
            from: 0; to: 100; stepSize: 1
            value: Backend.inputVolume
            onMoved: Backend.setInputVolume(Math.round(value))
        }
        FText { text: Math.round(inSlider.value); Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
    }

    // ---------------------------------------------------------- advanced
    SectionHeader { text: "Advanced" }
    SettingsCard {
        icon: "fl:desktop_speaker_20_regular"
        title: "More sound settings"
        description: "Per-app volume, profiles, sample rate"
        clickable: true
        onClicked: Backend.openKcm("kcm_pulseaudio")
    }
}
