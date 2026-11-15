import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Bluetooth & devices > Cameras > <camera> (BT.CAM.2: image controls not verified yet)
SettingsPage {
    id: page
    property string cameraName: ""
    property string cameraDevice: ""
    crumbs: ["Bluetooth & devices", "Cameras", cameraName]

    SettingsCard {
        icon: "fl:camera_20_regular"
        title: page.cameraName
        description: page.cameraDevice
    }

    SectionHeader { text: "Default image settings" }
    SettingsCard {
        enabled: false
        icon: "fl:video_20_regular"
        title: "Brightness"
        description: "Not available yet"
        FluentSlider { from: 0; to: 100; value: 50 }
    }
    SettingsCard {
        enabled: false
        icon: "fl:video_20_regular"
        title: "Contrast"
        description: "Not available yet"
        FluentSlider { from: 0; to: 100; value: 50 }
    }
}
