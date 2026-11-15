import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accessibility", "Mouse pointer and touch"]

    readonly property var sizes: [24, 32, 36, 40, 48, 64, 72, 96, 128]
    property int sizeIdx: curIdx
    readonly property int curIdx: {
        Backend.a11yCfgRev
        const v = parseInt(Backend.a11yCfg("kcminputrc", "Mouse", "cursorSize", "24")) || 24
        let best = 0
        for (let i = 0; i < sizes.length; i++)
            if (Math.abs(sizes[i] - v) < Math.abs(sizes[best] - v)) best = i
        return best
    }
    readonly property var themeNames: Backend.a11yCursorThemes.map(t => t.title)
    readonly property int themeIdx: {
        for (let i = 0; i < Backend.a11yCursorThemes.length; i++)
            if (Backend.a11yCursorThemes[i].name === Backend.a11yCursorTheme) return i
        return -1
    }

    Component.onCompleted: { Backend.a11yCfgReload(); Backend.a11yRefreshCursors() }

    SettingsCard {
        icon: "fl:cursor_20_regular"
        title: "Mouse pointer style"
        description: Backend.a11yCursorThemes.length ? "Pointer themes installed on this PC"
                                                     : "No pointer themes found"
        FluentCombo {
            minWidth: 160
            enabled: Backend.a11yCursorThemes.length > 0
            model: page.themeNames
            currentIndex: page.themeIdx
            onActivated: (i) => Backend.a11yCursorThemeSet(Backend.a11yCursorThemes[i].name)
        }
    }

    SettingsCard {
        icon: "fl:text_font_size_20_regular"
        title: "Size"
        description: "Make the mouse pointer bigger"
        FluentSlider {
            id: sz
            from: 0; to: page.sizes.length - 1; stepSize: 1
            value: page.sizeIdx
            onMoved: page.sizeIdx = Math.round(value)
            onPressedChanged: if (!pressed) Backend.a11yCursorSizeSet(page.sizes[page.sizeIdx])
        }
        FText {
            text: page.sizes[page.sizeIdx]
            Layout.preferredWidth: 32
            horizontalAlignment: Text.AlignRight
        }
    }

    SettingsCard {
        icon: "fl:tap_single_20_regular"
        title: "Touch indicator"
        description: "Show a visual indicator where the screen is touched"
        FluentToggle {
            checked: { Backend.a11yCfgRev; return Backend.a11yCfg("kwinrc", "Plugins", "touchpointsEnabled", "false") === "true" }
            onToggled: (c) => Backend.a11yEffectSet("touchpoints", c)
        }
    }

    SettingsCard {
        icon: "fl:cursor_20_regular"
        title: "Shake cursor to find it"
        description: "Wiggle the mouse to briefly enlarge the pointer"
        FluentToggle {
            checked: { Backend.a11yCfgRev; return Backend.a11yCfg("kwinrc", "Plugins", "shakecursorEnabled", "true") === "true" }
            onToggled: (c) => Backend.a11yEffectSet("shakecursor", c)
        }
    }
}
