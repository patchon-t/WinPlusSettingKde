import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Network & internet", "Wi-Fi", "Manage known networks"]

    Component.onCompleted: Backend.refreshNetConnections()

    NetToast {}

    SectionHeader { text: "Known networks"; visible: Backend.netKnownWifi.length > 0 }

    Repeater {
        model: Backend.netKnownWifi
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:wifi_1_20_regular"
            title: modelData.name
            description: modelData.active ? "Connected" : (modelData.autoconnect ? "Connects automatically" : "")
            clickable: true
            onClicked: Router.open("pages/network/NetConnectionPage.qml", { connName: modelData.name })
            FluentButton {
                text: "Forget"
                onClicked: Backend.netForget(modelData.name)
            }
        }
    }

    FText {
        visible: Backend.netKnownWifi.length === 0
        text: "No saved networks yet. Networks you connect to are remembered here."
        color: Theme.textSecondary
        Layout.topMargin: 8
    }
}
