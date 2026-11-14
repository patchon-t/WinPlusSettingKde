pragma Singleton
import QtQuick
import WinSettings

// Page navigation bus. Main.qml owns the StackView and listens to these.
QtObject {
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
