pragma Singleton
import QtQuick
import WinSettings

// Page navigation bus. Main.qml owns the StackView and listens to these.
QtObject {
    // "nav" | "push" | "pop": set by Main.qml before each StackView op, read by
    // SettingsPage to play the matching Win11 entrance (content only, header stays put)
    property string motion: "nav"
    signal open(string page, var props)   // push a sub page
    signal back()                         // pop one level
    signal openNav(int index)             // switch top-level nav item

    // entry = { page | kcm | cmd } from Data.js
    function activate(entry) {
        if (!entry)
            return
        if (entry.page)
            open(entry.page, entry.props || {})
        else if (entry.kcm)
            Backend.openKcm(entry.kcm)
        else if (entry.cmd)
            Backend.runCommand(entry.cmd)
    }
}
