import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Storage", "Disks & volumes"]

    Component.onCompleted: Backend.sysRefreshDisks()

    FText {
        visible: Backend.sysDisks.length === 0
        text: "No disks found"
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
    }

    Repeater {
        model: Backend.sysDisks
        delegate: ExpanderCard {
            id: dk
            required property var modelData
            icon: modelData.removable ? "fl:usb_stick_20_regular" : "fl:hard_drive_20_regular"
            title: modelData.model.length ? modelData.model : "/dev/" + modelData.name
            description: "/dev/" + modelData.name + "  ·  " + modelData.size
            expanded: true
            Repeater {
                model: dk.modelData.volumes
                delegate: ExpanderRow {
                    required property var modelData
                    required property int index
                    divider: index > 0
                    title: modelData.name + (modelData.fstype.length ? "  (" + modelData.fstype + ")" : "")
                    description: (modelData.mount.length ? modelData.mount : "Not mounted") + "  ·  " + modelData.size
                                 + (modelData.used.length ? "  ·  " + modelData.used + " used" : "")
                    Rectangle {
                        visible: modelData.mount.length > 0
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Theme.sliderTrack
                        Rectangle {
                            width: parent.width * modelData.fraction
                            height: parent.height
                            radius: 3
                            color: Theme.accent
                        }
                    }
                }
            }
        }
    }
}
