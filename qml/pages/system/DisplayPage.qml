import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Display"]

    property int sel: 0
    readonly property var outs: Backend.outputs
    readonly property var cur: outs.length ? outs[Math.min(sel, outs.length - 1)] : null
    property var iccProfiles: []
    readonly property var modeLabels: {
        const m = ["Extend these displays", "Duplicate these displays"]
        for (let i = 0; i < page.outs.length; ++i) m.push("Show only on " + (i + 1))
        return m
    }

    Component.onCompleted: {
        Backend.reloadOutputs()
        Backend.sysRefreshBrightness()
        Backend.sysRefreshNightLight()
        iccProfiles = Backend.sysIccProfiles()
    }

    FText {
        text: page.outs.length ? "Select a display to change the settings for it. Drag displays to rearrange them."
                               : "Couldn't read display info. Is kscreen-doctor installed?"
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 8
    }

    // ---------------------------------------------------------- arrangement canvas
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

            // Snap a dropped monitor against its nearest neighbour (edge to edge) and apply.
            function dropMonitor(idx, item) {
                const me = page.outs[idx]
                const gx = arena.bbox.x + (item.x - 2 - arena.ox) / arena.k
                const gy = arena.bbox.y + (item.y - 2 - arena.oy) / arena.k
                let best = null, bestD = 1e18
                for (let j = 0; j < page.outs.length; ++j) {
                    if (j === idx || !page.outs[j].enabled) continue
                    const o = page.outs[j]
                    const clampY = Math.max(o.y - me.h + 50, Math.min(o.y + o.h - 50, gy))
                    const clampX = Math.max(o.x - me.w + 50, Math.min(o.x + o.w - 50, gx))
                    function snap(v, targets) {
                        for (let t = 0; t < targets.length; ++t)
                            if (Math.abs(v - targets[t]) < 60) return targets[t]
                        return v
                    }
                    const cands = [
                        { x: o.x + o.w, y: snap(clampY, [o.y, o.y + o.h - me.h]) },
                        { x: o.x - me.w, y: snap(clampY, [o.y, o.y + o.h - me.h]) },
                        { x: snap(clampX, [o.x, o.x + o.w - me.w]), y: o.y + o.h },
                        { x: snap(clampX, [o.x, o.x + o.w - me.w]), y: o.y - me.h }
                    ]
                    for (let c = 0; c < cands.length; ++c) {
                        const d = Math.pow(cands[c].x - gx, 2) + Math.pow(cands[c].y - gy, 2)
                        if (d < bestD) { bestD = d; best = cands[c] }
                    }
                }
                if (best)
                    Backend.sysSetOutputPosition(me.name, Math.round(best.x), Math.round(best.y))
                else
                    Backend.reloadOutputs()
            }

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
                    z: monMa.drag.active ? 10 : 0
                    color: active ? Theme.accent : Theme.monitorIdle
                    Behavior on color { ColorAnimation { duration: Theme.durFaster } }
                    border.color: active ? Qt.darker(Theme.accent, 1.25) : Theme.cardBorder
                    FText {
                        anchors.centerIn: parent
                        text: mon.modelData.label
                        font.pixelSize: 28
                        color: mon.active ? Theme.textOnAccent : Theme.text
                    }
                    MouseArea {
                        id: monMa
                        property bool moved: false
                        anchors.fill: parent
                        drag.target: page.outs.length > 1 ? mon : null
                        cursorShape: page.outs.length > 1 ? Qt.SizeAllCursor : Qt.ArrowCursor
                        onPressed: { page.sel = mon.index; moved = false }
                        onPositionChanged: if (drag.active) moved = true
                        onReleased: if (moved) arena.dropMonitor(mon.index, mon)
                    }
                }
            }
        }
        RowLayout {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            spacing: 8
            FluentButton { text: "Identify"; onClicked: Backend.identifyDisplays() }
            FluentButton { text: "Detect"; onClicked: Backend.reloadOutputs() }
        }
    }

    // ---------------------------------------------------------- brightness & color
    SectionHeader { text: "Brightness & color" }

    Repeater {
        model: Backend.sysDisplays
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:brightness_high_20_regular"
            title: modelData.internal && Backend.sysDisplays.length === 1 ? "Brightness" : modelData.label
            description: modelData.internal ? "Adjust the brightness of the built-in display"
                                            : "Adjust the brightness of this external display"
            FluentSlider {
                from: 0; to: 100
                value: modelData.value
                onMoved: Backend.sysSetDisplayBrightness(modelData.path, Math.round(value))
            }
        }
    }
    SettingsCard {
        visible: Backend.sysDisplays.length === 0 && Backend.brightnessAvailable
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
        visible: !!(page.cur && page.cur.abmSupported)
        icon: "fl:dark_theme_20_regular"
        title: "Change brightness based on content"
        description: "Adaptive backlight modulation saves power by adjusting the backlight to the picture"
        FluentCombo {
            model: ["Off", "Always"]
            currentIndex: page.cur && page.cur.abm > 0 ? 1 : 0
            onActivated: (i) => Backend.sysSetAbm(page.cur.name, i === 0 ? 0 : 2)
        }
    }
    SettingsCard {
        icon: "fl:weather_moon_20_regular"
        title: "Night light"
        description: Backend.sysNightStatus.length ? Backend.sysNightStatus : "Use warmer colors to help block blue light"
        clickable: true
        onClicked: Router.open("pages/system/NightLightPage.qml", {})
        FluentToggle {
            checked: Backend.nightLight
            onToggled: (c) => Backend.setNightLight(c)
        }
    }
    SettingsCard {
        icon: "fl:hdr_20_regular"
        title: "HDR"
        description: page.cur && page.cur.hdrSupported ? (page.cur.hdr ? "HDR is on" : "More about HDR")
                                                       : "Not supported on this display"
        clickable: true
        onClicked: Router.open("pages/system/HdrPage.qml", {})
        enabled: !!(page.cur && page.cur.hdrSupported)
        FluentToggle {
            checked: !!(page.cur && page.cur.hdr)
            onToggled: (c) => Backend.setHdr(page.cur.name, c)
        }
    }
    SettingsCard {
        visible: !!(page.cur && (page.cur.iccSupported || page.cur.colorSource.length))
        icon: "fl:color_background_20_regular"
        title: "Color profile"
        description: "Adjust the way colors appear on your screen"
        FluentCombo {
            minWidth: 220
            readonly property var items: {
                const m = [{ n: "Standard (sRGB)", p: "" }, { n: "Display's own profile", p: "edid" }]
                for (let i = 0; i < page.iccProfiles.length; ++i)
                    m.push({ n: page.iccProfiles[i].name, p: page.iccProfiles[i].path })
                return m
            }
            model: items.map(e => e.n)
            currentIndex: {
                const c = page.cur
                if (!c) return 0
                if (c.colorSource === "ICC") {
                    const i = items.findIndex(e => e.p === c.iccPath)
                    return i < 0 ? 0 : i
                }
                return c.colorSource === "EDID" ? 1 : 0
            }
            onActivated: (i) => Backend.sysSetColorProfile(page.cur.name, items[i].p)
        }
    }
    SettingsCard {
        visible: !!(page.cur && page.cur.tradeoff.length)
        icon: "fl:color_20_regular"
        title: "Automatically manage color for apps"
        description: "Prefer color accuracy over power efficiency"
        FluentToggle {
            checked: !!(page.cur && page.cur.tradeoff === "accuracy")
            onToggled: (c) => Backend.sysSetColorAccuracy(page.cur.name, c)
        }
    }

    // ---------------------------------------------------------- scale & layout
    SectionHeader { text: "Scale & layout" }

    ExpanderCard {
        icon: "fl:resize_20_regular"
        title: "Scale"
        description: "Change the size of text, apps, and other items"
        enabled: !!page.cur
        headerControls: [
            FluentCombo {
                model: page.cur && page.cur.scaleCustom ? ["Custom (" + page.cur.scalePercent + "%)"]
                                                        : ["100%", "125%", "150%", "175%", "200%"]
                currentIndex: page.cur ? page.cur.scaleIndex : 0
                onActivated: (i) => { if (!(page.cur && page.cur.scaleCustom)) Backend.setScale(page.cur.name, [1, 1.25, 1.5, 1.75, 2][i]) }
                // a custom value can't be re-picked here; choose Custom scaling below
            }
        ]
        SysLinkRow {
            title: "Custom scaling"
            description: "Enter a custom scaling size (100%-500%)"
            onClicked: Router.open("pages/system/CustomScalingPage.qml", {})
        }
    }
    SettingsCard {
        icon: "fl:full_screen_maximize_20_regular"
        title: "Display resolution"
        description: "Adjust the resolution to fit your connected display"
        enabled: !!page.cur
        FluentCombo {
            minWidth: 200
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
            minWidth: 200
            model: ["Landscape", "Portrait", "Landscape (flipped)", "Portrait (flipped)"]
            currentIndex: page.cur ? page.cur.rotationIndex : 0
            onActivated: (i) => Backend.setRotation(page.cur.name, i)
        }
    }
    ExpanderCard {
        icon: "fl:desktop_pulse_20_regular"
        title: "Multiple displays"
        description: "Choose the presentation mode for your displays"
        enabled: page.outs.length > 1
        headerControls: [
            FluentCombo {
                minWidth: 200
                model: page.modeLabels
                currentIndex: Backend.displayModeIndex
                onActivated: (i) => Backend.setDisplayMode(i)
            }
        ]
        ExpanderRow {
            title: "Make this my main display"
            description: page.cur ? page.cur.title + " (" + page.cur.name + ")" : ""
            divider: false
            FluentToggle {
                showLabel: false
                checked: !!(page.cur && page.cur.isMain)
                enabled: !!(page.cur && !page.cur.isMain)
                onToggled: (c) => { if (c) Backend.sysSetMainDisplay(page.cur.name) }
            }
        }
    }

    // ---------------------------------------------------------- related
    SectionHeader { text: "Related settings" }

    SettingsCard {
        icon: "fl:desktop_20_regular"
        title: "Advanced display"
        description: "Display information, refresh rate"
        clickable: true
        onClicked: Router.open("pages/system/AdvancedDisplayPage.qml", {})
    }
    SettingsCard {
        icon: "fl:developer_board_20_regular"
        title: "Graphics"
        description: "Variable refresh rate, screen tearing"
        clickable: true
        onClicked: Router.open("pages/system/GraphicsPage.qml", {})
    }
}
