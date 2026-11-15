.pragma library
.import "helpers.js" as H

// Network & internet section. Owned by the Network & internet agent.
var P = "pages/network/"

// Pages below the top page (the top page draws its own cards; these arrays feed search and the smoke test).
var wifiItems = [
    { icon: "fl:wifi_1_20_regular", title: "Manage known networks", page: P + "WifiKnownPage.qml",
      items: [
        { icon: "fl:wifi_1_20_regular", title: "Network properties", page: P + "NetConnectionPage.qml",
          props: { connName: "Sample network" } }
      ] },
    { icon: "fl:info_20_regular", title: "Wi-Fi hardware properties", page: P + "NetDevicePage.qml",
      props: { ifname: "", pageName: "Hardware properties", trail: ["Network & internet", "Wi-Fi"] } }
]

var advancedItems = [
    { icon: "fl:info_20_regular", title: "Hardware and connection properties", page: P + "NetDevicePage.qml", props: { ifname: "" } },
    { icon: "fl:arrow_reset_20_regular", title: "Network reset", page: P + "NetworkResetPage.qml" }
]

var entry = H.custom("Network & internet", "fl:wifi_20_color", P + "NetworkPage.qml", [
    { icon: "fl:wifi_1_20_regular", title: "Wi-Fi", page: P + "WifiPage.qml", items: wifiItems },
    { icon: "fl:plug_connected_20_regular", title: "Ethernet", page: P + "EthernetPage.qml" },
    { icon: "fl:lock_shield_20_regular", title: "VPN", page: P + "VpnPage.qml" },
    { icon: "fl:phone_laptop_20_regular", title: "Mobile hotspot", page: P + "HotspotPage.qml" },
    { icon: "fl:airplane_20_regular", title: "Airplane mode", page: P + "AirplanePage.qml" },
    { icon: "fl:globe_20_regular", title: "Proxy", page: P + "ProxyPage.qml" },
    { icon: "fl:wifi_settings_20_regular", title: "Advanced network settings", page: P + "AdvancedNetworkPage.qml",
      items: advancedItems }
])

var settings = [
    { title: "Wi-Fi", kw: "wifi wireless network internet wlan", icon: "fl:wifi_1_20_regular", page: P + "WifiPage.qml" },
    { title: "Show available networks", kw: "wifi connect network password hidden ssid", icon: "fl:wifi_2_20_regular", page: P + "WifiPage.qml" },
    { title: "Manage known networks", kw: "wifi saved forget remove network profile", icon: "fl:wifi_1_20_regular", page: P + "WifiKnownPage.qml" },
    { title: "Wi-Fi hardware properties", kw: "adapter driver mac address band channel ssid", icon: "fl:info_20_regular",
      page: P + "NetDevicePage.qml", props: { ifname: "", pageName: "Hardware properties", trail: ["Network & internet", "Wi-Fi"] } },
    { title: "Random hardware addresses", kw: "mac address random privacy wifi", icon: "fl:communication_20_regular", page: P + "WifiKnownPage.qml" },
    { title: "Metered connection", kw: "metered data usage limit connection", icon: "fl:data_usage_20_regular", page: P + "WifiKnownPage.qml" },
    { title: "IP assignment", kw: "ip address dhcp static manual gateway subnet", icon: "fl:router_20_regular", page: P + "WifiKnownPage.qml" },
    { title: "DNS server assignment", kw: "dns server nameserver", icon: "fl:globe_20_regular", page: P + "WifiKnownPage.qml" },
    { title: "Ethernet", kw: "ethernet wired lan cable network", icon: "fl:plug_connected_20_regular", page: P + "EthernetPage.qml" },
    { title: "VPN", kw: "vpn openvpn wireguard tunnel add connection", icon: "fl:lock_shield_20_regular", page: P + "VpnPage.qml" },
    { title: "Mobile hotspot", kw: "hotspot tethering share internet wifi access point", icon: "fl:phone_laptop_20_regular", page: P + "HotspotPage.qml" },
    { title: "Airplane mode", kw: "airplane flight mode wireless bluetooth radio", icon: "fl:airplane_20_regular", page: P + "AirplanePage.qml" },
    { title: "Proxy", kw: "proxy server pac script wpad automatic manual exceptions", icon: "fl:globe_20_regular", page: P + "ProxyPage.qml" },
    { title: "Advanced network settings", kw: "network adapters enable disable properties", icon: "fl:wifi_settings_20_regular", page: P + "AdvancedNetworkPage.qml" },
    { title: "Network adapters", kw: "adapter ethernet wifi disable enable interface", icon: "fl:plug_connected_20_regular", page: P + "AdvancedNetworkPage.qml" },
    { title: "Network reset", kw: "reset network restart networking", icon: "fl:arrow_reset_20_regular", page: P + "NetworkResetPage.qml" }
]
