import QtQuick
import QtQuick.Layouts
import WinSettings
import "."

SettingsPage {
    id: page
    crumbs: ["System", "Display"]

    property int sel: 0
    readonly property var outs: Backend.outputs
    readonly property var cur: outs.length ? outs[Math.min(sel, outs.length - 1)] : null

    Component.onCompleted: Backend.reloadOutputs()

    FText {
        text: page.outs.length ? "Select a display to change the settings for it."
                               : "Couldn't read display info. Is kscreen-doctor installed?"
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 8
    }

    // ---------------------------------------------------------- arrangement preview
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 230
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder

        Item {
            id: arena
            anchors.fill: parent
            anchors.margins: 24
            anchors.bottomMargin: 60

            readonly property var bbox: {
                let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
                for (let i = 0; i < page.outs.length; ++i) {
                    const o = page.outs[i]
                    if (!o.enabled) continue
                    x0 = Math.min(x0, o.x); y0 = Math.min(y0, o.y)
                    x1 = Math.max(x1, o.x + o.w); y1 = Math.max(y1, o.y + o.h)
                }
                return x1 > x0 ? { x: x0, y: y0, w: x1 - x0, h: y1 - y0 } : { x: 0, y: 0, w: 1, h: 1 }
            }
            readonly property real k: Math.min(width / bbox.w, height / bbox.h)
            readonly property real ox: (width - bbox.w * k) / 2
            readonly property real oy: (height - bbox.h * k) / 2

            Repeater {
                model: page.outs
                delegate: Rectangle {
                    id: mon
                    required property var modelData
                    required property int index
                    readonly property bool active: index === page.sel
                    visible: modelData.enabled
                    x: arena.ox + (modelData.x - arena.bbox.x) * arena.k + 2
                    y: arena.oy + (modelData.y - arena.bbox.y) * arena.k + 2
                    width: modelData.w * arena.k - 4
                    height: modelData.h * arena.k - 4
                    radius: 4
                    color: active ? Theme.accent : Theme.monitorIdle
                    border.color: active ? Qt.darker(Theme.accent, 1.25) : Theme.cardBorder
                    FText {
                        anchors.centerIn: parent
                        text: mon.modelData.label
                        font.pixelSize: 28
                        color: mon.active ? Theme.onAccent : Theme.text
                    }
                    MouseArea { anchors.fill: parent; onClicked: page.sel = mon.index }
                }
            }
        }
        FluentButton {
            text: "Identify"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            onClicked: Backend.identifyDisplays()
        }
    }

    SettingsCard {
        icon: "fl:desktop_pulse_20_regular"
        title: "Multiple displays"
        description: "Choose the presentation mode for your displays"
        enabled: page.outs.length > 1
        FluentCombo {
            model: {
                const m = ["Extend these displays"]
                for (let i = 0; i < page.outs.length; ++i) m.push("Show only on " + (i + 1))
                return m
            }
            currentIndex: Backend.displayModeIndex
            onActivated: (i) => Backend.setDisplayMode(i)
        }
    }

    // ---------------------------------------------------------- brightness & color
    SectionHeader { text: "Brightness & color" }

    SettingsCard {
        visible: Backend.brightnessAvailable
        icon: "fl:brightness_high_20_regular"
        title: "Brightness"
        description: "Adjust the brightness of the built-in display"
        FluentSlider {
            from: 0
            to: 100
            value: Backend.brightness
            onMoved: Backend.setBrightness(Math.round(value))
        }
    }
    SettingsCard {
        icon: "fl:weather_moon_20_regular"
        title: "Night light"
        description: "Use warmer colors to help block blue light"
        clickable: true
        onClicked: Backend.openKcm("kcm_nightlight")
        FluentToggle {
            checked: Backend.nightLight
            onToggled: (c) => Backend.setNightLight(c)
        }
    }
    SettingsCard {
        icon: "fl:color_background_20_regular"
        title: "Color profile"
        description: "Adjust the way colors appear on your screen"
        clickable: true
        onClicked: Backend.openKcm("kcm_colord")
    }
    SettingsCard {
        icon: "fl:hdr_20_regular"
        title: "HDR"
        description: page.cur && page.cur.hdrSupported ? "Brighter, more vivid picture in HDR content"
                                                       : "Not supported on this display"
        enabled: !!(page.cur && page.cur.hdrSupported)
        FluentToggle {
            checked: !!(page.cur && page.cur.hdr)
            onToggled: (c) => Backend.setHdr(page.cur.name, c)
        }
    }

    // ---------------------------------------------------------- scale & layout
    SectionHeader { text: "Scale & layout" }

    SettingsCard {
        icon: "fl:resize_20_regular"
        title: "Scale"
        description: "Change the size of text, apps, and other items"
        enabled: !!page.cur
        FluentCombo {
            model: ["100%", "125%", "150%", "175%", "200%"]
            currentIndex: page.cur ? page.cur.scaleIndex : 0
            onActivated: (i) => Backend.setScale(page.cur.name, [1, 1.25, 1.5, 1.75, 2][i])
        }
    }
    SettingsCard {
        icon: "fl:full_screen_maximize_20_regular"
        title: "Display resolution"
        description: "Adjust the resolution to fit your connected display"
        enabled: !!page.cur
        FluentCombo {
            model: page.cur ? page.cur.resolutions : []
            currentIndex: page.cur ? page.cur.resIndex : -1
            onActivated: (i) => Backend.setResolution(page.cur.name, page.cur.resolutionKeys[i])
        }
    }
    SettingsCard {
        icon: "fl:rotate_right_20_regular"
        title: "Display orientation"
        enabled: !!page.cur
        FluentCombo {
            model: ["Landscape", "Portrait", "Landscape (flipped)", "Portrait (flipped)"]
            currentIndex: page.cur ? page.cur.rotationIndex : 0
            onActivated: (i) => Backend.setRotation(page.cur.name, i)
        }
    }
    SettingsCard {
        icon: "fl:top_speed_20_regular"
        title: "Refresh rate"
        description: "A higher rate gives smoother motion"
        enabled: !!page.cur
        FluentCombo {
            model: page.cur ? page.cur.rates : []
            currentIndex: page.cur ? page.cur.rateIndex : -1
            onActivated: (i) => Backend.setRefresh(page.cur.name, page.cur.rateValues[i])
        }
    }

    // ---------------------------------------------------------- related
    SectionHeader { text: "Related settings" }

    SettingsCard {
        icon: "fl:desktop_20_regular"
        title: "Advanced display"
        description: "Display information, positions, overscan"
        clickable: true
        onClicked: Backend.openKcm("kcm_kscreen")
    }
    SettingsCard {
        icon: "fl:developer_board_20_regular"
        title: "Graphics"
        description: "Graphics hardware and driver information"
        clickable: true
        onClicked: Backend.runCommand(["kinfocenter"])
    }
}
