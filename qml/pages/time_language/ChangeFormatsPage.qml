import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 "Change formats". The patterns themselves come from the locale, so the
// date/time rows are a read-only preview; first day of week and 12/24 h are
// written to the taskbar clock.
SettingsPage {
    id: page
    crumbs: ["Time & language", "Language & region", "Change formats"]

    readonly property var loc: Qt.locale(Backend.regionalFormat.length ? Backend.regionalFormat : Qt.locale().name)
    property date now: new Date()
    readonly property var dayNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    function fmtDate(f) { return loc.toString(now, loc.dateFormat(f)) }
    function fmtTime(f) { return loc.toString(now, loc.timeFormat(f).replace(/\s*(t+|z+|Z+)\s*$/, "")) }

    Timer { interval: 1000; repeat: true; running: true; onTriggered: page.now = new Date() }
    Component.onCompleted: { Backend.refreshLanguage(); Backend.refreshClock() }

    FText {
        text: Backend.regionalFormatName.length ? Backend.regionalFormatName : "Regional format"
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 8
    }

    SettingsCard {
        icon: "fl:calendar_ltr_20_regular"
        title: "Calendar"
        description: "Gregorian calendar"
        FluentCombo { enabled: false; minWidth: 160; model: ["Gregorian Calendar"]; currentIndex: 0 }
    }
    SettingsCard {
        icon: "fl:calendar_20_regular"
        title: "First day of week"
        description: Backend.clockAvailable ? "" : "Applied to the taskbar calendar once the Plasma shell is running"
        FluentCombo {
            minWidth: 160
            model: ["Region default (" + page.dayNames[page.loc.firstDayOfWeek % 7] + ")"].concat(page.dayNames)
            currentIndex: Backend.clockFirstDay + 1
            onActivated: (i) => Backend.setClockFirstDay(i - 1)
        }
    }
    SettingsCard {
        icon: "fl:calendar_ltr_20_regular"
        title: "Short date"
        description: page.loc.dateFormat(Locale.ShortFormat)
        FText { text: page.fmtDate(Locale.ShortFormat); color: Theme.textSecondary }
    }
    SettingsCard {
        icon: "fl:calendar_ltr_20_regular"
        title: "Long date"
        description: page.loc.dateFormat(Locale.LongFormat)
        FText { text: page.fmtDate(Locale.LongFormat); color: Theme.textSecondary }
    }
    SettingsCard {
        icon: "fl:clock_20_regular"
        title: "Short time"
        description: page.loc.timeFormat(Locale.ShortFormat)
        FText { text: page.fmtTime(Locale.ShortFormat); color: Theme.textSecondary }
    }
    SettingsCard {
        icon: "fl:clock_20_regular"
        title: "Long time"
        description: page.loc.timeFormat(Locale.LongFormat)
        FText { text: page.fmtTime(Locale.LongFormat); color: Theme.textSecondary }
    }
    SettingsCard {
        icon: "fl:clock_alarm_20_regular"
        title: "Taskbar clock format"
        description: Backend.clockAvailable ? "" : "Taskbar clock not found (Plasma shell is not running)"
        enabled: Backend.clockAvailable
        FluentCombo {
            minWidth: 160
            model: ["12-hour", "Region default", "24-hour"]
            currentIndex: Backend.clockUse24h
            onActivated: (i) => Backend.setClockUse24h(i)
        }
    }

    SectionHeader { text: "Other formats" }
    SettingsCard {
        icon: "fl:number_symbol_20_regular"
        title: "Numbers"
        FText { text: page.loc.toString(1234567.89, "f", 2); color: Theme.textSecondary }
    }
    SettingsCard {
        icon: "fl:number_symbol_20_regular"
        title: "Currency"
        FText { text: (1234.5).toLocaleCurrencyString(page.loc); color: Theme.textSecondary }
    }
    SettingsCard {
        icon: "fl:resize_20_regular"
        title: "Measurement system"
        FText {
            text: page.loc.measurementSystem === Locale.MetricSystem ? "Metric"
                  : page.loc.measurementSystem === Locale.ImperialUSSystem ? "Imperial (US)" : "Imperial (UK)"
            color: Theme.textSecondary
        }
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:local_language_20_regular"
        title: "Regional format"
        description: "Choose a different regional format"
        clickable: true
        onClicked: Router.back()
    }
}
