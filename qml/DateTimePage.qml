import QtQuick
import QtQuick.Layouts
import WinSettings
import "."

SettingsPage {
    id: page
    crumbs: ["Time & language", "Date & time"]

    property date now: new Date()
    Timer { interval: 1000; repeat: true; running: true; onTriggered: page.now = new Date() }
    Component.onCompleted: Backend.refreshTime()

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
            text: Qt.formatDate(page.now, "dddd, MMMM d, yyyy")
            color: Theme.textSecondary
        }
    }

    SettingsCard {
        icon: "fl:clock_20_regular"
        title: "Set time automatically"
        description: "Sync with internet time servers (NTP)"
        FluentToggle {
            checked: Backend.autoTime
            onToggled: (c) => Backend.setAutoTime(c)
        }
    }
    SettingsCard {
        icon: "fl:earth_20_regular"
        title: "Time zone"
        FluentCombo {
            minWidth: 260
            model: Backend.timezones
            currentIndex: Backend.timezones.indexOf(Backend.timezone)
            onActivated: (i) => Backend.setTimezone(Backend.timezones[i])
        }
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:calendar_20_regular"
        title: "Clock format & calendar"
        description: "12/24-hour clock, date format, first day of week"
        clickable: true
        onClicked: Backend.openKcm("kcm_regionandlang")
    }
    SettingsCard {
        icon: "fl:settings_20_regular"
        title: "Set date and time manually"
        description: "Turn off \"Set time automatically\" first"
        clickable: true
        onClicked: Backend.openKcm("kcm_clock")
    }
}
