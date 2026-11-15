import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accessibility", "Contrast themes"]

    readonly property var keys: ["", "aquatic", "desert", "dusk", "nightsky"]
    readonly property var labels: ["None", "Aquatic", "Desert", "Dusk", "Night sky"]
    // Fixed preview palettes (match the shipped .colors files, not the app theme)
    readonly property var pal: ({
        "aquatic":  { bg: "#202020", fg: "#ffffff", link: "#3ff2ff", selBg: "#3ff2ff", selFg: "#000000", dis: "#a8a8a8" },
        "desert":   { bg: "#fffae8", fg: "#000000", link: "#0000a0", selBg: "#000080", selFg: "#ffffff", dis: "#505050" },
        "dusk":     { bg: "#ffffff", fg: "#000000", link: "#0000ff", selBg: "#000000", selFg: "#ffffff", dis: "#464646" },
        "nightsky": { bg: "#000000", fg: "#ffffff", link: "#ffff00", selBg: "#1aebff", selFg: "#000000", dis: "#b0b0b0" }
    })
    readonly property string active: { Backend.a11yCfgRev; return Backend.a11yContrastActive }
    property int choice: Math.max(0, keys.indexOf(active))
    onActiveChanged: choice = Math.max(0, keys.indexOf(active))
    readonly property var cur: pal[keys[choice]] || null

    Component.onCompleted: Backend.a11yCfgReload()

    A11yInfoBar {
        title: "Contrast themes change the Plasma color scheme"
        message: "Choose None to return to the color scheme you used before."
    }

    SettingsCard {
        icon: "fl:circle_half_fill_20_regular"
        title: "Contrast themes"
        description: "Color themes for low vision, light sensitivity"
        FluentCombo {
            minWidth: 160
            model: page.labels
            currentIndex: page.choice
            onActivated: (i) => page.choice = i
        }
    }

    // Preview
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 190
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        Rectangle {
            id: win
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 420)
            height: 150
            radius: 6
            color: page.cur ? page.cur.bg : Theme.windowBg
            border.width: 2
            border.color: page.cur ? page.cur.fg : Theme.cardBorder
            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8
                Text {
                    text: "Text"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: page.cur ? page.cur.fg : Theme.text
                }
                Text {
                    text: "Hyperlinks"
                    font.pixelSize: 14
                    font.underline: true
                    color: page.cur ? page.cur.link : Theme.accent
                }
                Text {
                    text: "Disabled text"
                    font.pixelSize: 14
                    color: page.cur ? page.cur.dis : Theme.textDisabled
                }
                Rectangle {
                    width: 150
                    height: 26
                    color: page.cur ? page.cur.selBg : Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: "Selected text"
                        font.pixelSize: 14
                        color: page.cur ? page.cur.selFg : Theme.textOnAccent
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        FluentButton {
            text: "Apply"
            accent: true
            enabled: !Backend.a11yContrastBusy && page.keys[page.choice] !== page.active
            onClicked: page.choice === 0 ? Backend.a11yContrastOff()
                                         : Backend.a11yContrastApply(page.keys[page.choice])
        }
    }
}
