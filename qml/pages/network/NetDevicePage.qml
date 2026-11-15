import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Hardware and connection properties. ifname "" = every adapter.
SettingsPage {
    id: page
    property string ifname: ""
    property string pageName: "Hardware and connection properties"
    property var trail: ["Network & internet", "Advanced network settings"]
    crumbs: trail.concat([pageName])

    Component.onCompleted: Backend.loadNetDeviceInfo(ifname)
    onIfnameChanged: Backend.loadNetDeviceInfo(ifname)

    function asText(d) {
        let s = d.ifname + " (" + d.type + ")\n"
        for (let i = 0; i < d.rows.length; ++i) s += d.rows[i].label + ": " + d.rows[i].value + "\n"
        return s
    }

    Repeater {
        model: Backend.netDeviceInfo
        delegate: ColumnLayout {
            id: dev
            required property var modelData
            Layout.fillWidth: true
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 4
                FText {
                    text: dev.modelData.ifname + " · " + dev.modelData.type
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                FluentButton { text: "Copy"; onClicked: Backend.copyText(page.asText(dev.modelData)) }
            }
            NetInfoCard { rows: dev.modelData.rows }
        }
    }

    FText {
        visible: Backend.netDeviceInfo.length === 0
        text: "No network adapters found, or NetworkManager isn't running."
        color: Theme.textSecondary
    }
}
