import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Storage", "Temporary files"]

    property var selected: ({ trash: false, thumbs: true, cache: false })
    readonly property var selectedIds: Object.keys(selected).filter(k => selected[k])
    readonly property real selectedBytes: {
        let t = 0
        for (let i = 0; i < Backend.sysTempItems.length; ++i) {
            const it = Backend.sysTempItems[i]
            if (selected[it.id]) t += it.bytes
        }
        return t
    }

    Component.onCompleted: Backend.sysRefreshTemp()

    FText {
        text: "Select the files you want to remove. Apps may take a little longer to start the next time you open them."
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.fillWidth: true
        Layout.bottomMargin: 8
    }

    Repeater {
        model: Backend.sysTempItems
        delegate: SettingsCard {
            required property var modelData
            icon: "fl:delete_20_regular"
            title: modelData.name
            description: modelData.desc
            SysCheck {
                checked: !!page.selected[modelData.id]
                onToggled: (c) => {
                    const s = Object.assign({}, page.selected)
                    s[modelData.id] = c
                    page.selected = s
                }
            }
            FText { text: modelData.text; color: Theme.textSecondary; Layout.preferredWidth: 72; horizontalAlignment: Text.AlignRight }
        }
    }

    RowLayout {
        Layout.topMargin: 16
        spacing: 16
        FluentButton {
            text: "Remove files"
            accent: true
            enabled: page.selectedIds.length > 0
            onClicked: Backend.sysRemoveTemp(page.selectedIds)
        }
        FText {
            text: "Total selected: " + Backend.sysHumanSize(page.selectedBytes)
            color: Theme.textSecondary
        }
    }
}
