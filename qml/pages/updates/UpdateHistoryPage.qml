import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 › Windows Update › Update history, grouped like Win11.
SettingsPage {
    id: page
    crumbs: ["System updates", "Update history"]

    Component.onCompleted: Backend.refreshUpdateHistory()

    function entries(kind) {
        return Backend.updatesHistory.filter(function (e) { return e.kind === kind })
    }

    component HistoryGroup: ExpanderCard {
        id: grp
        property string kind
        property var list: []
        title: kind
        description: list.length === 1 ? "1 update" : list.length + " updates"
        expanded: kind === "Quality updates"
        Repeater {
            model: grp.list
            delegate: ExpanderRow {
                required property var modelData
                required property int index
                title: modelData.name
                description: modelData.detail + (modelData.date ? " · " + modelData.date : "")
                divider: index > 0
            }
        }
    }

    HistoryGroup { icon: "fl:arrow_sync_20_regular"; kind: "Quality updates"; list: page.entries(kind) }
    HistoryGroup { icon: "fl:developer_board_20_regular"; kind: "Driver updates"; list: page.entries(kind) }
    HistoryGroup { icon: "fl:box_20_regular"; kind: "Other updates"; list: page.entries(kind) }

    SettingsCard {
        visible: Backend.updatesHistory.length === 0
        icon: "fl:history_20_regular"
        title: "No update history yet"
        description: "Updates you install will show up here"
    }
}
