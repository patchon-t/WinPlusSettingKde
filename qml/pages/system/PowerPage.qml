import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Power & battery"]

    readonly property var timeoutLabels: ["1 minute", "2 minutes", "3 minutes", "5 minutes", "10 minutes",
        "15 minutes", "20 minutes", "25 minutes", "30 minutes", "45 minutes", "1 hour", "2 hours",
        "3 hours", "4 hours", "5 hours", "Never"]
    readonly property var actionLabels: ["Do nothing", "Sleep", "Hibernate", "Shut down", "Ask what to do", "Turn off the screen"]
    readonly property var actionValues: ["0", "1", "2", "8", "16", "64"]
    readonly property var profileLabels: ["Best power efficiency", "Balanced", "Best performance"]
    readonly property var profileValues: ["power-saver", "balanced", "performance"]
    readonly property string rc: "powerdevilrc"
    readonly property bool bat: Backend.batteryPresent
    readonly property bool plugged: Backend.batteryStatus !== "Discharging"

    property int idleAction: 1
    function refreshIdle() { idleAction = Backend.sysIdleAction() }
    Component.onCompleted: { Backend.sysCfgReload(); Backend.refreshPower(); refreshIdle() }
    Connections { target: Backend; function onSysCfgChanged() { page.refreshIdle() } }
    Timer { interval: 10000; repeat: true; running: true; onTriggered: Backend.refreshPower() }

    function batteryIcon(p) {
        return p >= 90 ? "fl:battery_10_20_regular" : p >= 65 ? "fl:battery_7_20_regular"
             : p >= 40 ? "fl:battery_5_20_regular" : p >= 15 ? "fl:battery_3_20_regular" : "fl:battery_0_20_regular"
    }
    // Timeout combo bound to PowerDevil's profile keys
    component TimeoutCombo: FluentCombo {
        property string profile
        property string what
        model: page.timeoutLabels
        currentIndex: { Backend.sysCfgRev; return Backend.powerTimeoutIndex(profile, what) }
        onActivated: (i) => Backend.setPowerTimeout(profile, what, i)
    }
    // Combo for a powerdevilrc key with a list of raw values (powerdevilrc + refreshStatus)
    component PwrCombo: FluentCombo {
        property string group
        property string key
        property string def: ""
        property var values: []
        currentIndex: {
            Backend.sysCfgRev
            const i = values.indexOf(Backend.sysCfg(page.rc, group, key, def))
            return i
        }
        onActivated: (i) => Backend.sysPowerSet(group, key, String(values[i]))
    }

    // ---------------------------------------------------------- battery header
    RowLayout {
        visible: page.bat
        Layout.fillWidth: true
        Layout.bottomMargin: 12
        spacing: 16
        Icon {
            name: Backend.batteryStatus === "Charging" ? "fl:battery_charge_20_regular" : page.batteryIcon(Backend.batteryPercent)
            size: 48
        }
        ColumnLayout {
            spacing: 0
            FText { text: Backend.batteryPercent + "%"; font.pixelSize: 40; font.weight: Font.DemiBold }
            FText {
                text: (Backend.batteryStatus === "Charging" ? "Charging"
                      : Backend.batteryStatus === "Full" ? "Fully charged"
                      : Backend.batteryStatus === "Not charging" ? "Plugged in, not charging" : "On battery")
                      + (Backend.batteryRemaining.length && Backend.batteryStatus === "Discharging"
                         ? "  ·  Estimated time remaining: " + Backend.batteryRemaining : "")
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
            }
        }
    }
    SettingsCard {
        visible: page.bat && Backend.batteryChargeLimit > 0
        icon: "fl:battery_charge_20_regular"
        title: "Battery charge limit"
        description: "Your battery stops charging at " + Backend.batteryChargeLimit + "% to extend its life"
    }
    SettingsCard {
        visible: page.bat
        enabled: false
        icon: "fl:data_usage_20_regular"
        title: "Battery levels"
        description: "Not available yet"
    }

    // ---------------------------------------------------------- power
    SectionHeader { text: "Power"; Layout.topMargin: page.bat ? 8 : 0 }

    ExpanderCard {
        icon: "fl:desktop_20_regular"
        title: "Screen, sleep, & hibernate timeouts"
        description: "Choose when your screen turns off and your device sleeps"
        expanded: true
        ExpanderRow {
            title: "On battery power, turn off my screen after"
            visible: page.bat
            divider: false
            TimeoutCombo { profile: "Battery"; what: "screen" }
        }
        ExpanderRow {
            title: page.bat ? "When plugged in, turn off my screen after" : "Turn off my screen after"
            divider: page.bat
            TimeoutCombo { profile: "AC"; what: "screen" }
        }
        ExpanderRow {
            title: "On battery power, put my device to sleep after"
            visible: page.bat
            TimeoutCombo { profile: "Battery"; what: "sleep" }
        }
        ExpanderRow {
            title: page.bat ? "When plugged in, put my device to sleep after" : "Put my device to sleep after"
            TimeoutCombo { profile: "AC"; what: "sleep" }
        }
        ExpanderRow {
            title: "When idle, my device will"
            description: "Plasma uses one idle action, so sleep and hibernate share the timeouts above"
            FluentCombo {
                model: ["Sleep", "Hibernate"]
                currentIndex: page.idleAction === 2 ? 1 : 0
                onActivated: (i) => Backend.sysSetIdleAction(i === 0 ? 1 : 2)
            }
        }
    }

    ExpanderCard {
        icon: "fl:gauge_20_regular"
        title: "Power mode"
        description: Backend.powerProfiles.length ? "Optimize your device based on power use and performance"
                                                  : "power-profiles-daemon isn't running"
        enabled: Backend.powerProfiles.length > 0
        headerControls: [
            FluentCombo {
                minWidth: 200
                model: Backend.powerProfiles
                currentIndex: Backend.powerProfileIndex
                onActivated: (i) => Backend.setPowerProfile(i)
            }
        ]
        ExpanderRow {
            title: page.bat ? "Plugged in" : "Default power mode"
            description: "Power mode PowerDevil switches to on this power source"
            divider: false
            PwrCombo { group: "AC/Performance"; key: "PowerProfile"; values: page.profileValues; model: page.profileLabels }
        }
        ExpanderRow {
            title: "On battery"
            visible: page.bat
            PwrCombo { group: "Battery/Performance"; key: "PowerProfile"; values: page.profileValues; model: page.profileLabels }
        }
    }

    ExpanderCard {
        visible: page.bat
        icon: "fl:leaf_two_20_regular"
        title: "Energy saver"
        description: Backend.powerProfileIds.length && Backend.powerProfileIds[Backend.powerProfileIndex] === "power-saver"
                     ? "Energy saver is on" : "Extend battery life by limiting some notifications and background activity"
        ExpanderRow {
            title: "Always use energy saver"
            description: "Switches the power mode to Best power efficiency"
            divider: false
            enabled: Backend.powerProfiles.length > 0
            FluentToggle {
                checked: Backend.powerProfileIds.length > 0 && Backend.powerProfileIds[Backend.powerProfileIndex] === "power-saver"
                onToggled: (c) => Backend.sysSetPowerProfileId(c ? "power-saver" : "balanced")
            }
        }
        ExpanderRow {
            title: "Turn energy saver on automatically at"
            FluentCombo {
                readonly property var vals: ["5", "10", "15", "20", "25", "30", "40", "50"]
                model: ["5%", "10%", "15%", "20%", "25%", "30%", "40%", "50%"]
                currentIndex: { Backend.sysCfgRev; return vals.indexOf(Backend.sysCfg(page.rc, "BatteryManagement", "BatteryLowLevel", "10")) }
                onActivated: (i) => Backend.sysSetLowBatteryLevel(parseInt(vals[i]))
            }
        }
        ExpanderRow {
            title: "Lower screen brightness when using energy saver"
            FluentToggle {
                checked: { Backend.sysCfgRev; return Backend.sysCfg(page.rc, "LowBattery/Display", "UseProfileSpecificDisplayBrightness", "true") === "true" }
                onToggled: (c) => Backend.sysPowerSet("LowBattery/Display", "UseProfileSpecificDisplayBrightness", c ? "true" : "false")
            }
        }
    }

    ExpanderCard {
        icon: "fl:plug_connected_20_regular"
        title: "Lid & power controls"
        description: "Choose what the power button and closing the lid do"
        ExpanderRow {
            title: page.bat ? "Pressing the power button on battery will make my PC" : "Pressing the power button will make my PC"
            divider: false
            PwrCombo {
                group: page.bat ? "Battery/SuspendAndShutdown" : "AC/SuspendAndShutdown"; key: "PowerButtonAction"; def: "16"
                minWidth: 190; values: page.actionValues; model: page.actionLabels
            }
        }
        ExpanderRow {
            title: "When plugged in, pressing the power button will make my PC"
            visible: page.bat
            PwrCombo { group: "AC/SuspendAndShutdown"; key: "PowerButtonAction"; def: "16"; minWidth: 190; values: page.actionValues; model: page.actionLabels }
        }
        ExpanderRow {
            title: page.bat ? "Closing the lid on battery will make my PC" : "Closing the lid will make my PC"
            visible: page.bat
            PwrCombo { group: "Battery/SuspendAndShutdown"; key: "LidAction"; def: "1"; minWidth: 190; values: page.actionValues; model: page.actionLabels }
        }
        ExpanderRow {
            title: "When plugged in, closing the lid will make my PC"
            visible: page.bat
            PwrCombo { group: "AC/SuspendAndShutdown"; key: "LidAction"; def: "1"; minWidth: 190; values: page.actionValues; model: page.actionLabels }
        }
        ExpanderRow {
            title: "Keep running when the lid is closed with an external display"
            visible: page.bat
            description: "Ignores the lid action while a monitor is connected"
            FluentToggle {
                checked: { Backend.sysCfgRev; return Backend.sysCfg(page.rc, "AC/SuspendAndShutdown", "InhibitLidActionWhenExternalMonitorPresent", "true") === "true" }
                onToggled: (c) => { Backend.sysPowerSet("AC/SuspendAndShutdown", "InhibitLidActionWhenExternalMonitorPresent", c ? "true" : "false")
                                    Backend.sysPowerSet("Battery/SuspendAndShutdown", "InhibitLidActionWhenExternalMonitorPresent", c ? "true" : "false") }
            }
        }
    }

    ExpanderCard {
        visible: page.bat
        icon: "fl:battery_3_20_regular"
        title: "Critical battery"
        description: "What happens when the battery is almost empty"
        ExpanderRow {
            title: "Critical battery level"
            divider: false
            PwrCombo { group: "BatteryManagement"; key: "BatteryCriticalLevel"; def: "5"
                       values: ["2", "3", "5", "7", "10"]; model: ["2%", "3%", "5%", "7%", "10%"] }
        }
        ExpanderRow {
            title: "At the critical level, my PC will"
            PwrCombo { group: "BatteryManagement"; key: "BatteryCriticalAction"; def: "2"; minWidth: 190
                       values: ["0", "1", "2", "8"]; model: ["Do nothing", "Sleep", "Hibernate", "Shut down"] }
        }
    }
}
