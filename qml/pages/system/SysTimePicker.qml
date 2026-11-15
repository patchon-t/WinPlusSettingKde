import QtQuick
import QtQuick.Layouts
import "../.."

// Hour : minute pair of combos for a "HH:MM:SS" string value.
RowLayout {
    id: tp
    property string value: "00:00:00"
    signal edited(string value)
    spacing: 8

    readonly property int hour: parseInt(value.split(":")[0]) || 0
    readonly property int minute: parseInt(value.split(":")[1]) || 0
    readonly property var hours: Array.from({ length: 24 }, (_, i) => (i < 10 ? "0" : "") + i)
    readonly property var minutes: Array.from({ length: 60 }, (_, i) => (i < 10 ? "0" : "") + i)

    function pad(n) { return (n < 10 ? "0" : "") + n }

    FluentCombo {
        minWidth: 72
        model: tp.hours
        currentIndex: tp.hour
        onActivated: (i) => tp.edited(tp.pad(i) + ":" + tp.pad(tp.minute) + ":00")
    }
    FText { text: ":" }
    FluentCombo {
        minWidth: 72
        model: tp.minutes
        currentIndex: tp.minute
        onActivated: (i) => tp.edited(tp.pad(tp.hour) + ":" + tp.pad(i) + ":00")
    }
}
