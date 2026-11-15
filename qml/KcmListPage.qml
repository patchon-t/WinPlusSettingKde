import QtQuick
import QtQuick.Layouts
import WinSettings
import "."

// Generic list page built from Data.js. Custom pages can put their own
// content above the list with `header`, and title the list with `listTitle`.
SettingsPage {
    id: page
    property string pageTitle
    property var items: []
    property Component header: null
    property string listTitle: ""
    crumbs: [pageTitle]

    Loader {
        Layout.fillWidth: true
        active: page.header !== null
        visible: active
        sourceComponent: page.header
    }

    SectionHeader { text: page.listTitle; visible: page.listTitle.length > 0 && page.items.length > 0 }

    Repeater {
        model: page.items
        delegate: SettingsCard {
            required property var modelData
            icon: modelData.icon || ""
            title: modelData.title
            description: modelData.desc || ""
            clickable: !!(modelData.page || modelData.kcm || modelData.cmd)
            onClicked: Router.activate(modelData)

            FluentToggle {
                visible: modelData.toggle === "bluetooth"
                enabled: Backend.bluetoothAvailable
                checked: Backend.bluetoothOn
                onToggled: (c) => Backend.setBluetooth(c)
            }
        }
    }
}
