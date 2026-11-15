import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Default apps > Choose defaults by file type / by link type  (APP.DEF.3)
SettingsPage {
    id: page
    property string kind: "file"     // "file" | "link"
    property var rows: []
    readonly property string pageName: kind === "link" ? "Choose defaults by link type" : "Choose defaults by file type"
    crumbs: ["Apps", "Default apps", pageName]

    function reload() { rows = Backend.appsAllTypes(kind, search.text) }
    Component.onCompleted: {
        Backend.appsRefresh()
        reload()
    }
    Connections {
        target: Backend
        function onAppsChanged() { page.reload() }
    }

    AppsAppPicker { id: picker }

    AppsSearch {
        id: search
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        placeholderText: page.kind === "link" ? "Search link types" : "Search file types"
        onTextChanged: page.reload()
    }
    FText {
        visible: page.rows.length === 0
        text: Backend.appsLoading ? "Loading..." : "Nothing matches your search."
        color: Theme.textSecondary
        Layout.leftMargin: 4
    }
    Repeater {
        model: page.rows
        delegate: AppsTypeRow {
            required property var modelData
            readonly property var cur: Backend.appsDefaults[modelData.mime]
            title: modelData.label
            mime: modelData.mime
            defName: cur ? cur.name : modelData.defName
            defIcon: cur ? cur.icon : modelData.defIcon
            onPick: picker.openFor(modelData.mime, modelData.label)
        }
    }
}
