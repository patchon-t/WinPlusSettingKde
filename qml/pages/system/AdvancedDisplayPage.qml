import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Display", "Advanced display"]

    Component.onCompleted: Backend.reloadOutputs()

    SysDisplayPicker { id: picker }
    readonly property var cur: picker.current

    function modeText(c) {
        return c.curW + " × " + c.curH + ", " + c.curRate.toFixed(3).replace(/\.?0+$/, "") + " Hz"
    }
    readonly property var infoRows: {
        const c = page.cur
        if (!c) return []
        const r = [
            { k: "Desktop mode", v: modeText(c) + (c.scale !== 1 ? " (scaled " + c.scalePercent + "%)" : "") },
            { k: "Active signal mode", v: modeText(c) },
            { k: "Connector", v: c.name },
            { k: "Position", v: c.x + ", " + c.y }
        ]
        if (c.bpcSupported) r.push({ k: "Bit depth", v: c.maxBpc === 0 ? "Automatic" : c.maxBpc + "-bit" })
        if (c.hdrSupported) r.push({ k: "Color space", v: c.hdr ? "High dynamic range (HDR)" : "Standard dynamic range (SDR)" })
        if (c.colorSource.length) r.push({ k: "Color profile source", v: c.colorSource })
        return r
    }

    SysInfoCard {
        icon: "fl:info_20_regular"
        title: page.cur ? page.cur.title + ": " + page.cur.name : "Display information"
        rows: page.infoRows
        visible: !!page.cur
    }

    SettingsCard {
        icon: "fl:top_speed_20_regular"
        title: "Choose a refresh rate"
        description: "A higher rate gives smoother motion, but uses more power"
        enabled: !!page.cur
        FluentCombo {
            minWidth: 140
            model: page.cur ? page.cur.rates : []
            currentIndex: page.cur ? page.cur.rateIndex : -1
            onActivated: (i) => Backend.setRefresh(page.cur.name, page.cur.rateValues[i])
        }
    }
    SettingsCard {
        visible: !!(page.cur && page.cur.vrrSupported)
        icon: "fl:top_speed_20_regular"
        title: "Dynamic refresh rate"
        description: "Lets the display change its refresh rate to match the content"
        FluentCombo {
            minWidth: 140
            model: ["Off", "Automatic", "Always"]
            currentIndex: page.cur ? page.cur.vrrIndex : 0
            onActivated: (i) => Backend.sysSetVrr(page.cur.name, i)
        }
    }
    SettingsCard {
        visible: !!(page.cur && page.cur.bpcSupported)
        icon: "fl:color_20_regular"
        title: "Maximum bits per color"
        description: "Limit the color depth sent to this display"
        FluentCombo {
            readonly property var vals: [0, 6, 8, 10, 12, 16]
            minWidth: 140
            model: ["Automatic", "6-bit", "8-bit", "10-bit", "12-bit", "16-bit"]
            currentIndex: page.cur ? Math.max(0, vals.indexOf(page.cur.maxBpc)) : 0
            onActivated: (i) => Backend.sysSetMaxBpc(page.cur.name, vals[i])
        }
    }
    SettingsCard {
        visible: !!(page.cur && page.cur.rgbSupported)
        icon: "fl:color_20_regular"
        title: "RGB range"
        description: "Change this if blacks look washed out or crushed"
        FluentCombo {
            minWidth: 140
            model: ["Automatic", "Full", "Limited"]
            currentIndex: page.cur ? page.cur.rgbIndex : 0
            onActivated: (i) => Backend.sysSetRgbRange(page.cur.name, i)
        }
    }
}
