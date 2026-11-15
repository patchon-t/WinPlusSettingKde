import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Network & internet: status hero + one card per sub page (Win11 24H2 layout).
SettingsPage {
    id: page
    property string pageTitle: "Network & internet"
    property var items: []
    crumbs: [pageTitle]

    readonly property string base: "pages/network/"
    readonly property bool online: Backend.networkType.length > 0
    readonly property bool hasWifiDevice: {
        for (let i = 0; i < Backend.netDevices.length; ++i)
            if (Backend.netDevices[i].type === "wifi") return true
        return false
    }
    readonly property bool hasEthernet: {
        for (let i = 0; i < Backend.netDevices.length; ++i)
            if (Backend.netDevices[i].type === "ethernet") return true
        return false
    }
    readonly property var activeWifi: {
        const l = Backend.wifiNetworks
        for (let i = 0; i < l.length; ++i) if (l[i].active) return l[i]
        return null
    }

    Component.onCompleted: {
        Backend.refreshWifi()
        Backend.refreshNetDevices()
        Backend.refreshHotspot()
    }

    NetToast {}

    // ------------------------------------------------------------ status hero
    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        implicitHeight: 120
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 20
            Icon {
                name: Backend.networkType === "wifi" ? "fl:wifi_1_20_regular"
                      : Backend.networkType === "ethernet" ? "fl:plug_connected_20_regular" : "fl:wifi_off_20_regular"
                size: 56
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                FText {
                    text: page.online ? Backend.networkName : "Not connected"
                    font.pixelSize: Theme.fontSubtitle
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                FText {
                    text: !page.online ? "You're not connected to any network"
                          : Backend.networkType === "ethernet" ? "Connected, secured"
                          : (page.activeWifi && !page.activeWifi.secure ? "Connected, open" : "Connected, secured")
                    font.pixelSize: Theme.fontCaption
                    color: Theme.textSecondary
                }
            }
            FluentButton {
                text: "Properties"
                enabled: page.online
                onClicked: Router.open(page.base + (Backend.networkType === "wifi" ? "NetConnectionPage.qml" : "EthernetPage.qml"),
                                       { connName: Backend.networkName })
            }
            FluentButton {
                text: "Data usage"
                enabled: false
                opacity: 0.6
            }
        }
    }

    // ------------------------------------------------------------ cards
    SettingsCard {
        icon: "fl:wifi_1_20_regular"
        title: "Wi-Fi"
        description: Backend.wifiBusy ? "Connecting…" : "Connect, manage known networks, metered network"
        clickable: true
        enabled: page.hasWifiDevice || Backend.wifiEnabled
        onClicked: Router.open(page.base + "WifiPage.qml", {})
        FluentToggle {
            checked: Backend.wifiEnabled
            onToggled: (v) => Backend.setWifiEnabled(v)
        }
    }

    SettingsCard {
        visible: page.hasEthernet
        icon: "fl:plug_connected_20_regular"
        title: "Ethernet"
        description: "Authentication, IP and DNS settings, metered network"
        clickable: true
        onClicked: Router.open(page.base + "EthernetPage.qml", {})
    }

    SettingsCard {
        icon: "fl:lock_shield_20_regular"
        title: "VPN"
        description: "Add, connect, manage"
        clickable: true
        onClicked: Router.open(page.base + "VpnPage.qml", {})
    }

    SettingsCard {
        icon: "fl:phone_laptop_20_regular"
        title: "Mobile hotspot"
        description: "Share your internet connection over Wi-Fi"
        clickable: true
        enabled: page.hasWifiDevice
        onClicked: Router.open(page.base + "HotspotPage.qml", {})
        FluentToggle {
            checked: Backend.hotspotOn
            enabled: !Backend.netBusy
            onToggled: (v) => Backend.setHotspot(v)
        }
    }

    SettingsCard {
        icon: "fl:airplane_20_regular"
        title: "Airplane mode"
        description: "Stop all wireless communication"
        clickable: true
        onClicked: Router.open(page.base + "AirplanePage.qml", {})
        FluentToggle {
            checked: Backend.airplaneMode
            onToggled: (v) => Backend.setAirplaneMode(v)
        }
    }

    SettingsCard {
        icon: "fl:globe_20_regular"
        title: "Proxy"
        description: "Proxy server for Wi-Fi and Ethernet connections"
        clickable: true
        onClicked: Router.open(page.base + "ProxyPage.qml", {})
    }

    SettingsCard {
        icon: "fl:wifi_settings_20_regular"
        title: "Advanced network settings"
        description: "View all network adapters, network reset"
        clickable: true
        onClicked: Router.open(page.base + "AdvancedNetworkPage.qml", {})
    }
}
