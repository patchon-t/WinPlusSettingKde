import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Per-connection settings shared by the Wi-Fi network page and the Ethernet page (section-local).
ColumnLayout {
    id: form
    property string connName: ""
    property bool isWifi: true
    property bool showForget: isWifi

    readonly property var c: Backend.netConn
    readonly property bool ready: c.loaded === true && c.name === connName
    readonly property bool manualIp: ready && c.v4method === "manual"
    readonly property bool manualDns: ready && (c.v4ignoreAuto || c.v6ignoreAuto)

    Layout.fillWidth: true
    spacing: 4

    function secName(k) {
        return k === "wpa-psk" ? "WPA2-Personal" : k === "sae" ? "WPA3-Personal" : k === "wpa-eap" ? "WPA2-Enterprise"
             : k === "owe" ? "Enhanced Open" : k === "" || k === "none" ? "Open" : k
    }

    Component.onCompleted: if (connName.length) Backend.loadNetConn(connName)
    onConnNameChanged: if (connName.length) Backend.loadNetConn(connName)

    Connections {
        target: Backend
        function onNetKeyRevealed(key) {
            keyDlg.key = key
            keyDlg.open()
        }
    }

    function editIp() { ipDlg.openFor() }
    function editDns() { dnsDlg.openFor() }

    NetToast {}

    // ---- connect / disconnect
    SettingsCard {
        visible: form.ready
        icon: form.isWifi ? "fl:wifi_1_20_regular" : "fl:plug_connected_20_regular"
        title: form.connName
        description: form.c.active ? "Connected" : "Not connected"
        FluentButton {
            text: form.c.active ? "Disconnect" : "Connect"
            enabled: !Backend.netBusy
            onClicked: form.c.active ? Backend.netDisconnect(form.connName) : Backend.netConnect(form.connName)
        }
    }

    SettingsCard {
        visible: form.isWifi
        icon: "fl:arrow_sync_20_regular"
        title: "Connect automatically when in range"
        enabled: form.ready
        FluentToggle {
            checked: form.ready && form.c.autoconnect
            onToggled: (v) => Backend.netSetAutoconnect(form.connName, v)
        }
    }

    SettingsCard {
        visible: form.isWifi
        icon: "fl:key_20_regular"
        title: "View Wi-Fi security key"
        description: "Show the saved password for this network"
        enabled: form.ready && form.c.keyMgmt !== "" && form.c.keyMgmt !== "none"
        FluentButton { text: "View"; onClicked: Backend.netRevealKey(form.connName) }
    }

    SettingsCard {
        visible: form.isWifi
        icon: "fl:communication_20_regular"
        title: "Random hardware addresses"
        description: "Use a different hardware address for this network"
        enabled: form.ready
        FluentCombo {
            model: ["Off", "On", "Fixed per network"]
            currentIndex: form.ready ? form.c.macMode : 0
            onActivated: (i) => Backend.netSetMacMode(form.connName, i)
        }
    }

    SettingsCard {
        icon: "fl:data_usage_20_regular"
        title: "Metered connection"
        description: "Some apps might work differently to reduce data usage when you're connected to this network"
        enabled: form.ready
        FluentToggle {
            checked: form.ready && form.c.metered === "yes"
            onToggled: (v) => Backend.netSetMetered(form.connName, v)
        }
    }

    SettingsCard {
        icon: "fl:router_20_regular"
        title: "IP assignment"
        description: !form.ready ? "" : form.manualIp ? "Manual" : "Automatic (DHCP)"
        enabled: form.ready
        FluentButton { text: "Edit"; onClicked: form.editIp() }
    }

    SettingsCard {
        icon: "fl:globe_20_regular"
        title: "DNS server assignment"
        description: !form.ready ? "" : form.manualDns ? "Manual" : "Automatic (DHCP)"
        enabled: form.ready
        FluentButton { text: "Edit"; onClicked: form.editDns() }
    }

    SectionHeader { text: "Properties"; visible: form.ready }
    NetInfoCard {
        visible: form.ready
        rows: !form.ready ? [] : (form.isWifi ? [
            { label: "SSID", value: form.c.ssid },
            { label: "Security type", value: form.secName(form.c.keyMgmt) }
        ] : []).concat([
            { label: "IPv4 address", value: form.c.ip4 },
            { label: "IPv4 default gateway", value: form.c.gw4 },
            { label: "IPv4 DNS servers", value: form.c.dns4 },
            { label: "IPv6 address", value: form.c.ip6 },
            { label: "IPv6 DNS servers", value: form.c.dns6 }
        ])
    }

    FluentButton {
        visible: form.showForget
        text: "Forget"
        Layout.topMargin: 12
        enabled: form.ready && !Backend.netBusy
        onClicked: forgetDlg.open()
    }

    // ------------------------------------------------------------ dialogs
    NetFormDialog {
        id: keyDlg
        property string key: ""
        title: "Wi-Fi security key"
        message: key.length ? "Network: " + form.connName : "Couldn't read the saved key. You may need to approve the authorization prompt."
        showAccept: key.length > 0
        acceptText: "Copy"
        onConfirmed: { Backend.copyText(key); close() }
        FText {
            visible: keyDlg.key.length > 0
            text: keyDlg.key
            Layout.fillWidth: true
            wrapMode: Text.WrapAnywhere
            font.pixelSize: Theme.fontSubtitle
        }
    }

    NetFormDialog {
        id: forgetDlg
        title: "Forget " + form.connName + "?"
        message: "Your device will no longer connect to this network automatically."
        acceptText: "Forget"
        onConfirmed: { Backend.netForget(form.connName); close(); Router.back() }
    }

    NetFormDialog {
        id: ipDlg
        title: "Edit IP settings"
        acceptText: "Save"
        function openFor() {
            modeBox.currentIndex = form.manualIp ? 1 : 0
            v4on.checked = form.c.v4method !== "disabled"
            v4ip.text = form.c.v4addr; v4mask.text = form.c.v4mask; v4gw.text = form.c.v4gw
            v6on.checked = form.c.v6method === "manual"
            v6ip.text = form.c.v6addr; v6prefix.text = form.c.v6prefix || "64"; v6gw.text = form.c.v6gw
            error = ""
            open()
        }
        onConfirmed: {
            if (modeBox.currentIndex === 0) {
                Backend.netApplyAutoIp(form.connName)
                close()
                return
            }
            const err = Backend.netValidateManualIp(v4on.checked, v4ip.text, v4mask.text, v4gw.text,
                                                    v6on.checked, v6ip.text, v6prefix.text, v6gw.text)
            if (err.length) { error = err; return }
            Backend.netApplyManualIp(form.connName, v4on.checked, v4ip.text, v4mask.text, v4gw.text,
                                     v6on.checked, v6ip.text, v6prefix.text, v6gw.text)
            close()
        }
        FluentCombo {
            id: modeBox
            model: ["Automatic (DHCP)", "Manual"]
            Layout.fillWidth: true
            onActivated: (i) => currentIndex = i
        }
        RowLayout {
            visible: modeBox.currentIndex === 1
            Layout.fillWidth: true
            FText { text: "IPv4"; font.weight: Font.DemiBold; Layout.fillWidth: true }
            FluentToggle { id: v4on; onToggled: (v) => checked = v }
        }
        NetField { id: v4ip; visible: modeBox.currentIndex === 1 && v4on.checked; label: "IP address" }
        NetField { id: v4mask; visible: modeBox.currentIndex === 1 && v4on.checked; label: "Subnet mask"; placeholder: "255.255.255.0" }
        NetField { id: v4gw; visible: modeBox.currentIndex === 1 && v4on.checked; label: "Gateway" }
        RowLayout {
            visible: modeBox.currentIndex === 1
            Layout.fillWidth: true
            FText { text: "IPv6"; font.weight: Font.DemiBold; Layout.fillWidth: true }
            FluentToggle { id: v6on; onToggled: (v) => checked = v }
        }
        NetField { id: v6ip; visible: modeBox.currentIndex === 1 && v6on.checked; label: "IP address" }
        NetField { id: v6prefix; visible: modeBox.currentIndex === 1 && v6on.checked; label: "Subnet prefix length" }
        NetField { id: v6gw; visible: modeBox.currentIndex === 1 && v6on.checked; label: "Gateway" }
    }

    NetFormDialog {
        id: dnsDlg
        title: "Edit DNS settings"
        acceptText: "Save"
        function openFor() {
            dnsMode.currentIndex = form.manualDns ? 1 : 0
            const a = form.c.v4dns || [], b = form.c.v6dns || []
            d4a.text = a.length > 0 ? a[0] : ""; d4b.text = a.length > 1 ? a[1] : ""
            d6a.text = b.length > 0 ? b[0] : ""; d6b.text = b.length > 1 ? b[1] : ""
            error = ""
            open()
        }
        onConfirmed: {
            if (dnsMode.currentIndex === 0) {
                Backend.netApplyAutoDns(form.connName)
                close()
                return
            }
            const err = Backend.netValidateDns(d4a.text, d4b.text, d6a.text, d6b.text)
            if (err.length) { error = err; return }
            Backend.netApplyManualDns(form.connName, d4a.text, d4b.text, d6a.text, d6b.text)
            close()
        }
        FluentCombo {
            id: dnsMode
            model: ["Automatic (DHCP)", "Manual"]
            Layout.fillWidth: true
            onActivated: (i) => currentIndex = i
        }
        NetField { id: d4a; visible: dnsMode.currentIndex === 1; label: "Preferred IPv4 DNS" }
        NetField { id: d4b; visible: dnsMode.currentIndex === 1; label: "Alternate IPv4 DNS" }
        NetField { id: d6a; visible: dnsMode.currentIndex === 1; label: "Preferred IPv6 DNS" }
        NetField { id: d6b; visible: dnsMode.currentIndex === 1; label: "Alternate IPv6 DNS" }
    }
}
