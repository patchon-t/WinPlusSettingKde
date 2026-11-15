import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > Printers & scanners > <printer> > Print queue (BT.PRN.3a)
SettingsPage {
    id: page
    property string printerName: ""
    crumbs: ["Bluetooth & devices", "Printers & scanners", printerName, "Print queue"]

    Component.onCompleted: Backend.refreshPrintJobs(printerName)
    Timer { interval: 3000; repeat: true; running: true; onTriggered: Backend.refreshPrintJobs(page.printerName) }

    SettingsCard {
        icon: "fl:document_20_regular"
        title: "Documents waiting to print"
        description: Backend.printJobs.length === 0 ? "The queue is empty"
                     : Backend.printJobs.length + (Backend.printJobs.length === 1 ? " document" : " documents")
        FluentButton {
            text: "Cancel all documents"
            enabled: Backend.printJobs.length > 0
            onClicked: Backend.cancelAllPrintJobs(page.printerName)
        }
    }

    Repeater {
        model: Backend.printJobs
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:document_20_regular"
            title: modelData.id
            description: modelData.user + " · " + Math.max(1, Math.round(modelData.size / 1024)) + " KB · " + modelData.when
            IconButton {
                icon: "fl:dismiss_20_regular"
                onClicked: Backend.cancelPrintJob(page.printerName, modelData.id)
            }
        }
    }
}
