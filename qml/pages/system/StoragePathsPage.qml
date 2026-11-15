import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Storage", "Where new content is saved"]

    readonly property var dirs: [
        { key: "DOCUMENTS", label: "New documents will save to", icon: "fl:document_20_regular" },
        { key: "MUSIC", label: "New music will save to", icon: "fl:headphones_20_regular" },
        { key: "PICTURES", label: "New photos and videos will save to", icon: "fl:image_20_regular" },
        { key: "VIDEOS", label: "New videos will save to", icon: "fl:desktop_20_regular" },
        { key: "DOWNLOAD", label: "Downloads will save to", icon: "fl:arrow_download_20_regular" }
    ]

    Component.onCompleted: Backend.sysRefreshStorage()

    FText {
        text: "Enter a folder path and press Apply. The folder is created if it doesn't exist."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 8
    }

    Repeater {
        model: page.dirs
        delegate: SettingsCard {
            id: row
            required property var modelData
            icon: modelData.icon
            title: modelData.label
            readonly property string current: Backend.sysUserDirs[modelData.key] || ""
            SysTextBox {
                id: field
                implicitWidth: 300
                text: row.current
                onAccepted: Backend.sysSetUserDir(row.modelData.key, text)
            }
            FluentButton {
                text: "Apply"
                enabled: field.text.startsWith("/") && field.text !== row.current
                onClicked: Backend.sysSetUserDir(row.modelData.key, field.text)
            }
        }
    }
}
