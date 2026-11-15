import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Sound"]

    Component.onCompleted: { Backend.refreshSound(); Backend.sysCfgReload() }
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
    SettingsCard {
        enabled: false
        icon: "fl:speaker_2_20_regular"
        title: "Mono audio"
        description: "Not available on Linux"
        FluentToggle { checked: false }
    }
    SettingsCard {
        icon: "fl:bluetooth_20_regular"
        title: "Pair a new output device"
        description: "Connect a Bluetooth speaker or headphones"
        FluentButton {
            text: "Add device"
            onClicked: Router.open("pages/bluetooth/BluetoothPage.qml", {})
        }
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
        icon: "fl:headphones_20_regular"
        title: "All sound devices"
        description: "Turn devices on or off, troubleshoot, other options"
        clickable: true
        onClicked: Router.open("pages/system/SoundDevicesPage.qml", {})
    }
    SettingsCard {
        icon: "fl:options_20_regular"
        title: "Volume mixer"
        description: "App volume mix, app input & output devices"
        clickable: true
        onClicked: Router.open("pages/system/VolumeMixerPage.qml", {})
    }
    ExpanderCard {
        icon: "fl:desktop_speaker_20_regular"
        title: "More sound settings"
        description: "System sounds, volume step, maximum volume"
        ExpanderRow {
            title: "Play system sounds"
            description: "Sounds for events like errors and notifications"
            divider: false
            SysCfgToggle { cfgFile: "kdeglobals"; cfgGroup: "Sounds"; cfgKey: "Enable"; cfgDefault: true }
        }
        ExpanderRow {
            title: "Raise maximum volume to 150%"
            description: "Allow the volume sliders to go above 100%"
            SysCfgToggle { cfgFile: "plasmaparc"; cfgGroup: "General"; cfgKey: "RaiseMaximumVolume" }
        }
        ExpanderRow {
            title: "Volume step"
            description: "How much each volume key press changes the volume"
            SysCfgCombo {
                cfgFile: "plasmaparc"; cfgGroup: "General"; cfgKey: "VolumeStep"; cfgDefault: "5"
                model: ["1%", "2%", "5%", "10%"]
                values: ["1", "2", "5", "10"]
            }
        }
        ExpanderRow {
            title: "Show volume on screen"
            description: "Display an indicator when the volume changes"
            SysCfgToggle { cfgFile: "plasmaparc"; cfgGroup: "General"; cfgKey: "VolumeOsd"; cfgDefault: true }
        }
        ExpanderRow {
            title: "Play a sound when the volume changes"
            SysCfgToggle { cfgFile: "plasmaparc"; cfgGroup: "General"; cfgKey: "AudioFeedback"; cfgDefault: true }
        }
    }
}
