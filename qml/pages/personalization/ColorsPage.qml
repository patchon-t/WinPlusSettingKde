import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Colors"]

    readonly property var cs: Backend.colorState

    // The Windows 11 accent palette (8 x 6)
    readonly property var paletteColors: [
        "#ffb900", "#ff8c00", "#f7630c", "#ca5010", "#da3b01", "#ef6950", "#d13438", "#ff4343",
        "#e74856", "#e81123", "#ea005e", "#c30052", "#e3008c", "#bf0077", "#c239b3", "#9a0089",
        "#0078d7", "#0063b1", "#8e8cd8", "#6b69d6", "#8764b8", "#744da9", "#b146c2", "#881798",
        "#0099bc", "#2d7d9a", "#00b7c3", "#038387", "#00b294", "#018574", "#00cc6a", "#10893e",
        "#7a7574", "#5d5a58", "#68768a", "#515c6b", "#567c73", "#486860", "#498205", "#107c10",
        "#767676", "#4c4a48", "#69797e", "#4a5459", "#647c64", "#525e54", "#847545", "#7e735f"
    ]

    Component.onCompleted: Backend.refreshColorState()

    PerPreview { Layout.bottomMargin: 12 }

    // ---------------------------------------------------------- mode
    ExpanderCard {
        id: modeCard
        icon: "fl:dark_theme_20_regular"
        title: "Choose your mode"
        description: "Change the colors that appear in Plasma and your apps"
        expanded: page.cs.custom === true
        headerControls: [
            FluentCombo {
                model: ["Light", "Dark", "Custom"]
                currentIndex: page.cs.custom ? 2 : (Backend.dark ? 1 : 0)
                onActivated: (i) => Backend.setColorMode(i)
            }
        ]
        Connections {
            target: Backend
            function onColorStateChanged() { modeCard.expanded = Backend.colorState.custom === true }
        }
        ExpanderRow {
            title: "Choose your default Plasma mode"
            description: page.cs.shellOk ? "" : "Needs the breeze-light and breeze-dark Plasma styles"
            FluentCombo {
                enabled: page.cs.shellOk === true
                model: ["Light", "Dark"]
                currentIndex: page.cs.shellDark ? 1 : 0
                onActivated: (i) => Backend.setShellDark(i === 1)
            }
        }
        ExpanderRow {
            title: "Choose your default app mode"
            FluentCombo {
                model: ["Light", "Dark"]
                currentIndex: Backend.dark ? 1 : 0
                onActivated: (i) => Backend.setDark(i === 1)
            }
        }
    }

    SettingsCard {
        icon: "fl:weather_sunny_20_regular"
        title: "Switch between light and dark automatically"
        description: "Follows the schedule set under Display > Night Light"
        FluentToggle {
            checked: page.cs.auto === true
            onToggled: (c) => Backend.setAutoLookAndFeel(c)
        }
    }

    SettingsCard {
        icon: "fl:transparency_square_20_regular"
        title: "Transparency effects"
        description: "Windows and surfaces appear translucent"
        FluentToggle {
            checked: Backend.blur
            onToggled: (c) => Backend.setBlur(c)
        }
    }

    // ---------------------------------------------------------- accent
    ExpanderCard {
        icon: "fl:color_20_regular"
        title: "Accent color"
        expanded: true
        headerControls: [
            FluentCombo {
                model: ["Manual", "Automatic"]
                currentIndex: Backend.accentAuto ? 1 : 0
                onActivated: (i) => Backend.setAccentAuto(i === 1)
            }
        ]

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 56
            Layout.rightMargin: 48
            Layout.topMargin: 16
            Layout.bottomMargin: 20
            spacing: 8
            enabled: !Backend.accentAuto
            opacity: enabled ? 1 : 0.5

            FText { text: "Recent colors"; visible: Backend.recentAccents.length > 0 }
            Flow {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                spacing: 4
                visible: Backend.recentAccents.length > 0
                Repeater {
                    model: Backend.recentAccents
                    delegate: PerSwatch {
                        required property var modelData
                        swatchColor: modelData
                        selectedColor: Backend.accent
                        onPicked: (c) => Backend.setAccent(c)
                    }
                }
            }

            FText { text: "Windows colors" }
            GridLayout {
                columns: 8
                columnSpacing: 4
                rowSpacing: 4
                Repeater {
                    model: page.paletteColors
                    delegate: PerSwatch {
                        required property var modelData
                        swatchColor: modelData
                        selectedColor: Backend.accent
                        onPicked: (c) => Backend.setAccent(c)
                    }
                }
            }
        }

        ExpanderRow {
            title: "Custom colors"
            FluentButton { text: "View colors"; onClicked: colorDialog.open() }
        }
    }

    SettingsCard {
        icon: "fl:window_20_regular"
        title: "Show accent color on Start and taskbar"
        description: "Not available on Plasma, the Plasma style decides"
        enabled: false
        FluentToggle { checked: false }
    }

    SettingsCard {
        icon: "fl:window_20_regular"
        title: "Show accent color on title bars and window borders"
        description: "Not available yet"
        enabled: false
        FluentToggle { checked: false }
    }

    ColorDialog {
        id: colorDialog
        title: "Pick a custom accent color"
        selectedColor: Backend.accent
        onAccepted: Backend.setAccent(selectedColor.toString())
    }
}
