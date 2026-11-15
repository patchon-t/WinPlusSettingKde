.pragma library
.import "helpers.js" as H

// Network & internet section. Owned by the Network & internet agent.
var P = "pages/network/"

var entry = H.custom("Network & internet", "fl:wifi_20_color", P + "NetworkPage.qml", [
    { icon: "fl:wifi_1_20_regular", title: "Advanced network settings", desc: "Ethernet, VPN, hotspot, IP and DNS", kcm: "kcm_networkmanagement" },
    { icon: "fl:globe_20_regular", title: "Proxy", desc: "Proxy server for network connections", kcm: "kcm_proxy" },
    { icon: "fl:shield_20_regular", title: "Firewall", desc: "Allow and block network traffic", kcm: "kcm_firewall" }
])

var settings = [
    { title: "Wi-Fi", kw: "wifi wireless network internet", icon: "fl:wifi_1_20_regular" }
]
