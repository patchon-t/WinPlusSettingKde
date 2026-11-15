import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > Printers & scanners (BT.PRN.1, BT.PRN.4)
SettingsPage {
    id: page
    crumbs: ["Bluetooth & devices", "Printers & scanners"]

    Component.onCompleted: Backend.refreshPrinters()
    Timer { interval: 6000; repeat: true; running: true; onTriggered: Backend.refreshPrinters() }

    BtAddPrinterDialog { id: addDialog }

    SectionHeader { text: "Printers"; Layout.topMargin: 0 }
    SettingsCard {
        icon: "fl:print_add_20_regular"
        title: "Add device"
        description: "Search for a printer on your network or connected by USB"
        FluentButton { text: "Add device"; accent: true; onClicked: addDialog.open() }
    }

    Repeater {
        model: Backend.printers
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:print_20_regular"
            title: modelData.name
            description: modelData.state + (modelData.isDefault ? " · Default" : "")
            clickable: true
            onClicked: Router.open("pages/bluetooth/PrinterPage.qml", { printerName: modelData.name })
        }
    }

    SettingsCard {
        visible: Backend.printers.length === 0
        icon: "fl:print_20_regular"
        title: "No printers added"
        description: Backend.printersLoaded ? "Select Add device to set up a printer." : "Looking for printers…"
    }

    SectionHeader { text: "Scanners" }
    SettingsCard {
        enabled: false
        icon: "fl:scan_20_regular"
        title: "Scanners"
        description: "Not available yet"
    }
}
