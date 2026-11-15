import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."
import "BtUtil.js" as U

// Win11 24H2 device tile (top of Bluetooth & devices): icon, "...", name, status
Rectangle {
    id: tile
    property var device: ({})
    signal removeRequested(string mac, string name)

    implicitWidth: 172
    implicitHeight: 120
    radius: Theme.radius
    color: ma.pressed ? Theme.cardBgPressed : ma.containsMouse ? Theme.cardBgHover : Theme.cardBg
    Behavior on color { ColorAnimation { duration: Theme.durFaster } }
    border.color: Theme.cardBorder

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: tile.device.connected ? Backend.bluetoothDisconnect(tile.device.mac)
                                         : Backend.bluetoothConnect(tile.device.mac)
    }

    Icon {
        x: 16
        y: 16
        name: U.deviceIcon(tile.device.icon)
        size: 32
    }
    IconButton {
        id: more
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        icon: "fl:more_horizontal_20_regular"
        onClicked: menu.open()
        BtMenu {
            id: menu
            y: more.height + 4
            x: more.width - width
            model: [{ text: tile.device.connected ? "Disconnect" : "Connect", icon: "fl:link_20_regular" },
                    { text: "Remove device", icon: "fl:delete_20_regular" }]
            onChosen: (i) => {
                if (i === 0)
                    tile.device.connected ? Backend.bluetoothDisconnect(tile.device.mac)
                                          : Backend.bluetoothConnect(tile.device.mac)
                else
                    tile.removeRequested(tile.device.mac, tile.device.name)
            }
        }
    }
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        anchors.bottomMargin: 14
        spacing: 1
        FText { text: tile.device.name; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
        FText {
            text: U.deviceStatus(tile.device, true)
            font.pixelSize: Theme.fontCaption
            color: Theme.textSecondary
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
}
