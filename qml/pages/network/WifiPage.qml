import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Network & internet", "Wi-Fi"]

    readonly property string base: "pages/network/"
    property string pendingSsid: ""

    Component.onCompleted: { Backend.refreshWifi(); Backend.refreshNetConnections() }
    Timer { interval: 8000; repeat: true; running: true; onTriggered: if (!Backend.wifiBusy) Backend.refreshWifi() }

    function signalIcon(s) {
        return s >= 75 ? "fl:wifi_1_20_regular" : s >= 50 ? "fl:wifi_2_20_regular"
             : s >= 25 ? "fl:wifi_3_20_regular" : "fl:wifi_4_20_regular"
    }
    function wifiIface() {
        for (let i = 0; i < Backend.netDevices.length; ++i)
            if (Backend.netDevices[i].type === "wifi") return Backend.netDevices[i].ifname
        return ""
    }

    InputDialog {
        id: pwDialog
        title: "Connect to " + page.pendingSsid
        message: "Enter the network security key"
        placeholder: "Password"
        password: true
        acceptText: "Next"
        onSubmitted: (v) => Backend.wifiConnect(page.pendingSsid, v)
    }

    NetFormDialog {
        id: hiddenDlg
        title: "Connect to a hidden network"
        message: "Enter the network name exactly as it is shown by your router."
        acceptText: "Connect"
        acceptEnabled: hName.text.length > 0
        onOpened: { hName.text = ""; hPwd.text = ""; error = "" }
        onConfirmed: {
            Backend.wifiConnectHidden(hName.text, hPwd.text)
            close()
        }
        NetField { id: hName; label: "Network name" }
        NetField { id: hPwd; label: "Security key (leave empty for an open network)"; password: true }
    }

    NetToast {}

    SettingsCard {
        icon: "fl:wifi_1_20_regular"
        title: "Wi-Fi"
        description: Backend.wifiBusy ? "Connecting…" : (Backend.wifiEnabled ? "Connect to available networks" : "Turn on Wi-Fi to see networks")
        FluentToggle {
            checked: Backend.wifiEnabled
            onToggled: (c) => Backend.setWifiEnabled(c)
        }
    }

    ExpanderCard {
        icon: "fl:wifi_2_20_regular"
        title: "Show available networks"
        description: Backend.wifiEnabled ? "Connect, disconnect or enter a password" : "Wi-Fi is off"
        expanded: Backend.wifiEnabled
        enabled: Backend.wifiEnabled
        headerControls: [
            IconButton {
                icon: "fl:arrow_clockwise_20_regular"
                visible: Backend.wifiEnabled
                onClicked: Backend.rescanWifi()
            }
        ]

        Repeater {
            model: Backend.wifiEnabled ? Backend.wifiNetworks : []
            delegate: Item {
                id: net
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 56

                Rectangle { width: parent.width; height: 1; color: Theme.divider }
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 1
                    color: nma.containsMouse ? Theme.subtleHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durFaster } }
                }
                MouseArea { id: nma; anchors.fill: parent; hoverEnabled: true }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 48
                    spacing: 0
                    Icon { name: page.signalIcon(net.modelData.signal); size: 20; Layout.rightMargin: 18 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        FText { text: net.modelData.ssid; Layout.fillWidth: true; elide: Text.ElideRight }
                        FText {
                            text: (net.modelData.active ? "Connected, " : "")
                                  + (net.modelData.secure ? "Secured" : "Open")
                            font.pixelSize: Theme.fontCaption
                            color: Theme.textSecondary
                        }
                    }
                    Icon { name: "fl:lock_closed_20_regular"; size: 14; visible: net.modelData.secure; Layout.rightMargin: 12 }
                    FluentButton {
                        visible: nma.containsMouse || net.modelData.active
                        text: net.modelData.active ? "Disconnect" : "Connect"
                        enabled: !Backend.wifiBusy
                        onClicked: {
                            if (net.modelData.active) {
                                Backend.wifiDisconnect()
                            } else if (net.modelData.secure && !net.modelData.known) {
                                page.pendingSsid = net.modelData.ssid
                                pwDialog.open()
                            } else {
                                Backend.wifiConnect(net.modelData.ssid, "")
                            }
                        }
                    }
                    IconButton {
                        visible: net.modelData.known && nma.containsMouse
                        icon: "fl:delete_20_regular"
                        Layout.leftMargin: 4
                        onClicked: Backend.wifiForget(net.modelData.ssid)
                    }
                }
            }
        }
        FText {
            visible: Backend.wifiEnabled && Backend.wifiNetworks.length === 0
            text: "Looking for networks…"
            color: Theme.textSecondary
            Layout.margins: 18
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: 56
            Rectangle { width: parent.width; height: 1; color: Theme.divider }
            FluentButton {
                anchors.left: parent.left
                anchors.leftMargin: 56
                anchors.verticalCenter: parent.verticalCenter
                text: "Connect to a hidden network"
                enabled: !Backend.wifiBusy
                onClicked: hiddenDlg.open()
            }
        }
    }

    SettingsCard {
        icon: "fl:settings_20_regular"
        title: "Manage known networks"
        description: "Add, remove and edit saved networks"
        clickable: true
        onClicked: Router.open(page.base + "WifiKnownPage.qml", {})
    }

    SettingsCard {
        icon: "fl:info_20_regular"
        title: "Hardware properties"
        description: "View and copy properties of your Wi-Fi adapter"
        clickable: true
        enabled: page.wifiIface().length > 0
        onClicked: Router.open(page.base + "NetDevicePage.qml", { ifname: page.wifiIface(), pageName: "Hardware properties" })
    }

    SettingsCard {
        icon: "fl:communication_20_regular"
        title: "Random hardware addresses"
        description: "Not available yet. Set it per network in Manage known networks"
        enabled: false
        FluentToggle { checked: false }
    }
}
