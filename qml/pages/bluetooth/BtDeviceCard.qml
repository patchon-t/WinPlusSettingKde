import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."
import "BtUtil.js" as U

// One paired device as a settings row: icon, name, status, [Connect/Disconnect] and a "..." menu
SettingsCard {
    id: card
    property var device: ({})
    signal removeRequested(string mac, string name)

    icon: U.deviceIcon(device.icon)
    title: device.name
    description: U.deviceStatus(device)

    FluentButton {
        text: card.device.connected ? "Disconnect" : "Connect"
        onClicked: card.device.connected ? Backend.bluetoothDisconnect(card.device.mac)
                                         : Backend.bluetoothConnect(card.device.mac)
    }
    IconButton {
        id: more
        icon: "fl:more_horizontal_20_regular"
        onClicked: menu.open()
        BtMenu {
            id: menu
            y: more.height + 4
            x: more.width - width
            model: [{ text: card.device.connected ? "Disconnect" : "Connect", icon: "fl:link_20_regular" },
                    { text: "Remove device", icon: "fl:delete_20_regular" }]
            onChosen: (i) => {
                if (i === 0)
                    card.device.connected ? Backend.bluetoothDisconnect(card.device.mac)
                                          : Backend.bluetoothConnect(card.device.mac)
                else
                    card.removeRequested(card.device.mac, card.device.name)
            }
        }
    }
}
