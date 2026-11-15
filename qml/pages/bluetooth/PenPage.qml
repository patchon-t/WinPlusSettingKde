import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > Pen & Windows Ink (BT.PEN.*): drawing tablets via org.kde.KWin.InputDevice
SettingsPage {
    id: page
    crumbs: ["Bluetooth & devices", "Pen & Windows Ink"]

    readonly property var dev: Backend.penDevices.length ? Backend.penDevices[0] : null
    readonly property bool has: dev !== null
    function v(name, def) { return dev && dev[name] !== undefined ? dev[name] : def }
    function set(name, value) { Backend.setInputProperty("pen", name, value) }

    Component.onCompleted: Backend.refreshInputDevices()

    SettingsCard {
        visible: !page.has
        icon: "fl:pen_20_regular"
        title: Backend.inputDevicesLoading ? "Looking for pens…" : "No pen or drawing tablet found"
        description: "Connect a drawing tablet to change how its pen behaves."
    }
    SettingsCard {
        visible: page.has
        icon: "fl:pen_20_regular"
        title: page.v("name", "")
        description: "Drawing tablet"
    }

    SettingsCard {
        enabled: page.has && page.v("supportsLeftHanded", false)
        icon: "fl:hand_draw_20_regular"
        title: "Choose which hand you write with"
        description: "Rotates the pen mapping for left-handed use"
        FluentCombo {
            minWidth: 120
            model: ["Right", "Left"]
            currentIndex: page.v("leftHanded", false) ? 1 : 0
            onActivated: (i) => page.set("leftHanded", i === 1)
        }
    }

    SettingsCard {
        enabled: page.has
        icon: "fl:desktop_20_regular"
        title: "Map the pen to all displays"
        description: "Use the whole desktop instead of a single display"
        FluentToggle {
            checked: page.v("mapToWorkspace", false)
            onToggled: (c) => page.set("mapToWorkspace", c)
        }
    }

    SettingsCard {
        visible: page.v("supportsRotation", false)
        icon: "fl:arrow_sync_20_regular"
        title: "Tablet orientation"
        description: "Rotate the area the pen reports in"
        FluentCombo {
            minWidth: 120
            model: ["0°", "90°", "180°", "270°"]
            currentIndex: Math.max(0, Math.min(3, Math.round(page.v("rotation", 0) / 90)))
            onActivated: (i) => page.set("rotation", i * 90)
        }
    }

    ExpanderCard {
        visible: page.v("supportsPressureRange", false)
        icon: "fl:pen_20_regular"
        title: "Pen pressure"
        description: "Range of pressure the pen responds to"
        expanded: true
        ExpanderRow {
            title: "Minimum pressure"
            divider: false
            FText { text: Math.round(pmin.value * 100) + "%"; color: Theme.textSecondary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
            FluentSlider {
                id: pmin
                from: 0
                to: 1
                value: page.v("pressureRangeMin", 0)
                onMoved: page.set("pressureRangeMin", value)
            }
        }
        ExpanderRow {
            title: "Maximum pressure"
            FText { text: Math.round(pmax.value * 100) + "%"; color: Theme.textSecondary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
            FluentSlider {
                id: pmax
                from: 0
                to: 1
                value: page.v("pressureRangeMax", 1)
                onMoved: page.set("pressureRangeMax", value)
            }
        }
    }
}
