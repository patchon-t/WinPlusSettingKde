import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    property string connName: ""
    crumbs: ["Network & internet", "Ethernet"]

    // the connection to edit: the one passed in, else the active one, else the first saved
    readonly property string name: {
        if (connName.length) return connName
        const l = Backend.netEthernetList
        for (let i = 0; i < l.length; ++i) if (l[i].active) return l[i].name
        return l.length ? l[0].name : ""
    }

    Component.onCompleted: { Backend.refreshNetConnections(); Backend.refreshNetDevices() }

    SettingsCard {
        icon: "fl:shield_lock_20_regular"
        title: "Authentication settings"
        description: "802.1X authentication isn't available yet"
        enabled: false
        FluentButton { text: "Edit"; enabled: false }
    }

    NetConnForm {
        visible: page.name.length > 0
        connName: page.name
        isWifi: false
    }

    FText {
        visible: page.name.length === 0
        text: "No Ethernet connection found."
        color: Theme.textSecondary
        Layout.topMargin: 8
    }
}
