import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Time & language", "Date & time"]

    property date now: new Date()
    readonly property string clockHint: Backend.clockAvailable ? "" : "Taskbar clock not found (Plasma shell is not running)"
    property int addZoneIndex: 0

    Timer { interval: 1000; repeat: true; running: true; onTriggered: page.now = new Date() }
    Component.onCompleted: { Backend.refreshTime(); Backend.refreshClock() }

    TlDateTimeDialog {
        id: manualDialog
        onSubmitted: (d, t) => Backend.setDateTimeManually(d, t)
    }

    // big clock like Win11
    ColumnLayout {
        Layout.bottomMargin: 16
        spacing: 0
        FText {
            text: Qt.formatTime(page.now, Qt.locale().timeFormat(Locale.ShortFormat))
            font.pixelSize: 40
            font.weight: Font.DemiBold
        }
        FText {
            text: Qt.formatDate(page.now, Qt.locale().dateFormat(Locale.LongFormat))
            color: Theme.textSecondary
        }
    }

    SettingsCard {
        icon: "fl:clock_20_regular"
        title: "Set time automatically"
        description: "Keep the clock in sync with internet time servers"
        FluentToggle {
            checked: Backend.autoTime
            onToggled: (c) => Backend.setAutoTime(c)
        }
    }
    SettingsCard {
        icon: "fl:earth_20_regular"
        title: "Set time zone automatically"
        description: "Use your location to choose the time zone"
        FluentToggle {
            checked: Backend.autoTimeZone
            onToggled: (c) => Backend.setAutoTimeZone(c)
        }
    }
    SettingsCard {
        icon: "fl:globe_clock_20_regular"
        title: "Time zone"
        enabled: !Backend.autoTimeZone
        FluentCombo {
            minWidth: 300
            model: Backend.timezoneLabels
            currentIndex: Backend.timezones.indexOf(Backend.timezone)
            onActivated: (i) => Backend.setTimezone(Backend.timezones[i])
        }
    }
    SettingsCard {
        icon: "fl:calendar_clock_20_regular"
        title: "Set the date and time manually"
        description: Backend.autoTime ? "Turn off \"Set time automatically\" to change the date and time" : ""
        enabled: !Backend.autoTime
        FText {
            text: Qt.formatDateTime(page.now, "d MMM yyyy, HH:mm")
            color: Theme.textSecondary
        }
        FluentButton { text: "Change"; onClicked: manualDialog.open() }
    }

    ExpanderCard {
        icon: "fl:settings_20_regular"
        title: "Additional settings"
        ExpanderRow {
            title: "Sync now"
            description: "Not available on Linux (systemd-timesyncd syncs on its own schedule)"
            FluentButton { text: "Sync now"; enabled: false }
        }
        ExpanderRow {
            title: "Last successful time synchronization"
            FText { text: Backend.lastTimeSync.length ? Backend.lastTimeSync : "Unknown"; color: Theme.textSecondary }
        }
        ExpanderRow {
            title: "Time server"
            FText { text: Backend.timeServer.length ? Backend.timeServer : "Unknown"; color: Theme.textSecondary }
        }
    }

    // ------------------------------------------------------------ taskbar clock
    SectionHeader { text: "Taskbar clock" }
    SettingsCard {
        icon: "fl:clock_20_regular"
        title: "Show time and date in the System tray"
        description: page.clockHint
        enabled: Backend.clockAvailable
        FluentToggle {
            checked: Backend.clockShowDate
            onToggled: (c) => Backend.setClockShowDate(c)
        }
    }
    SettingsCard {
        icon: "fl:timer_20_regular"
        title: "Show seconds in system tray clock"
        description: page.clockHint
        enabled: Backend.clockAvailable
        FluentToggle {
            checked: Backend.clockShowSeconds
            onToggled: (c) => Backend.setClockShowSeconds(c)
        }
    }
    SettingsCard {
        icon: "fl:calendar_ltr_20_regular"
        title: "Show additional calendars in the taskbar"
        description: page.clockHint
        enabled: Backend.clockAvailable
        FluentCombo {
            minWidth: 220
            model: ["Don't show additional calendars", "Alternate calendar", "Astronomical events"]
            currentIndex: Backend.clockCalendarMode
            onActivated: (i) => Backend.setClockCalendarMode(i)
        }
    }
    ExpanderCard {
        icon: "fl:globe_clock_20_regular"
        title: "Additional clocks"
        description: Backend.clockExtraZones.length ? Backend.clockExtraZones.length + " additional clock(s)" : "Show clocks for other time zones in the calendar"
        enabled: Backend.clockAvailable
        Repeater {
            model: Backend.clockExtraZones
            delegate: ExpanderRow {
                required property string modelData
                required property int index
                title: modelData.replace(/_/g, " ")
                IconButton { icon: "fl:delete_20_regular"; onClicked: Backend.removeClockZone(index) }
            }
        }
        ExpanderRow {
            title: "Add a clock"
            FluentCombo {
                autoSelect: true
                minWidth: 260
                model: Backend.timezoneLabels
                currentIndex: page.addZoneIndex
                onActivated: (i) => page.addZoneIndex = i
            }
            FluentButton {
                text: "Add"
                enabled: Backend.timezones.length > 0
                onClicked: Backend.addClockZone(Backend.timezones[page.addZoneIndex])
            }
        }
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:local_language_20_regular"
        title: "Language & region"
        description: "Display language, preferred languages, regional format"
        clickable: true
        onClicked: Router.open("pages/time_language/LanguageRegionPage.qml", {})
    }
}
