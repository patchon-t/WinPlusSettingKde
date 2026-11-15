import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Privacy & security", "Activity history"]

    readonly property var monthValues: [1, 2, 3, 4, 6, 12, 0]
    readonly property var monthLabels: ["1 month", "2 months", "3 months", "4 months", "6 months", "12 months", "Forever"]
    property string result: ""
    property bool resultOk: true

    Component.onCompleted: Backend.refreshPrvActivity()

    Connections {
        target: Backend
        function onPrvActivityResult(ok, msg) { page.resultOk = ok; page.result = msg }
    }

    PrvInfoBar {
        visible: page.result.length > 0
        severity: page.resultOk ? "success" : "warning"
        title: page.result
    }

    FText {
        text: "Your activity history is the list of recent files and places that Plasma remembers so it can show them in menus and search."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.bottomMargin: 8
    }

    SettingsCard {
        icon: "fl:history_20_regular"
        title: "Store my activity history on this device"
        description: Backend.prvActivityWhat === 1 ? "Remembering only some apps" : "Remember recent files and places"
        FluentToggle {
            checked: Backend.prvActivityWhat !== 2
            onToggled: (v) => Backend.setPrvActivityStore(v)
        }
    }

    SettingsCard {
        icon: "fl:calendar_20_regular"
        title: "Keep history for"
        description: "Older activity is removed automatically"
        enabled: Backend.prvActivityWhat !== 2
        FluentCombo {
            model: page.monthLabels
            currentIndex: Math.max(0, page.monthValues.indexOf(Backend.prvActivityMonths))
            onActivated: (i) => Backend.setPrvActivityMonths(page.monthValues[i])
        }
    }

    SectionHeader { text: "Clear activity history for this device" }

    SettingsCard {
        icon: "fl:delete_20_regular"
        title: "Clear history"
        description: "Remove all recent files and places that Plasma has stored"
        FluentButton { text: "Clear history"; onClicked: confirm.open() }
    }

    PrvConfirmDialog {
        id: confirm
        title: "Clear your activity history?"
        message: "This removes all stored recent files and places on this device. It can't be undone."
        acceptText: "Clear"
        onAccepted: Backend.clearPrvActivity()
    }
}
