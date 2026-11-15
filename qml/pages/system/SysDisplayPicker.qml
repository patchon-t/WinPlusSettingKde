import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// "Select a display" combo (hidden when there is a single display).
// `current` is the chosen output (or null).
SettingsCard {
    id: pk
    property int sel: 0
    readonly property var outs: Backend.outputs
    readonly property var current: outs.length ? outs[Math.min(sel, outs.length - 1)] : null
    icon: "fl:desktop_20_regular"
    title: "Select a display"
    description: outs.length ? "" : "No displays found. Is kscreen-doctor installed?"
    visible: outs.length !== 1
    FluentCombo {
        minWidth: 220
        enabled: pk.outs.length > 0
        model: pk.outs.map(o => o.title + " (" + o.name + ")")
        currentIndex: Math.min(pk.sel, Math.max(0, pk.outs.length - 1))
        onActivated: (i) => pk.sel = i
    }
}
