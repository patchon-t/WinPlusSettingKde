import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Themes", "Window decorations"]

    readonly property var d: Backend.decoState
    // kwinrc [org.kde.kdecoration2] BorderSize values (kwin/src/kcms/decoration/utils.cpp)
    readonly property var sizeIds: ["None", "NoSides", "Tiny", "Normal", "Large", "VeryLarge", "Huge", "VeryHuge", "Oversized"]
    readonly property var sizeNames: ["No borders", "No side borders", "Tiny", "Normal", "Large", "Very large", "Huge", "Very huge", "Oversized"]
    // Button letters: M menu, S on all desktops, H help, I minimize, A maximize, X close
    readonly property var layouts: [
        { name: "Windows", left: "", right: "IAX" },
        { name: "Plasma default", left: "MSE", right: "HIAX" }
    ]
    readonly property int layoutIndex: {
        for (let i = 0; i < layouts.length; ++i)
            if (layouts[i].left === d.left && layouts[i].right === d.right)
                return i
        return -1
    }

    Component.onCompleted: Backend.refreshDecoration()

    SettingsCard {
        icon: "fl:window_20_regular"
        title: "Window decoration theme"
        description: "The decoration plugin Plasma uses for title bars"
        FText { text: d.theme || ""; color: Theme.textSecondary }
    }

    SettingsCard {
        icon: "fl:window_apps_20_regular"
        title: "Title bar buttons"
        description: page.layoutIndex < 0 ? "Custom layout: " + (d.left || "-") + " | " + (d.right || "-")
                                          : "Windows keeps minimize, maximize and close on the right"
        FluentCombo {
            model: page.layouts.map(l => l.name)
            currentIndex: page.layoutIndex
            onActivated: (i) => {
                Backend.setDecoration("left", page.layouts[i].left)
                Backend.setDecoration("right", page.layouts[i].right)
            }
        }
    }

    SettingsCard {
        icon: "fl:resize_20_regular"
        title: "Use the theme's default border size"
        FluentToggle {
            checked: d.borderAuto === true
            onToggled: (c) => Backend.setDecoration("borderAuto", c)
        }
    }

    SettingsCard {
        icon: "fl:resize_20_regular"
        title: "Window border size"
        enabled: d.borderAuto !== true
        FluentCombo {
            model: page.sizeNames
            currentIndex: Math.max(0, page.sizeIds.indexOf(d.borderSize))
            onActivated: (i) => Backend.setDecoration("borderSize", page.sizeIds[i])
        }
    }
}
