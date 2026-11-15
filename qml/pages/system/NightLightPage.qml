import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Display", "Night light"]

    readonly property int kelvin: {
        Backend.sysCfgRev
        return parseInt(Backend.sysCfg("kwinrc", "NightColor", "NightTemperature", "4500")) || 4500
    }
    readonly property bool scheduled: {
        Backend.sysCfgRev
        return Backend.sysCfg("kwinrc", "NightColor", "Mode", "DarkLight") === "DarkLight"
    }
    readonly property bool useTimes: {
        Backend.sysCfgRev
        return Backend.sysCfg("knighttimerc", "General", "Source", "Location") === "Times"
    }
    function tk(group, key, def) {
        Backend.sysCfgRev
        return Backend.sysCfg("knighttimerc", group, key, def)
    }

    Component.onCompleted: { Backend.sysCfgReload(); Backend.sysRefreshNightLight() }

    SettingsCard {
        icon: "fl:weather_moon_20_regular"
        title: "Night light"
        description: Backend.sysNightStatus.length ? Backend.sysNightStatus
                                                   : "Use warmer colors to help block blue light"
        FluentButton {
            text: Backend.nightLight ? "Turn off now" : "Turn on now"
            onClicked: Backend.sysNightTurnOn(!Backend.nightLight)
        }
    }

    SettingsCard {
        icon: "fl:brightness_high_20_regular"
        title: "Strength"
        description: "How warm the screen color gets at night"
        FluentSlider {
            id: strength
            from: 0; to: 100; stepSize: 1
            value: Math.round((6500 - page.kelvin) / 55)
            onMoved: Backend.sysNightPreview(6500 - Math.round(value) * 55)
            onPressedChanged: if (!pressed) Backend.sysNightCommit(6500 - Math.round(value) * 55)
        }
        FText {
            text: Math.round(strength.value)
            Layout.preferredWidth: 28
            horizontalAlignment: Text.AlignRight
        }
    }

    ExpanderCard {
        icon: "fl:calendar_20_regular"
        title: "Schedule night light"
        description: page.scheduled ? (page.useTimes ? "Set hours" : "Sunset to sunrise") : "Off"
        expanded: page.scheduled
        headerControls: [
            FluentToggle {
                checked: page.scheduled
                onToggled: (c) => Backend.sysNightSchedule(c)
            }
        ]
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 56
            Layout.rightMargin: 24
            Layout.topMargin: 12
            Layout.bottomMargin: 16
            spacing: 8
            SysRadio {
                text: "Sunset to sunrise"
                checked: !page.useTimes
                onClicked: Backend.sysCfgSet("knighttimerc", "General", "Source", "Location", "")
            }
            SysRadio {
                text: "Set hours"
                checked: page.useTimes
                onClicked: Backend.sysCfgSet("knighttimerc", "General", "Source", "Times", "")
            }
            RowLayout {
                visible: page.useTimes
                spacing: 16
                Layout.topMargin: 4
                FText { text: "Turn on"; color: Theme.textSecondary; Layout.preferredWidth: 60 }
                SysTimePicker {
                    value: page.tk("Times", "SunsetStart", "18:00:00")
                    onEdited: (v) => Backend.sysCfgSet("knighttimerc", "Times", "SunsetStart", v, "")
                }
                FText { text: "Turn off"; color: Theme.textSecondary; Layout.leftMargin: 16; Layout.preferredWidth: 60 }
                SysTimePicker {
                    value: page.tk("Times", "SunriseStart", "06:00:00")
                    onEdited: (v) => Backend.sysCfgSet("knighttimerc", "Times", "SunriseStart", v, "")
                }
            }
        }
    }
}
