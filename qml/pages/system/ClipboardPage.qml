import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Clipboard"]

    Component.onCompleted: Backend.sysCfgReload()

    ExpanderCard {
        icon: "fl:clipboard_20_regular"
        title: "Clipboard history"
        description: "Save multiple items to the clipboard to use later"
        headerControls: [
            SysCfgToggle { cfgFile: "klipperrc"; cfgGroup: "General"; cfgKey: "KeepClipboardContents"; cfgDefault: true }
        ]
        ExpanderRow {
            title: "Number of items to keep"
            divider: false
            SysCfgCombo {
                cfgFile: "klipperrc"; cfgGroup: "General"; cfgKey: "MaxClipItems"; cfgDefault: "20"
                model: ["5", "10", "20", "50", "100", "200"]
                values: ["5", "10", "20", "50", "100", "200"]
            }
        }
    }
    SettingsCard {
        enabled: false
        icon: "fl:phone_laptop_20_regular"
        title: "Sync across your devices"
        description: "Not available yet"
        FluentToggle { checked: false }
    }
    SettingsCard {
        icon: "fl:sparkle_20_regular"
        title: "Suggested actions"
        description: "Show actions for links and other data you copy"
        SysCfgToggle { cfgFile: "klipperrc"; cfgGroup: "General"; cfgKey: "URLGrabberEnabled"; cfgDefault: false }
    }

    SectionHeader { text: "Clear clipboard data" }
    SettingsCard {
        icon: "fl:delete_20_regular"
        title: "Clear clipboard data"
        description: "Clear everything on the clipboard, including the history"
        FluentButton { text: "Clear"; onClicked: Backend.sysClearClipboard() }
    }
}
