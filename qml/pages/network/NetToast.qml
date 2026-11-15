import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Result line for the last network action (section-local). Put at the top of a page.
FText {
    id: t
    property bool ok: true
    visible: text.length > 0
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Layout.bottomMargin: 4
    color: ok ? Theme.accentText : (Theme.dark ? "#ff99a4" : "#c42b1c")

    Connections {
        target: Backend
        function onNetResult(good, message) { t.ok = good; t.text = message; hide.restart() }
        function onWifiResult(good, message) { t.ok = good; t.text = message; hide.restart() }
    }
    Timer { id: hide; interval: 6000; onTriggered: t.text = "" }
}
