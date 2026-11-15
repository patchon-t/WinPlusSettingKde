import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accessibility", "Magnifier"]

    readonly property var incs: [5, 10, 25, 50, 100, 150, 200, 400]
    function cfg(group, key, def) {
        Backend.a11yCfgRev
        return Backend.a11yCfg("kwinrc", group, key, def)
    }
    readonly property bool lens: cfg("Plugins", "magnifierEnabled", "false") === "true"
    readonly property bool invertOn: cfg("Plugins", "invertEnabled", "false") === "true"
    readonly property int incIdx: {
        const pct = (parseFloat(cfg("Effect-zoom", "ZoomFactor", "1.2")) - 1) * 100
        let best = 0
        for (let i = 0; i < incs.length; i++)
            if (Math.abs(incs[i] - pct) < Math.abs(incs[best] - pct)) best = i
        return best
    }
    readonly property int tracking: parseInt(cfg("Effect-zoom", "MouseTracking", "0"))
    readonly property int lensW: parseInt(cfg("Effect-magnifier", "Width", "200")) || 200
    readonly property int lensH: parseInt(cfg("Effect-magnifier", "Height", "200")) || 200
    property int wPending: lensW
    property int hPending: lensH
    onLensWChanged: wPending = lensW
    onLensHChanged: hPending = lensH

    Component.onCompleted: Backend.a11yCfgReload()

    SettingsCard {
        icon: "fl:zoom_in_20_regular"
        title: "Magnifier"
        description: "Zoom in on parts of the screen. Shortcut: Meta + Plus, Meta + Minus"
        FluentToggle {
            checked: Backend.a11yMagnifierOn
            onToggled: (c) => Backend.a11yMagnifier(c, page.lens)
        }
    }

    SettingsCard {
        icon: "fl:zoom_fit_20_regular"
        title: "Zoom increment"
        description: "How much the screen zooms with each step"
        FluentCombo {
            model: page.incs.map(p => p + "%")
            currentIndex: page.incIdx
            onActivated: (i) => Backend.a11yEffectCfgSet("zoom", "ZoomFactor",
                                                         (1 + page.incs[i] / 100).toFixed(2), "double")
        }
    }

    SettingsCard {
        icon: "fl:zoom_in_20_regular"
        title: "View"
        description: "Magnify the whole screen or an area that follows the pointer"
        FluentCombo {
            model: ["Full screen", "Lens"]
            currentIndex: page.lens ? 1 : 0
            onActivated: (i) => Backend.a11yMagnifier(Backend.a11yMagnifierOn, i === 1)
        }
    }

    SettingsCard {
        icon: "fl:arrow_maximize_20_regular"
        title: "Lens width"
        visible: page.lens
        FluentSlider {
            from: 100; to: 800; stepSize: 10
            value: page.wPending
            onMoved: page.wPending = Math.round(value)
            onPressedChanged: if (!pressed) Backend.a11yEffectCfgSet("magnifier", "Width", String(page.wPending), "int")
        }
        FText { text: page.wPending; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
    }

    SettingsCard {
        icon: "fl:arrow_maximize_20_regular"
        title: "Lens height"
        visible: page.lens
        FluentSlider {
            from: 100; to: 800; stepSize: 10
            value: page.hPending
            onMoved: page.hPending = Math.round(value)
            onPressedChanged: if (!pressed) Backend.a11yEffectCfgSet("magnifier", "Height", String(page.hPending), "int")
        }
        FText { text: page.hPending; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
    }

    SettingsCard {
        icon: "fl:color_20_regular"
        title: "Invert colors"
        description: "Invert the colors of the whole screen"
        FluentToggle {
            checked: page.invertOn
            onToggled: (c) => Backend.a11yEffectSet("invert", c)
        }
    }

    SettingsCard {
        icon: "fl:sparkle_20_regular"
        title: "Sharpen screen content while zoomed in"
        description: "Keep text and images crisp at high zoom levels"
        visible: !page.lens
        A11yCfgToggle {
            file: "kwinrc"; group: "Effect-zoom"; key: "UsePatternUpscaler"; effect: "zoom"; fallback: true
        }
    }

    SectionHeader { text: "Have Magnifier follow" }

    SettingsCard {
        icon: "fl:cursor_20_regular"
        title: "Mouse pointer"
        visible: !page.lens
        FluentToggle {
            checked: page.tracking !== 3
            onToggled: (c) => Backend.a11yEffectCfgSet("zoom", "MouseTracking", c ? "0" : "3", "int")
        }
    }

    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Keyboard focus"
        visible: !page.lens
        A11yCfgToggle {
            file: "kwinrc"; group: "Effect-zoom"; key: "EnableFocusTracking"; effect: "zoom"
        }
    }

    SettingsCard {
        icon: "fl:text_font_20_regular"
        title: "Text cursor"
        visible: !page.lens
        A11yCfgToggle {
            file: "kwinrc"; group: "Effect-zoom"; key: "EnableTextCaretTracking"; effect: "zoom"
        }
    }
}
