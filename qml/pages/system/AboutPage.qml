import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "About"]

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

    component SpecCard: ExpanderCard {
        id: sc
        property var rows: []
        function asText() { return rows.map(r => r.k + "\t" + r.v).join("\n") }
        expanded: true
        headerControls: [
            FluentButton { text: "Copy"; onClicked: Backend.copyText(sc.asText()) }
        ]
        Repeater {
            model: sc.rows
            delegate: RowLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.leftMargin: 56
                Layout.rightMargin: 48
                Layout.topMargin: index === 0 ? 14 : 4
                Layout.bottomMargin: index === sc.rows.length - 1 ? 16 : 0
                spacing: 12
                FText {
                    text: modelData.k
                    color: Theme.textSecondary
                    Layout.preferredWidth: 180
                }
                FText {
                    text: modelData.v
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    SpecCard { icon: "fl:info_20_regular"; title: "Device specifications"; rows: Backend.deviceSpecs }
    SpecCard { icon: "fl:apps_20_regular"; title: "Operating system specifications"; rows: Backend.osSpecs }

    SectionHeader { text: "Related" }
    SettingsCard {
        icon: "fl:developer_board_20_regular"
        title: "Full system information"
        description: "Hardware, drivers, memory, graphics"
        clickable: true
        onClicked: Backend.runCommand(["kinfocenter"])
    }
}
