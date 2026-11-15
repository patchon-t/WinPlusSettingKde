import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > Mobile devices > <device> (BT.MOB.1a)
SettingsPage {
    id: page
    property string deviceId: ""
    property string deviceName: ""
    crumbs: ["Bluetooth & devices", "Mobile devices", deviceName]

    readonly property var info: {
        for (let i = 0; i < Backend.mobileDevices.length; ++i)
            if (Backend.mobileDevices[i].id === deviceId)
                return Backend.mobileDevices[i]
        return null
    }
    readonly property bool online: info !== null && info.paired && info.reachable

    Component.onCompleted: Backend.refreshMobileDevices()

    InputDialog {
        id: shareDialog
        title: "Send a file to " + page.deviceName
        message: "Enter the path of the file or a link to send"
        placeholder: "/home/me/Pictures/photo.jpg"
        acceptText: "Send"
        onSubmitted: (v) => Backend.mobileShareFile(page.deviceId, v.trim())
    }
    BtConfirmDialog {
        id: unpairDialog
        title: "Remove this device?"
        message: "\"" + page.deviceName + "\" will be unpaired from this PC."
        acceptText: "Remove"
        onAccepted: { Backend.mobileUnpair(page.deviceId); Router.back() }
    }

    SettingsCard {
        icon: "fl:phone_20_regular"
        title: page.deviceName
        description: page.info ? (page.online ? "Paired · Connected" : page.info.paired ? "Paired · Not reachable" : "Not paired")
                               : "Not found"
    }
    SettingsCard {
        icon: "fl:phone_vibrate_20_regular"
        title: "Find my phone"
        description: "Make the device ring so you can find it"
        enabled: page.online
        FluentButton { text: "Ring"; onClicked: Backend.mobileRing(page.deviceId) }
    }
    SettingsCard {
        icon: "fl:alert_20_regular"
        title: "Send a ping"
        description: "Show a notification on the device"
        enabled: page.online
        FluentButton { text: "Ping"; onClicked: Backend.mobilePing(page.deviceId) }
    }
    SettingsCard {
        icon: "fl:send_20_regular"
        title: "Send a file"
        description: "Send a file or link to this device"
        enabled: page.online
        FluentButton { text: "Send file"; onClicked: shareDialog.open() }
    }
    SettingsCard {
        icon: "fl:link_dismiss_20_regular"
        title: "Remove device"
        description: "Unpair this device from your PC"
        enabled: page.info !== null && page.info.paired
        FluentButton { text: "Remove"; onClicked: unpairDialog.open() }
    }
}
