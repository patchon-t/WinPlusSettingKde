import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Default apps > (app): every file / link type the app can open and its current default
SettingsPage {
    id: page
    property string appId: ""
    property var info: ({})
    property var types: []
    crumbs: ["Apps", "Default apps", info.name || "App"]

    function reload() {
        info = appId.length ? Backend.appsInfo(appId) : ({})
        types = appId.length ? Backend.appsMimesOf(appId) : []
        Backend.appsQueryDefaults(types.map(t => t.mime))
    }
    Component.onCompleted: {
        Backend.appsRefresh()
        reload()
    }
    Connections {
        target: Backend
        function onAppsChanged() { page.reload() }
    }

    AppsAppPicker { id: picker }

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
            Icon { name: info.icon || "application-x-executable"; size: 40 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                FText { text: info.name || "App not found"; font.pixelSize: Theme.fontSubtitle; font.weight: Font.DemiBold }
                FText {
                    text: "Set a default for each file type and link type this app can open"
                    font.pixelSize: Theme.fontCaption
                    color: Theme.textSecondary
                }
            }
        }
    }

    FText {
        visible: types.length === 0
        text: Backend.appsLoading ? "Loading..." : "This app doesn't declare any file or link types."
        color: Theme.textSecondary
        Layout.leftMargin: 4
    }
    Repeater {
        model: page.types
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
}
