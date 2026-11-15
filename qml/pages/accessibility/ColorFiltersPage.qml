import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accessibility", "Color filters"]

    readonly property var names: ["Inverted", "Grayscale", "Grayscale inverted",
                                  "Red-green (green weak, deuteranopia)",
                                  "Red-green (red weak, protanopia)",
                                  "Blue-yellow (tritanopia)"]
    function plug(id, def) {
        Backend.a11yCfgRev
        return Backend.a11yCfg("kwinrc", "Plugins", id + "Enabled", def) === "true"
    }
    readonly property bool invertOn: plug("invert", "false")
    readonly property bool cbOn: plug("colorblindnesscorrection", "false")
    readonly property int mode: {
        Backend.a11yCfgRev
        return parseInt(Backend.a11yCfg("kwinrc", "Effect-colorblindnesscorrection", "Mode", "0")) || 0
    }
    readonly property bool active: invertOn || cbOn
    // Mode enum: 0 protanopia, 1 deuteranopia, 2 tritanopia, 3 monochrome
    readonly property int shown: {
        if (cbOn && mode === 3) return invertOn ? 2 : 1
        if (cbOn) return mode === 1 ? 3 : mode === 0 ? 4 : 5
        return invertOn ? 0 : -1
    }
    property int last: 1
    readonly property int selected: shown >= 0 ? shown : last
    readonly property real intensity: {
        Backend.a11yCfgRev
        const v = parseFloat(Backend.a11yCfg("kwinrc", "Effect-colorblindnesscorrection", "Intensity", "1"))
        return isNaN(v) ? 1 : v
    }
    property real pendingIntensity: intensity
    onIntensityChanged: pendingIntensity = intensity

    Component.onCompleted: Backend.a11yCfgReload()

    ExpanderCard {
        icon: "fl:color_20_regular"
        title: "Color filters"
        description: "Apply a color filter to the screen"
        expanded: page.active
        headerControls: [
            FluentToggle {
                checked: page.active
                onToggled: (c) => Backend.a11yColorFilter(c, page.selected, page.pendingIntensity)
            }
        ]
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 56
            Layout.rightMargin: 24
            Layout.topMargin: 12
            Layout.bottomMargin: 16
            spacing: 4
            FText { text: "Choose a filter"; color: Theme.textSecondary; Layout.bottomMargin: 4 }
            Repeater {
                model: page.names
                delegate: A11yRadio {
                    required property string modelData
                    required property int index
                    text: modelData
                    checked: page.selected === index
                    onClicked: {
                        page.last = index
                        Backend.a11yColorFilter(true, index, page.pendingIntensity)
                    }
                }
            }
        }
    }

    SettingsCard {
        icon: "fl:brightness_high_20_regular"
        title: "Color intensity"
        description: "How strongly the filter is applied"
        visible: page.selected >= 1
        enabled: page.active
        FluentSlider {
            from: 0; to: 100; stepSize: 1
            value: Math.round(page.pendingIntensity * 100)
            onMoved: page.pendingIntensity = value / 100
            onPressedChanged: if (!pressed) Backend.a11yColorFilter(true, page.selected, page.pendingIntensity)
        }
        FText {
            text: Math.round(page.pendingIntensity * 100)
            Layout.preferredWidth: 32
            horizontalAlignment: Text.AlignRight
        }
    }
}
