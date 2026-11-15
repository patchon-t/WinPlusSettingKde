import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WinSettings
import "../.."
import "BtUtil.js" as U

// Bluetooth & devices > Touchpad (BT.TPD.*). Properties live on org.kde.KWin.InputDevice.
SettingsPage {
    id: page
    crumbs: ["Bluetooth & devices", "Touchpad"]

    readonly property var dev: Backend.touchpadDevices.length ? Backend.touchpadDevices[0] : null
    readonly property bool has: dev !== null
    function v(name, def) { return dev && dev[name] !== undefined ? dev[name] : def }
    function set(name, value) { Backend.setInputProperty("touchpad", name, value) }

    Component.onCompleted: Backend.refreshInputDevices()

    SettingsCard {
        visible: !page.has
        icon: "fl:tap_single_20_regular"
        title: Backend.inputDevicesLoading ? "Looking for touchpads…" : "No touchpad found"
        description: "Touchpad settings appear here when a touchpad is detected."
    }

    ExpanderCard {
        icon: "fl:tap_single_20_regular"
        title: "Touchpad"
        description: "Tap, swipe, scroll and cursor settings"
        expanded: page.has && page.v("supportsDisableEventsOnExternalMouse", false)
        enabled: page.has
        opacity: enabled ? 1 : 0.5
        headerControls: [
            FluentToggle {
                checked: page.v("enabled", true)
                onToggled: (c) => page.set("enabled", c)
            }
        ]
        ExpanderRow {
            title: "Leave touchpad on when a mouse is connected"
            divider: false
            visible: page.v("supportsDisableEventsOnExternalMouse", false)
            BtCheckBox {
                checked: !page.v("disableEventsOnExternalMouse", false)
                onToggled: (c) => page.set("disableEventsOnExternalMouse", !c)
            }
        }
    }

    SettingsCard {
        enabled: page.has && page.v("supportsPointerAcceleration", true)
        icon: "fl:cursor_hover_20_regular"
        title: "Cursor speed"
        FText { text: Math.round(speed.value); color: Theme.textSecondary; Layout.preferredWidth: 20; horizontalAlignment: Text.AlignRight }
        FluentSlider {
            id: speed
            from: 1
            to: 20
            stepSize: 1
            snapMode: Slider.SnapAlways
            value: U.speedFromAccel(page.v("pointerAcceleration", 0))
            onMoved: page.set("pointerAcceleration", U.accelFromSpeed(value))
        }
    }

    ExpanderCard {
        icon: "fl:tap_single_20_regular"
        title: "Taps"
        description: "Tap, double-tap and drag"
        expanded: true
        enabled: page.has
        opacity: enabled ? 1 : 0.5
        ExpanderRow {
            title: "Ignore the touchpad while typing"
            description: "Prevents accidental taps with your palm"
            divider: false
            visible: page.v("supportsDisableWhileTyping", false)
            FluentToggle {
                showLabel: false
                checked: page.v("disableWhileTyping", false)
                onToggled: (c) => page.set("disableWhileTyping", c)
            }
        }
        ExpanderRow {
            title: "Tap with a single finger to single-click"
            divider: page.v("supportsDisableWhileTyping", false)
            BtCheckBox { checked: page.v("tapToClick", false); onToggled: (c) => page.set("tapToClick", c) }
        }
        ExpanderRow {
            title: "Tap with two fingers to right-click"
            visible: page.v("supportsLmrTapButtonMap", false)
            BtCheckBox { checked: !page.v("lmrTapButtonMap", false); onToggled: (c) => page.set("lmrTapButtonMap", !c) }
        }
        ExpanderRow {
            title: "Tap twice and drag to multi-select"
            BtCheckBox { checked: page.v("tapAndDrag", false); onToggled: (c) => page.set("tapAndDrag", c) }
        }
        ExpanderRow {
            title: "Press the lower right corner of the touchpad to right-click"
            visible: page.v("supportsClickMethodAreas", false)
            BtCheckBox {
                checked: page.v("clickMethodAreas", false)
                onToggled: (c) => {
                    if (c)
                        page.set("clickMethodAreas", true)
                    else if (page.v("supportsClickMethodClickfinger", false))
                        page.set("clickMethodClickfinger", true)
                    else
                        page.set("clickMethodAreas", false)
                }
            }
        }
    }

    ExpanderCard {
        icon: "fl:arrow_sync_20_regular"
        title: "Scroll & zoom"
        expanded: true
        enabled: page.has
        opacity: enabled ? 1 : 0.5
        ExpanderRow {
            title: "Drag two fingers to scroll"
            divider: false
            visible: page.v("supportsScrollTwoFinger", false)
            BtCheckBox {
                checked: page.v("scrollTwoFinger", false)
                onToggled: (c) => {
                    if (c)
                        page.set("scrollTwoFinger", true)
                    else if (page.v("supportsScrollEdge", false))
                        page.set("scrollEdge", true)
                    else
                        page.set("scrollTwoFinger", false)
                }
            }
        }
        ExpanderRow {
            title: "Scrolling direction"
            divider: page.v("supportsScrollTwoFinger", false)
            visible: page.v("supportsNaturalScroll", false)
            FluentCombo {
                minWidth: 200
                model: ["Down motion scrolls down", "Down motion scrolls up"]
                currentIndex: page.v("naturalScroll", false) ? 1 : 0
                onActivated: (i) => page.set("naturalScroll", i === 1)
            }
        }
    }

    SettingsCard {
        enabled: false
        icon: "fl:hand_draw_20_regular"
        title: "Three-finger gestures"
        description: "Not available on Linux: KWin's gestures are fixed"
    }
    SettingsCard {
        enabled: false
        icon: "fl:hand_draw_20_regular"
        title: "Four-finger gestures"
        description: "Not available on Linux: KWin's gestures are fixed"
    }

    ExpanderCard {
        icon: "fl:arrow_reset_20_regular"
        title: "Reset your touchpad"
        description: "Reset touchpad settings and gestures to default"
        enabled: page.has
        opacity: enabled ? 1 : 0.5
        headerControls: [
            FluentButton { text: "Reset"; onClicked: Backend.resetTouchpadSettings() }
        ]
    }
}
