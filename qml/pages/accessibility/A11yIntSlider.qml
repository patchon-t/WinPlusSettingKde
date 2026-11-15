import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Slider + value label bound to an Int key of kaccessrc (committed on release).
RowLayout {
    id: r
    property string group
    property string key
    property int fallback: 0
    property int from: 0
    property int to: 100
    property int stepSize: 1
    property string suffix: ""
    readonly property int stored: {
        Backend.a11yCfgRev
        const v = parseInt(Backend.a11yCfg("kaccessrc", group, key, String(fallback)))
        return isNaN(v) ? fallback : v
    }
    property int pending: stored
    onStoredChanged: pending = stored
    spacing: 12

    FluentSlider {
        from: r.from; to: r.to; stepSize: r.stepSize
        value: r.pending
        onMoved: r.pending = Math.round(value)
        onPressedChanged: if (!pressed) Backend.a11yKaccessSet(r.group, r.key, String(r.pending), "int")
    }
    FText {
        text: r.pending + r.suffix
        Layout.preferredWidth: 60
        horizontalAlignment: Text.AlignRight
    }
}
