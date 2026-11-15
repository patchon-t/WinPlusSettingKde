import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WinSettings
import "../.."
import "BtUtil.js" as U

// Bluetooth & devices > Mouse (BT.MSE.*). Properties live on org.kde.KWin.InputDevice.
SettingsPage {
    id: page
    crumbs: ["Bluetooth & devices", "Mouse"]

    readonly property var dev: Backend.mouseDevices.length ? Backend.mouseDevices[0] : null
    readonly property bool has: dev !== null
    function v(name, def) { return dev && dev[name] !== undefined ? dev[name] : def }

    Component.onCompleted: Backend.refreshInputDevices()

    SettingsCard {
        visible: !page.has
        icon: "fl:cursor_20_regular"
        title: Backend.inputDevicesLoading ? "Looking for mice…" : "No mouse found"
        description: "Connect a mouse to change its settings. Pointer settings are applied by KWin."
    }

    SettingsCard {
        enabled: page.has && page.v("supportsLeftHanded", false)
        icon: "fl:cursor_click_20_regular"
        title: "Primary mouse button"
        description: "Choose which button selects and drags"
        FluentCombo {
            minWidth: 120
            model: ["Left", "Right"]
            currentIndex: page.v("leftHanded", false) ? 1 : 0
            onActivated: (i) => Backend.setInputProperty("mouse", "leftHanded", i === 1)
        }
    }

    SettingsCard {
        enabled: page.has && page.v("supportsPointerAcceleration", true)
        icon: "fl:cursor_hover_20_regular"
        title: "Mouse pointer speed"
        FText { text: Math.round(speed.value); color: Theme.textSecondary; Layout.preferredWidth: 20; horizontalAlignment: Text.AlignRight }
        FluentSlider {
            id: speed
            from: 1
            to: 20
            stepSize: 1
            snapMode: Slider.SnapAlways
            value: U.speedFromAccel(page.v("pointerAcceleration", 0))
            onMoved: Backend.setInputProperty("mouse", "pointerAcceleration", U.accelFromSpeed(value))
        }
    }

    SettingsCard {
        enabled: page.has && page.v("supportsPointerAccelerationProfileAdaptive", false)
        icon: "fl:cursor_20_regular"
        title: "Enhance pointer precision"
        description: "Accelerate the pointer when you move the mouse quickly"
        FluentToggle {
            checked: page.v("pointerAccelerationProfileAdaptive", false)
            onToggled: (c) => Backend.setInputProperty("mouse", "pointerAccelerationProfileAdaptive", c)
        }
    }

    ExpanderCard {
        icon: "fl:arrow_sync_20_regular"
        title: "Scrolling"
        expanded: true
        enabled: page.has
        opacity: enabled ? 1 : 0.5
        ExpanderRow {
            title: "Lines to scroll at a time"
            divider: false
            FText { text: Math.round(lines.value); color: Theme.textSecondary; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignRight }
            FluentSlider {
                id: lines
                from: 1
                to: 20
                stepSize: 1
                snapMode: Slider.SnapAlways
                value: Math.max(1, Math.min(20, Math.round(page.v("scrollFactor", 1) * 3)))
                onMoved: Backend.setInputProperty("mouse", "scrollFactor", value / 3)
            }
        }
        ExpanderRow {
            title: "Scroll inactive windows when hovering over them"
            FluentToggle {
                checked: Backend.mouseScrollInactiveWindows
                onToggled: (c) => Backend.setMouseScrollInactiveWindows(c)
            }
        }
        ExpanderRow {
            title: "Scrolling direction"
            visible: page.v("supportsNaturalScroll", false)
            FluentCombo {
                minWidth: 200
                model: ["Down motion scrolls down", "Down motion scrolls up"]
                currentIndex: page.v("naturalScroll", false) ? 1 : 0
                onActivated: (i) => Backend.setInputProperty("mouse", "naturalScroll", i === 1)
            }
        }
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:tap_single_20_regular"
        title: "Double-click speed"
        description: "How quickly two clicks count as a double-click (shorter is faster)"
        FText { text: Math.round(dbl.value) + " ms"; color: Theme.textSecondary; Layout.preferredWidth: 56; horizontalAlignment: Text.AlignRight }
        FluentSlider {
            id: dbl
            from: 200
            to: 2000
            stepSize: 50
            snapMode: Slider.SnapAlways
            value: Backend.mouseDoubleClickInterval
            onMoved: Backend.setMouseDoubleClickInterval(value)
        }
    }
}
