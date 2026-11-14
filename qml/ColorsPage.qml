import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import WinSettings
import "."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Colors"]

    // The Windows 11 accent palette (8 x 6)
    readonly property var paletteColors: [
        "#ffb900", "#ff8c00", "#f7630c", "#ca5010", "#da3b01", "#ef6950", "#d13438", "#ff4343",
        "#e74856", "#e81123", "#ea005e", "#c30052", "#e3008c", "#bf0077", "#c239b3", "#9a0089",
        "#0078d7", "#0063b1", "#8e8cd8", "#6b69d6", "#8764b8", "#744da9", "#b146c2", "#881798",
        "#0099bc", "#2d7d9a", "#00b7c3", "#038387", "#00b294", "#018574", "#00cc6a", "#10893e",
        "#7a7574", "#5d5a58", "#68768a", "#515c6b", "#567c73", "#486860", "#498205", "#107c10",
        "#767676", "#4c4a48", "#69797e", "#4a5459", "#647c64", "#525e54", "#847545", "#7e735f"
    ]

    component Swatch: Rectangle {
        id: sw
        property string swatchColor
        readonly property bool selected: swatchColor.toLowerCase() === Backend.accent.toLowerCase()
        implicitWidth: 40
        implicitHeight: 40
        radius: Theme.radius
        color: "transparent"
        border.width: selected || sma.containsMouse ? 2 : 0
        border.color: Theme.text

        Rectangle {
            anchors.fill: parent
            anchors.margins: sw.selected || sma.containsMouse ? 3 : 0
            radius: 2
            color: sw.swatchColor
        }
        Rectangle {  // check badge
            visible: sw.selected
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 3
            width: 16
            height: 16
            radius: 2
            color: Theme.text
            Glyph {
                anchors.centerIn: parent
                width: 12
                height: 12
                lines: Theme.gCheck
                color: Theme.windowBg
                stroke: 1.5
            }
        }
        MouseArea {
            id: sma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Backend.setAccent(sw.swatchColor)
        }
    }

    // ---------------------------------------------------------- preview
    Rectangle {
        implicitWidth: 268
        implicitHeight: 160
        radius: Theme.radiusLarge
        color: "#111111"
        Layout.bottomMargin: 12

        Item {
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            Image {
                anchors.fill: parent
                source: Backend.wallpaperUrl
                sourceSize.width: 540
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Rectangle {  // fake window
                width: parent.width * 0.42
                height: parent.height * 0.55
                anchors.right: parent.right
                anchors.rightMargin: parent.width * 0.1
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -6
                radius: 3
                color: Theme.cardBg
                Column {
                    x: 10
                    y: 12
                    spacing: 6
                    Repeater {
                        model: [60, 50, 60, 36]
                        Rectangle { width: modelData; height: 2; color: Theme.textSecondary; opacity: 0.6 }
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    width: 20
                    height: 7
                    radius: 2
                    color: Theme.accent
                }
            }
            Rectangle {  // taskbar
                anchors.bottom: parent.bottom
                width: parent.width
                height: 14
                color: Theme.dark ? "#d0202020" : "#d0f3f3f3"
                Row {
                    anchors.centerIn: parent
                    spacing: 5
                    Repeater {
                        model: 5
                        Rectangle {
                            width: 7; height: 7; radius: 1.5
                            color: index === 0 ? Theme.accent : Theme.textSecondary
                            opacity: index === 0 ? 1 : 0.6
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------- settings
    SettingsCard {
        icon: "preferences-desktop-color|color-management"
        title: "Choose your mode"
        description: "Change the colors that appear in Plasma and your apps"
        FluentCombo {
            model: ["Light", "Dark"]
            currentIndex: Backend.dark ? 1 : 0
            onActivated: (i) => Backend.setDark(i === 1)
        }
    }

    SettingsCard {
        icon: "preferences-desktop-effects|transform-shear"
        title: "Transparency effects"
        description: "Windows and surfaces appear translucent"
        FluentToggle {
            checked: Backend.blur
            onToggled: (c) => Backend.setBlur(c)
        }
    }

    ExpanderCard {
        icon: "color-picker|preferences-desktop-color"
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
                    delegate: Swatch {
                        required property var modelData
                        swatchColor: modelData
                    }
                }
            }

            FText { text: "Accent colors" }
            GridLayout {
                columns: 8
                columnSpacing: 4
                rowSpacing: 4
                Repeater {
                    model: page.paletteColors
                    delegate: Swatch {
                        required property var modelData
                        swatchColor: modelData
                    }
                }
            }
        }

        ExpanderRow {
            title: "Custom colors"
            FluentButton { text: "View colors"; onClicked: colorDialog.open() }
        }
    }

    ColorDialog {
        id: colorDialog
        title: "Pick a custom accent color"
        selectedColor: Backend.accent
        onAccepted: Backend.setAccent(selectedColor.toString())
    }
}
