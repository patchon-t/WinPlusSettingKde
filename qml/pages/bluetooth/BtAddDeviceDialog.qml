import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WinSettings
import "../.."
import "BtUtil.js" as U

// Win11 "Add a device" dialog: scan -> pick -> pair / trust / connect (all async in Backend)
Popup {
    id: dlg
    readonly property string phase: Backend.bluetoothPairState      // "" | pairing | connecting | done | failed
    property string target: ""                                      // mac being paired

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: 560
    padding: 0
    closePolicy: phase === "pairing" || phase === "connecting" ? Popup.NoAutoClose
                                                               : Popup.CloseOnEscape
    Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.3) }
    background: FlyoutBackground {}
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durFast
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decelerate }
        NumberAnimation { property: "scale"; from: 1.05; to: 1; duration: Theme.durNormal
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decelerate }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFaster }
        NumberAnimation { property: "scale"; from: 1; to: 1.05; duration: Theme.durFast
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.accelerate }
    }

    onOpened: { Backend.resetBluetoothPairState(); Backend.startBluetoothScan() }
    onClosed: { Backend.stopBluetoothScan(); Backend.resetBluetoothPairState(); Backend.refreshBluetoothDevices() }

    contentItem: ColumnLayout {
        spacing: 0

        ColumnLayout {
            Layout.margins: 24
            Layout.bottomMargin: 16
            spacing: 12

            FText {
                text: dlg.phase === "done" ? "Your device is ready to go!"
                      : dlg.phase === "failed" ? "Something went wrong"
                      : dlg.phase === "pairing" || dlg.phase === "connecting" ? "Connecting to " + Backend.bluetoothPairName
                      : "Add a device"
                font.pixelSize: Theme.fontSubtitle
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // ---------------------------------------------------- discovery
            ColumnLayout {
                visible: dlg.phase === ""
                Layout.fillWidth: true
                spacing: 8

                FText {
                    text: !Backend.bluetoothAvailable ? "No Bluetooth adapter was found."
                          : !Backend.bluetoothOn ? "Turn on Bluetooth to find devices."
                          : "Make sure your device is turned on and discoverable. Select a device below to connect."
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                BtProgressBar {
                    Layout.fillWidth: true
                    running: Backend.bluetoothScanning
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.preferredHeight: 280
                    contentHeight: found.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: FluentScrollBar {}

                    ColumnLayout {
                        id: found
                        width: flick.width
                        spacing: 2
                        Repeater {
                            model: Backend.bluetoothFound
                            delegate: Rectangle {
                                id: row
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 56
                                radius: Theme.radius
                                color: rma.pressed ? Theme.subtlePressed : rma.containsMouse ? Theme.subtleHover : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.durFaster } }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 16
                                    Icon { name: U.deviceIcon(row.modelData.icon); size: 24 }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        FText { text: row.modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
                                        FText {
                                            text: row.modelData.mac
                                            font.pixelSize: Theme.fontCaption
                                            color: Theme.textSecondary
                                        }
                                    }
                                }
                                MouseArea {
                                    id: rma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        dlg.target = row.modelData.mac
                                        Backend.pairBluetoothDevice(row.modelData.mac, row.modelData.name)
                                    }
                                }
                            }
                        }
                        FText {
                            visible: Backend.bluetoothFound.length === 0
                            text: Backend.bluetoothScanning ? "Searching for devices…"
                                  : Backend.bluetoothOn ? "No devices found." : ""
                            color: Theme.textSecondary
                            Layout.topMargin: 24
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            // ---------------------------------------------------- pairing / connecting
            ColumnLayout {
                visible: dlg.phase === "pairing" || dlg.phase === "connecting"
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 16
                spacing: 16
                BtProgressRing { size: 56; Layout.alignment: Qt.AlignHCenter; running: parent.visible }
                FText {
                    text: dlg.phase === "pairing" ? "Pairing… If a code or prompt appears on either device, confirm it."
                                                  : "Almost done…"
                    color: Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // ---------------------------------------------------- done / failed
            ColumnLayout {
                visible: dlg.phase === "done" || dlg.phase === "failed"
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 16
                spacing: 16
                Icon {
                    name: dlg.phase === "done" ? "fl:checkmark_circle_20_regular" : "fl:warning_20_regular"
                    size: 48
                    Layout.alignment: Qt.AlignHCenter
                }
                FText {
                    text: Backend.bluetoothPairMessage
                    color: Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 80
            color: Theme.dark ? "#202020" : "#f3f3f3"
            radius: Theme.radiusLarge
            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 8
                FluentButton {
                    visible: dlg.phase === "failed"
                    text: "Try again"
                    accent: true
                    Layout.fillWidth: true
                    onClicked: { Backend.resetBluetoothPairState(); Backend.startBluetoothScan() }
                }
                FluentButton {
                    visible: dlg.phase === "done"
                    text: "Done"
                    accent: true
                    Layout.fillWidth: true
                    onClicked: dlg.close()
                }
                FluentButton {
                    visible: dlg.phase !== "done"
                    text: dlg.phase === "failed" ? "Close" : "Cancel"
                    Layout.fillWidth: true
                    onClicked: {
                        if (dlg.phase === "pairing" || dlg.phase === "connecting")
                            Backend.cancelBluetoothPairing(dlg.target)
                        dlg.close()
                    }
                }
            }
        }
    }
}
