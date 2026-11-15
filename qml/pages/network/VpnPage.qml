import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Network & internet", "VPN"]

    property string removeName: ""

    Component.onCompleted: Backend.refreshNetConnections()

    NetToast {}

    SettingsCard {
        icon: "fl:lock_shield_20_regular"
        title: "VPN connections"
        description: "Add a VPN from an OpenVPN (.ovpn) or WireGuard (.conf) file"
        FluentButton { text: "Add VPN"; onClicked: addDlg.open() }
    }

    Repeater {
        model: Backend.netVpnList
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:lock_shield_20_regular"
            title: modelData.name
            description: modelData.active ? "Connected" : (modelData.type === "wireguard" ? "WireGuard" : "VPN")
            FluentButton {
                text: modelData.active ? "Disconnect" : "Connect"
                enabled: !Backend.netBusy
                accent: !modelData.active
                onClicked: modelData.active ? Backend.vpnDisconnect(modelData.name) : Backend.vpnConnect(modelData.name)
            }
            IconButton {
                icon: "fl:delete_20_regular"
                onClicked: { page.removeName = modelData.name; removeDlg.open() }
            }
        }
    }

    FText {
        visible: Backend.netVpnList.length === 0
        text: "No VPN connections yet."
        color: Theme.textSecondary
        Layout.topMargin: 8
    }

    NetFormDialog {
        id: addDlg
        title: "Add a VPN connection"
        message: "Choose a configuration file from your VPN provider. OpenVPN needs the NetworkManager OpenVPN plugin."
        acceptText: "Add"
        acceptEnabled: vpnPath.text.length > 0
        onOpened: { vpnPath.text = ""; error = "" }
        onConfirmed: {
            const err = Backend.netValidateVpnFile(vpnPath.text)
            if (err.length) { error = err; return }
            Backend.vpnImport(vpnPath.text)
            close()
        }
        NetField { id: vpnPath; label: "Configuration file path"; placeholder: "/home/you/Downloads/work.ovpn" }
    }

    NetFormDialog {
        id: removeDlg
        title: "Remove " + page.removeName + "?"
        message: "This deletes the saved VPN connection."
        acceptText: "Remove"
        onConfirmed: { Backend.vpnRemove(page.removeName); close() }
    }
}
