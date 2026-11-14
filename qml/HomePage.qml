import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WinSettings
import "."

SettingsPage {
    id: page
    crumbs: ["Home"]
    maxContentWidth: 1200

    component StatusTile: Item {
        id: tile
        property string icon
        property string title
        property string subtitle
        signal clicked()
        implicitWidth: tr.implicitWidth + 16
        implicitHeight: tr.implicitHeight + 12
        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: tma.containsMouse ? Theme.subtleHover : "transparent"
        }
        RowLayout {
            id: tr
            anchors.centerIn: parent
            spacing: 10
            Icon { name: tile.icon; size: 20 }
            ColumnLayout {
                spacing: 0
                FText { text: tile.title; font.pixelSize: 13; font.weight: Font.DemiBold }
                FText { text: tile.subtitle; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary; visible: text.length > 0 }
            }
        }
        MouseArea { id: tma; anchors.fill: parent; hoverEnabled: true; onClicked: tile.clicked() }
    }

    // ---------------------------------------------------------- device header
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 20
        spacing: 16

        Rectangle {  // screen preview with bezel
            implicitWidth: 96
            implicitHeight: 62
            radius: 6
            color: "#1a1a1a"
            Image {
                anchors.fill: parent
                anchors.margins: 3
                source: Backend.wallpaperUrl
                sourceSize.width: 200
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                clip: true
            }
        }
        ColumnLayout {
            spacing: 1
            FText { text: Backend.hostname; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold }
            FText {
                text: Backend.deviceModel
                visible: text.length > 0
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
            }
            LinkText { text: "Rename"; onClicked: renameDialog.open() }
        }
        Item { Layout.fillWidth: true }
        StatusTile {
            icon: Backend.networkType === "wifi" ? "network-wireless" : "network-wired"
            title: Backend.networkName.length ? Backend.networkName : "Not connected"
            subtitle: Backend.networkName.length ? "Connected" : ""
            onClicked: Backend.openKcm("kcm_networkmanagement")
        }
        StatusTile {
            icon: "system-software-update|update-none"
            title: "System updates"
            subtitle: "Open Discover"
            onClicked: Backend.runCommand(["plasma-discover", "--mode", "Update"])
        }
    }

    // ---------------------------------------------------------- two columns
    GridLayout {
        Layout.fillWidth: true
        columns: page.width > 860 ? 2 : 1
        columnSpacing: 8
        rowSpacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 100
            Layout.alignment: Qt.AlignTop
            spacing: 8

            HomeCard {
                title: "Recommended settings"
                subtitle: "Recent and commonly used settings"
                HomeRow { icon: "drive-harddisk"; title: "Storage"; onClicked: Backend.runCommand(["filelight", "/"]) }
                HomeRow { icon: "preferences-desktop-theme-global|preferences-desktop-theme"; title: "Themes"; onClicked: Backend.openKcm("kcm_lookandfeel") }
                HomeRow { icon: "video-display"; title: "Display"; onClicked: Router.open("DisplayPage.qml", {}) }
            }

            HomeCard {
                title: "Personalize your device"
                GridLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    Layout.bottomMargin: 18
                    columns: 3
                    columnSpacing: 8
                    rowSpacing: 8
                    Repeater {
                        model: Backend.wallpapers.slice(0, 6)
                        delegate: Rectangle {
                            id: wp
                            required property var modelData
                            readonly property bool selected: modelData.path === Backend.wallpaper
                            Layout.fillWidth: true
                            Layout.preferredHeight: 70
                            radius: 6
                            color: "transparent"
                            border.width: selected ? 2 : (wma.containsMouse ? 1 : 0)
                            border.color: selected ? Theme.accent : Theme.strongStroke
                            Image {
                                anchors.fill: parent
                                anchors.margins: wp.selected ? 4 : 0
                                source: wp.modelData.thumb
                                sourceSize.width: 260
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                clip: true
                            }
                            MouseArea {
                                id: wma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Backend.setWallpaper(wp.modelData.path)
                            }
                        }
                    }
                }
                HomeRow {
                    icon: "preferences-desktop-color|color-management"
                    title: "Color mode"
                    clickable: false
                    FluentCombo {
                        model: ["Light", "Dark"]
                        currentIndex: Backend.dark ? 1 : 0
                        onActivated: (i) => Backend.setDark(i === 1)
                    }
                }
                HomeRow {
                    icon: "preferences-desktop-color|color-management"
                    title: "Colors"
                    subtitle: "Accent color, transparency effects"
                    onClicked: Router.open("ColorsPage.qml", {})
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 100
            Layout.alignment: Qt.AlignTop
            spacing: 8

            HomeCard {
                title: "Bluetooth devices"
                subtitle: "Manage, add, and remove devices"
                HomeRow {
                    icon: "preferences-system-bluetooth|bluetooth"
                    title: "Bluetooth"
                    subtitle: Backend.bluetoothAvailable ? "Discoverable as \"" + Backend.hostname + "\"" : "No Bluetooth adapter found"
                    clickable: false
                    FluentToggle {
                        enabled: Backend.bluetoothAvailable
                        checked: Backend.bluetoothOn
                        onToggled: (c) => Backend.setBluetooth(c)
                    }
                }
                HomeRow {
                    title: "View all devices"
                    onClicked: Backend.openKcm("kcm_bluetooth")
                    FluentButton { text: "Add device"; onClicked: Backend.runCommand(["bluedevil-wizard"]) }
                }
            }

            HomeCard {
                icon: "drive-harddisk"
                title: "Storage"
                subtitle: Backend.storageText
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    implicitHeight: 4
                    radius: 2
                    color: Theme.divider
                    Rectangle {
                        width: parent.width * Backend.storageRatio
                        height: parent.height
                        radius: 2
                        color: Backend.storageRatio > 0.9 ? "#c42b1c" : Theme.accent
                    }
                }
                FluentButton {
                    text: "See what's using space"
                    Layout.leftMargin: 18
                    Layout.topMargin: 16
                    Layout.bottomMargin: 18
                    onClicked: Backend.runCommand(["filelight", "/"])
                }
            }

            HomeCard {
                icon: "start-here-kde|distributor-logo|kde"
                title: Backend.osName
                subtitle: (Backend.plasmaVersion.length ? "KDE Plasma " + Backend.plasmaVersion + "  ·  " : "")
                          + "Kernel " + Backend.kernel
                FluentButton {
                    text: "About this PC"
                    Layout.leftMargin: 18
                    Layout.bottomMargin: 18
                    onClicked: Backend.openKcm("kcm_about-distro")
                }
            }
        }
    }

    // ---------------------------------------------------------- rename dialog
    Popup {
        id: renameDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 420
        padding: 0
        onOpened: { nameField.text = Backend.hostname; nameField.selectAll(); nameField.forceActiveFocus() }
        Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.3) }
        background: FlyoutBackground {}

        contentItem: ColumnLayout {
            spacing: 0
            ColumnLayout {
                Layout.margins: 24
                spacing: 12
                FText { text: "Rename your PC"; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold }
                FText {
                    text: "Letters, numbers and hyphens only. You'll be asked for your password."
                    font.pixelSize: Theme.fontCaption
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    implicitHeight: 32
                    color: Theme.text
                    font.pixelSize: Theme.fontBody
                    leftPadding: 11
                    validator: RegularExpressionValidator { regularExpression: /[A-Za-z0-9][A-Za-z0-9-]{0,62}/ }
                    background: Rectangle {
                        radius: Theme.radius
                        color: Theme.controlBgFocus
                        border.color: Theme.controlBorder
                        Rectangle {
                            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                            height: nameField.activeFocus ? 2 : 1
                            color: nameField.activeFocus ? Theme.accent : Theme.controlBorderBottom
                        }
                    }
                    onAccepted: okBtn.clicked()
                }
            }
            Rectangle {  // dialog footer
                Layout.fillWidth: true
                implicitHeight: 80
                color: Theme.dark ? "#202020" : "#f3f3f3"
                radius: Theme.radiusLarge
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 8
                    FluentButton {
                        id: okBtn
                        text: "Rename"
                        accent: true
                        Layout.fillWidth: true
                        enabled: nameField.acceptableInput
                        onClicked: { Backend.renameHost(nameField.text); renameDialog.close() }
                    }
                    FluentButton { text: "Cancel"; Layout.fillWidth: true; onClicked: renameDialog.close() }
                }
            }
        }
    }
}
