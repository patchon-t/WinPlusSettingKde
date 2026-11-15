import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Properties of one saved Wi-Fi network.
SettingsPage {
    id: page
    property string connName: ""
    crumbs: ["Network & internet", "Wi-Fi", "Manage known networks", connName.length ? connName : "Network"]

    NetConnForm {
        connName: page.connName
        isWifi: true
    }
}
