import QtQuick
import QtQuick.Layouts
import WinSettings
import "."

KcmListPage {
    id: page
    pageTitle: "Network & internet"
    listTitle: "Advanced"

    property string pendingSsid: ""
    property string toast: ""

    Component.onCompleted: Backend.refreshWifi()
    Timer { interval: 8000; repeat: true; running: true; onTriggered: if (!Backend.wifiBusy) Backend.refreshWifi() }

    Connections {
        target: Backend
        function onWifiResult(ok, message) { page.toast = message; toastTimer.restart() }
    }
    Timer { id: toastTimer; interval: 5000; onTriggered: page.toast = "" }

    InputDialog {
        id: pwDialog
        title: "Connect to " + page.pendingSsid
        message: "Enter the network security key"
        placeholder: "Password"
        password: true
        acceptText: "Next"
        onSubmitted: (v) => Backend.wifiConnect(page.pendingSsid, v)
    }

    function signalIcon(s) {
        return s >= 75 ? "fl:wifi_1_20_regular" : s >= 50 ? "fl:wifi_2_20_regular"
             : s >= 25 ? "fl:wifi_3_20_regular" : "fl:wifi_4_20_regular"
    }

    header: Component {
        ColumnLayout {
            spacing: 4

            // status banner (like Win11's big "Connected" header)
            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                implicitHeight: 88
                radius: Theme.radius
                color: Theme.cardBg
                border.color: Theme.cardBorder
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 16
                    Icon {
                        name: Backend.networkType === "wifi" ? "fl:wifi_1_20_regular"
                              : Backend.networkType === "ethernet" ? "fl:plug_connected_20_regular" : "fl:wifi_off_20_regular"
                        size: 40
                    }
                    ColumnLayout {
                        spacing: 2
                        FText {
                            text: Backend.networkName.length ? Backend.networkName : "Not connected"
                            font.pixelSize: Theme.fontSubtitle
                            font.weight: Font.DemiBold
                        }
                        FText {
                            text: Backend.networkType === "wifi" ? "Wi-Fi · Connected"
                                  : Backend.networkType === "ethernet" ? "Ethernet · Connected"
                                  : "You're not connected to any network"
                            font.pixelSize: Theme.fontCaption
                            color: Theme.textSecondary
                        }
                    }
                }
            }

            FText {
                visible: page.toast.length > 0
                text: page.toast
                color: Theme.accentText
                Layout.bottomMargin: 4
            }

            ExpanderCard {
                icon: "fl:wifi_1_20_regular"
                title: "Wi-Fi"
                description: Backend.wifiBusy ? "Connecting…" : (Backend.wifiEnabled ? "Show available networks" : "Off")
                expanded: Backend.wifiEnabled
                headerControls: [
                    IconButton {
                        icon: "fl:arrow_clockwise_20_regular"
                        visible: Backend.wifiEnabled
                        onClicked: Backend.rescanWifi()
                    },
                    FluentToggle {
                        checked: Backend.wifiEnabled
                        onToggled: (c) => Backend.setWifiEnabled(c)
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
            }
        }
    }
}
