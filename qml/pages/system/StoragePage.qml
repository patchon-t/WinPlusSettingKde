import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Storage"]

    Component.onCompleted: { Backend.sysCfgReload(); Backend.sysRefreshStorage() }

    // ---------------------------------------------------------- local disk
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: diskCol.implicitHeight + 32
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        ColumnLayout {
            id: diskCol
            anchors.fill: parent
            anchors.margins: 16
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Icon { name: "fl:hard_drive_20_regular"; size: 32 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText { text: "Local disk (/)"; font.weight: Font.DemiBold }
                    FText { text: Backend.storageText; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary }
                }
                FText { visible: Backend.sysStorageScanning; text: "Scanning…"; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary }
            }
            Rectangle {   // usage bar
                Layout.fillWidth: true
                implicitHeight: 8
                radius: 4
                color: Theme.sliderTrack
                Rectangle {
                    width: parent.width * Backend.storageRatio
                    height: parent.height
                    radius: 4
                    color: Theme.accent
                }
            }
        }
    }

    // ---------------------------------------------------------- categories
    Repeater {
        model: Backend.sysStorageCats
        delegate: SettingsCard {
            required property var modelData
            icon: modelData.icon
            title: modelData.name
            clickable: modelData.name === "Temporary files"
            onClicked: Router.open("pages/system/StorageTempFilesPage.qml", {})
            FText { text: modelData.text; color: Theme.textSecondary }
        }
    }

    // ---------------------------------------------------------- management
    SectionHeader { text: "Storage management" }
    SettingsCard {
        enabled: false
        icon: "fl:storage_20_regular"
        title: "Storage Sense"
        description: "Not available on Linux. Use Temporary files to free up space"
        FluentToggle { checked: false }
    }
    ExpanderCard {
        icon: "fl:alert_20_regular"
        title: "Low disk space warning"
        description: "Get a notification when free space on your home folder gets low"
        headerControls: [
            SysCfgToggle { cfgFile: "freespacenotifierrc"; cfgGroup: "General"; cfgKey: "enableNotification"; cfgDefault: true }
        ]
        ExpanderRow {
            title: "Warn me when free space drops below"
            divider: false
            SysCfgCombo {
                cfgFile: "freespacenotifierrc"; cfgGroup: "General"; cfgKey: "minimumSpace"; cfgDefault: "200"
                model: ["100 MB", "200 MB", "500 MB", "1 GB", "2 GB", "5 GB", "10 GB"]
                values: ["100", "200", "500", "1024", "2048", "5120", "10240"]
            }
        }
    }

    SectionHeader { text: "Advanced storage settings" }
    ExpanderCard {
        icon: "fl:settings_20_regular"
        title: "Advanced storage settings"
        description: "Disks & volumes, where new content is saved, removable drives"
        expanded: true
        SysLinkRow {
            title: "Disks & volumes"
            description: "View drives, partitions and free space"
            divider: false
            onClicked: Router.open("pages/system/StorageDisksPage.qml", {})
        }
        SysLinkRow {
            title: "Where new content is saved"
            description: "Change where your documents, music, pictures and videos are stored"
            onClicked: Router.open("pages/system/StoragePathsPage.qml", {})
        }
        ExpanderRow {
            title: "Mount removable drives when they are plugged in"
            SysCfgToggle { cfgFile: "kded_device_automounterrc"; cfgGroup: "General"; cfgKey: "AutomountOnPlugin"; showLabel: false }
        }
        ExpanderRow {
            title: "Mount removable drives at sign-in"
            SysCfgToggle { cfgFile: "kded_device_automounterrc"; cfgGroup: "General"; cfgKey: "AutomountOnLogin"; showLabel: false }
        }
    }
}
