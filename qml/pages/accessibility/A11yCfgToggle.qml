import QtQuick
import WinSettings
import "../.."

// Toggle bound to a Bool key of any KConfig file via the Accessibility mixin.
// kaccess: true -> write kaccessrc and re-run `kaccess` so it reloads.
FluentToggle {
    id: t
    property string file: "kaccessrc"
    property string group
    property string key
    property bool fallback: false
    property bool kaccess: file === "kaccessrc"
    property bool invert: false
    property string effect: ""   // set: write [Effect-<effect>] and reconfigureEffect
    readonly property bool stored: {
        Backend.a11yCfgRev
        const v = Backend.a11yCfg(file, group, key, fallback ? "true" : "false") === "true"
        return invert ? !v : v
    }
    checked: stored
    onToggled: (c) => {
        const v = (invert ? !c : c) ? "true" : "false"
        if (effect.length)
            Backend.a11yEffectCfgSet(effect, key, v, "bool")
        else if (kaccess)
            Backend.a11yKaccessSet(group, key, v, "bool")
        else
            Backend.a11yCfgSet(file, group, key, v, "bool")
    }
}
