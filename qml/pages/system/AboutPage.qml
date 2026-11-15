import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "About"]

    Component.onCompleted: Backend.sysRefreshAbout()

    // header: device name + rename
    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        implicitHeight: 84
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            spacing: 16
            Icon { name: "fl:laptop_20_color"; size: 40 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                FText { text: Backend.hostname; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold }
                FText { text: Backend.deviceModel; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary }
            }
            FluentButton { text: "Rename this PC"; onClicked: renameDialog.open() }
        }
    }

    InputDialog {
        id: renameDialog
        title: "Rename your PC"
        message: "Letters, numbers and hyphens only. You'll be asked for your password."
        placeholder: Backend.hostname
        acceptText: "Rename"
        onSubmitted: (v) => Backend.renameHost(v)
    }

    SysInfoCard {
        icon: "fl:info_20_regular"
        title: "Device specifications"
        rows: Backend.deviceSpecs
        copyButton: true
    }
    SysInfoCard {
        icon: "fl:apps_20_regular"
        title: "Operating system specifications"
        rows: Backend.osSpecs
        copyButton: true
    }
}
