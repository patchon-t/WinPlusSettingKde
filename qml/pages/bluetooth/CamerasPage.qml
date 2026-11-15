import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > Cameras (BT.CAM.1)
SettingsPage {
    id: page
    crumbs: ["Bluetooth & devices", "Cameras"]

    Component.onCompleted: Backend.refreshCameras()
    Timer { interval: 5000; repeat: true; running: true; onTriggered: Backend.refreshCameras() }

    SectionHeader { text: "Connected cameras"; Layout.topMargin: 0 }
    Repeater {
        model: Backend.cameras
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:camera_20_regular"
            title: modelData.name
            description: modelData.device
            clickable: true
            onClicked: Router.open("pages/bluetooth/CameraPage.qml", { cameraName: modelData.name, cameraDevice: modelData.device })
        }
    }
    SettingsCard {
        visible: Backend.cameras.length === 0
        icon: "fl:camera_off_20_regular"
        title: "No cameras found"
        description: "Connect a webcam and it will show up here."
    }
}
