import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > Printers & scanners > <printer> (BT.PRN.3*)
SettingsPage {
    id: page
    property string printerName: ""
    crumbs: ["Bluetooth & devices", "Printers & scanners", printerName]

    readonly property var info: {
        for (let i = 0; i < Backend.printers.length; ++i)
            if (Backend.printers[i].name === printerName)
                return Backend.printers[i]
        return null
    }

    Component.onCompleted: Backend.refreshPrinters()

    BtConfirmDialog {
        id: removeDialog
        title: "Remove this printer?"
        message: "\"" + page.printerName + "\" will be removed from this PC."
        acceptText: "Remove"
        onAccepted: { Backend.removePrinter(page.printerName); Router.back() }
    }

    SettingsCard {
        icon: "fl:print_20_regular"
        title: page.printerName
        description: page.info ? page.info.state + (page.info.isDefault ? " · Default" : "") : "Not found"
    }

    SettingsCard {
        icon: "fl:checkmark_circle_20_regular"
        title: "Set as default"
        description: page.info && page.info.isDefault ? "This is your default printer" : "Use this printer first when you print"
        enabled: page.info !== null && !page.info.isDefault
        FluentButton { text: "Set as default"; onClicked: Backend.setDefaultPrinter(page.printerName) }
    }
    SettingsCard {
        icon: "fl:document_20_regular"
        title: "Open print queue"
        description: "See what's printing and what's waiting"
        enabled: page.info !== null
        clickable: true
        onClicked: Router.open("pages/bluetooth/PrintQueuePage.qml", { printerName: page.printerName })
    }
    SettingsCard {
        icon: "fl:print_20_regular"
        title: "Print a test page"
        description: "Check that this printer is working"
        enabled: page.info !== null
        FluentButton { text: "Print test page"; onClicked: Backend.printTestPage(page.printerName) }
    }
    SettingsCard {
        icon: "fl:info_20_regular"
        title: "Printer properties"
        description: "Printing preferences and hardware properties open in the KDE printer window"
        enabled: page.info !== null
        FluentButton { text: "Open"; onClicked: Backend.openPrinterProperties(page.printerName) }
    }
    SettingsCard {
        icon: "fl:delete_20_regular"
        title: "Remove"
        description: "Remove this printer from your PC"
        enabled: page.info !== null
        FluentButton { text: "Remove"; onClicked: removeDialog.open() }
    }
}
