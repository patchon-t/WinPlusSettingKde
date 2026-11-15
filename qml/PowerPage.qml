import QtQuick
import QtQuick.Layouts
import WinSettings
import "."

SettingsPage {
    id: page
    crumbs: ["System", "Power & battery"]

    readonly property var timeoutLabels: ["1 minute", "2 minutes", "3 minutes", "5 minutes", "10 minutes",
        "15 minutes", "20 minutes", "25 minutes", "30 minutes", "45 minutes", "1 hour", "2 hours",
        "3 hours", "4 hours", "5 hours", "Never"]

    Component.onCompleted: Backend.refreshPower()
    Timer { interval: 10000; repeat: true; running: true; onTriggered: Backend.refreshPower() }

    function batteryIcon(p) {
        return p >= 90 ? "fl:battery_10_20_regular" : p >= 65 ? "fl:battery_7_20_regular"
             : p >= 40 ? "fl:battery_5_20_regular" : p >= 15 ? "fl:battery_3_20_regular" : "fl:battery_0_20_regular"
    }

    // ---------------------------------------------------------- battery header
    RowLayout {
        visible: Backend.batteryPresent
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
                text: Backend.batteryStatus === "Charging" ? "Charging"
                      : Backend.batteryStatus === "Full" ? "Fully charged"
                      : Backend.batteryStatus === "Not charging" ? "Plugged in, not charging" : "On battery"
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
            }
        }
    }

    // ---------------------------------------------------------- power
    SectionHeader { text: "Power"; Layout.topMargin: Backend.batteryPresent ? 8 : 0 }

    ExpanderCard {
        icon: "fl:desktop_20_regular"
        title: "Screen and sleep"
        expanded: true
        ExpanderRow {
            title: Backend.batteryPresent ? "On battery power, turn off my screen after" : "Turn off my screen after"
            visible: Backend.batteryPresent
            divider: false
            FluentCombo {
                model: page.timeoutLabels
                currentIndex: Backend.powerTimeoutIndex("Battery", "screen")
                autoSelect: true
                onActivated: (i) => Backend.setPowerTimeout("Battery", "screen", i)
            }
        }
        ExpanderRow {
            title: Backend.batteryPresent ? "When plugged in, turn off my screen after" : "Turn off my screen after"
            divider: Backend.batteryPresent
            FluentCombo {
                model: page.timeoutLabels
                currentIndex: Backend.powerTimeoutIndex("AC", "screen")
                autoSelect: true
                onActivated: (i) => Backend.setPowerTimeout("AC", "screen", i)
            }
        }
        ExpanderRow {
            title: "On battery power, put my device to sleep after"
            visible: Backend.batteryPresent
            FluentCombo {
                model: page.timeoutLabels
                currentIndex: Backend.powerTimeoutIndex("Battery", "sleep")
                autoSelect: true
                onActivated: (i) => Backend.setPowerTimeout("Battery", "sleep", i)
            }
        }
        ExpanderRow {
            title: Backend.batteryPresent ? "When plugged in, put my device to sleep after" : "Put my device to sleep after"
            FluentCombo {
                model: page.timeoutLabels
                currentIndex: Backend.powerTimeoutIndex("AC", "sleep")
                autoSelect: true
                onActivated: (i) => Backend.setPowerTimeout("AC", "sleep", i)
            }
        }
    }

    SettingsCard {
        icon: "fl:gauge_20_regular"
        title: "Power mode"
        description: Backend.powerProfiles.length ? "Optimize your device based on power use and performance"
                                                  : "power-profiles-daemon isn't running"
        enabled: Backend.powerProfiles.length > 0
        FluentCombo {
            minWidth: 200
            model: Backend.powerProfiles
            currentIndex: Backend.powerProfileIndex
            onActivated: (i) => Backend.setPowerProfile(i)
        }
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:leaf_two_20_regular"
        title: "More power settings"
        description: "Lid, power button, battery charge limit"
        clickable: true
        onClicked: Backend.openKcm("kcm_powerdevilprofilesconfig")
    }
}
