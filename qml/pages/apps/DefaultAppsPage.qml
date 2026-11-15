import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Apps > Default apps  (APP.DEF.1 - APP.DEF.4)
SettingsPage {
    id: page
    crumbs: ["Apps", "Default apps"]

    property var typeResults: []
    property var appResults: []
    property var terminals: []

    function runTypeSearch() {
        typeResults = Backend.appsSearchTypes(typeSearch.text)
        Backend.appsQueryDefaults(typeResults.map(r => r.mime))
    }
    function runAppSearch() { appResults = Backend.appsHandlerApps(appSearch.text) }
    function reload() {
        runAppSearch()
        terminals = Backend.appsTerminals()
        if (typeSearch.text.length)
            runTypeSearch()
    }

    Component.onCompleted: {
        Backend.appsRefresh()
        Backend.appsRefreshTerminal()
        reload()
    }
    Connections {
        target: Backend
        function onAppsChanged() { page.reload() }
    }

    AppsAppPicker { id: picker }

    // ---- file / link type search
    SectionHeader { text: "Set a default for a file type or link type"; Layout.topMargin: 0 }
    AppsSearch {
        id: typeSearch
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        placeholderText: "Enter a file type (like .pdf) or a link type (like mailto)"
        onTextChanged: page.runTypeSearch()
    }
    FText {
        visible: typeSearch.text.length > 0 && page.typeResults.length === 0
        text: "No file or link type matches \"" + typeSearch.text + "\"."
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
        Layout.leftMargin: 4
    }
    Repeater {
        model: page.typeResults
        delegate: AppsTypeRow {
            required property var modelData
            readonly property var cur: Backend.appsDefaults[modelData.mime]
            title: modelData.label
            mime: modelData.mime
            defName: cur ? cur.name : ""
            defIcon: cur ? cur.icon : ""
            onPick: picker.openFor(modelData.mime, modelData.label)
        }
    }

    // ---- terminal
    SectionHeader { text: "Terminal" }
    SettingsCard {
        icon: "fl:window_console_20_regular"
        title: "Default terminal app"
        description: page.terminals.length ? "Used when an app or the file manager opens a terminal"
                                           : "No terminal app found"
        FluentCombo {
            enabled: page.terminals.length > 0
            minWidth: 180
            model: page.terminals.map(t => t.name)
            currentIndex: page.terminals.findIndex(t => t.id === Backend.appsTerminalId)
            onActivated: (i) => Backend.appsSetTerminal(page.terminals[i].id)
        }
    }

    // ---- per-app
    SectionHeader { text: "Set defaults for applications" }
    AppsSearch {
        id: appSearch
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        placeholderText: "Search apps"
        onTextChanged: page.runAppSearch()
    }
    FText {
        visible: Backend.appsLoading || page.appResults.length === 0
        text: Backend.appsLoading ? "Loading apps..." : "No apps found."
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
        Layout.leftMargin: 4
    }
    Repeater {
        model: page.appResults
        delegate: SettingsCard {
            required property var modelData
            icon: modelData.icon
            title: modelData.name
            description: modelData.count + (modelData.count === 1 ? " file and link type" : " file and link types")
            clickable: true
            onClicked: Router.open("pages/apps/DefaultAppPage.qml", { appId: modelData.id })
        }
    }

    // ---- related
    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:document_multiple_20_regular"
        title: "Choose defaults by file type"
        description: "See and change the default app for every file type"
        clickable: true
        onClicked: Router.open("pages/apps/DefaultTypesPage.qml", { kind: "file" })
    }
    SettingsCard {
        icon: "fl:link_multiple_20_regular"
        title: "Choose defaults by link type"
        description: "See and change the default app for web, mail and other links"
        clickable: true
        onClicked: Router.open("pages/apps/DefaultTypesPage.qml", { kind: "link" })
    }
}
