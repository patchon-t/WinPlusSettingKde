import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Network & internet", "Advanced network settings"]

    readonly property string base: "pages/network/"

    Component.onCompleted: Backend.refreshNetDevices()

    function stateText(d) {
        return d.state === "connected" ? "Connected" + (d.connection.length ? " to " + d.connection : "")
             : d.state === "unavailable" ? "Unavailable" : d.state === "unmanaged" ? "Not managed" : "Not connected"
    }

    NetToast {}

    ExpanderCard {
        icon: "fl:plug_connected_20_regular"
        title: "Network adapters"
        description: Backend.netDevices.length + (Backend.netDevices.length === 1 ? " adapter" : " adapters")
        expanded: true

        Repeater {
            model: Backend.netDevices
            delegate: ExpanderRow {
                required property var modelData
                title: modelData.ifname + " · " + (modelData.type === "wifi" ? "Wi-Fi" : modelData.type === "ethernet" ? "Ethernet" : modelData.type)
                description: page.stateText(modelData)
                IconButton {
                    icon: "fl:info_20_regular"
                    onClicked: Router.open(page.base + "NetDevicePage.qml", { ifname: modelData.ifname,
                                                                           pageName: modelData.ifname })
                }
                FluentButton {
                    text: modelData.state === "connected" ? "Disable" : "Enable"
                    enabled: modelData.state !== "unavailable" && modelData.state !== "unmanaged" && !Backend.netBusy
                    onClicked: Backend.netSetDeviceEnabled(modelData.ifname, modelData.state !== "connected")
                }
            }
        }
        ExpanderRow {
            visible: Backend.netDevices.length === 0
            title: "No network adapters found"
            description: "NetworkManager may not be running"
        }
    }

    SettingsCard {
        icon: "fl:share_20_regular"
        title: "Advanced sharing settings"
        description: "Not available yet"
        enabled: false
    }

    SettingsCard {
        icon: "fl:data_usage_20_regular"
        title: "Data usage"
        description: "Not available yet"
        enabled: false
    }

    SettingsCard {
        icon: "fl:info_20_regular"
        title: "Hardware and connection properties"
        description: "View the properties of your network adapters and connections"
        clickable: true
        onClicked: Router.open(page.base + "NetDevicePage.qml", { ifname: "" })
    }

    SettingsCard {
        icon: "fl:arrow_reset_20_regular"
        title: "Network reset"
        description: "Reset all network adapters to their original settings"
        clickable: true
        onClicked: Router.open(page.base + "NetworkResetPage.qml", {})
    }

    SectionHeader { text: "More settings" }
    SettingsCard {
        icon: "fl:shield_20_regular"
        title: "Windows Firewall"
        description: "Allow or block network traffic"
        clickable: true
        onClicked: Router.open("pages/privacy/FirewallPage.qml", {})
    }
}
