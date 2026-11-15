import QtQuick
import WinSettings
import "../.."

// FluentToggle bound to a boolean KConfig key (read/written through Backend.sysCfg*).
// Use as the control of a SettingsCard / ExpanderRow.
FluentToggle {
    id: t
    property string cfgFile
    property string cfgGroup
    property string cfgKey
    property bool cfgDefault: false
    property bool inverted: false        // checked = !value
    property bool reconfigure: false     // call KWin reconfigure after writing
    signal changed(bool value)

    readonly property bool value: {
        Backend.sysCfgRev
        const raw = Backend.sysCfg(cfgFile, cfgGroup, cfgKey, cfgDefault ? "true" : "false")
        return (raw === "true" || raw === "1") !== inverted
    }
    checked: value
    onToggled: (c) => {
        Backend.sysCfgSet(cfgFile, cfgGroup, cfgKey, (c !== inverted) ? "true" : "false", "bool", reconfigure)
        changed(c)
    }
}
