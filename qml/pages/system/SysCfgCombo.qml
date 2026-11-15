import QtQuick
import WinSettings
import "../.."

// FluentCombo bound to a KConfig key. `model` labels are shown, `values` are the raw
// strings stored in the file (same order).
FluentCombo {
    id: c
    property string cfgFile
    property string cfgGroup
    property string cfgKey
    property string cfgDefault: ""
    property var values: []
    property string kind: ""
    property bool reconfigure: false

    currentIndex: {
        Backend.sysCfgRev
        const raw = Backend.sysCfg(cfgFile, cfgGroup, cfgKey, cfgDefault)
        const i = values.indexOf(raw)
        return i < 0 ? values.indexOf(cfgDefault) : i
    }
    onActivated: (i) => Backend.sysCfgSet(cfgFile, cfgGroup, cfgKey, String(values[i]), kind, reconfigure)
}
