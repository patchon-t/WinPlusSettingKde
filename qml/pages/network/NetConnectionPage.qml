import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Properties of one saved Wi-Fi network.
SettingsPage {
    id: page
    property string connName: ""
    crumbs: ["Wi-Fi", "Manage known networks", connName.length ? connName : "Network"]

    property alias connForm: form

    NetConnForm {
        id: form
        connName: page.connName
        isWifi: true
    }
}
