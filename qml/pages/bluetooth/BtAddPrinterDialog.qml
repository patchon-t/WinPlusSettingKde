import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 "Add a printer or scanner" dialog: search (lpinfo -v) -> pick -> lpadmin, or type an address
Popup {
    id: dlg
    readonly property string phase: Backend.printerAddState      // "" | adding | ok | failed | search-failed

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: 560
    padding: 0
    closePolicy: phase === "adding" ? Popup.NoAutoClose : Popup.CloseOnEscape
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

    onOpened: { addrField.text = ""; Backend.resetPrinterAddState(); Backend.searchForPrinters() }

    contentItem: ColumnLayout {
        spacing: 0

        ColumnLayout {
            Layout.margins: 24
            Layout.bottomMargin: 16
            spacing: 12

            FText {
                text: dlg.phase === "ok" ? "Printer added"
                      : dlg.phase === "adding" ? "Adding printer…"
                      : dlg.phase === "failed" ? "Something went wrong" : "Add a printer"
                font.pixelSize: Theme.fontSubtitle
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            ColumnLayout {
                visible: dlg.phase === "" || dlg.phase === "search-failed"
                Layout.fillWidth: true
                spacing: 8
                FText {
                    text: Backend.printersSearching ? "Searching for printers…"
                          : Backend.printersFound.length ? "Select a printer to add it to this PC."
                          : "No printers were found. Make sure the printer is turned on and connected."
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                BtProgressBar { Layout.fillWidth: true; running: Backend.printersSearching }
                BtInfoBar {
                    visible: dlg.phase === "search-failed"
                    severity: "warning"
                    message: Backend.printerAddMessage
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    contentHeight: list.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: FluentScrollBar {}
                    ColumnLayout {
                        id: list
                        width: flick.width
                        spacing: 2
                        Repeater {
                            model: Backend.printersFound
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
                                    Icon { name: "fl:print_20_regular"; size: 24 }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        FText { text: row.modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
                                        FText {
                                            text: row.modelData.uri
                                            font.pixelSize: Theme.fontCaption
                                            color: Theme.textSecondary
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                        }
                                    }
                                }
                                MouseArea {
                                    id: rma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: Backend.addPrinter(row.modelData.name, row.modelData.uri)
                                }
                            }
                        }
                    }
                }

                FText { text: "The printer that I want isn't listed"; font.weight: Font.DemiBold; Layout.topMargin: 8 }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    TextField {
                        id: addrField
                        Layout.fillWidth: true
                        implicitHeight: 32
                        color: Theme.text
                        placeholderText: "Printer address, for example ipp://192.168.1.20/ipp/print"
                        placeholderTextColor: Theme.textSecondary
                        font.pixelSize: Theme.fontBody
                        leftPadding: 11
                        selectByMouse: true
                        background: Rectangle {
                            radius: Theme.radius
                            color: Theme.controlBgFocus
                            border.color: Theme.controlBorder
                            clip: true
                            Rectangle {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                height: addrField.activeFocus ? 2 : 1
                                color: addrField.activeFocus ? Theme.accent : Theme.controlBorderBottom
                            }
                        }
                        onAccepted: if (text.length) Backend.addPrinter("Network printer", text.trim())
                    }
                    FluentButton {
                        text: "Add"
                        enabled: addrField.text.trim().length > 0
                        onClicked: Backend.addPrinter("Network printer", addrField.text.trim())
                    }
                }
            }

            ColumnLayout {
                visible: dlg.phase === "adding"
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 16
                BtProgressRing { size: 56; Layout.alignment: Qt.AlignHCenter; running: parent.visible }
            }

            ColumnLayout {
                visible: dlg.phase === "ok" || dlg.phase === "failed"
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 16
                spacing: 16
                Icon {
                    name: dlg.phase === "ok" ? "fl:checkmark_circle_20_regular" : "fl:warning_20_regular"
                    size: 48
                    Layout.alignment: Qt.AlignHCenter
                }
                FText {
                    text: dlg.phase === "ok" ? "Your printer is ready to use." : Backend.printerAddMessage
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
                    onClicked: { Backend.resetPrinterAddState(); Backend.searchForPrinters() }
                }
                FluentButton {
                    visible: dlg.phase === "ok"
                    text: "Done"
                    accent: true
                    Layout.fillWidth: true
                    onClicked: dlg.close()
                }
                FluentButton {
                    visible: dlg.phase !== "ok"
                    text: "Cancel"
                    enabled: dlg.phase !== "adding"
                    Layout.fillWidth: true
                    onClicked: dlg.close()
                }
            }
        }
    }
}
