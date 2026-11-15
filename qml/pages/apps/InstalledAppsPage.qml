import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WinSettings
import "../.."

// Apps > Installed apps  (APP.INS.1 / APP.INS.2 / APP.INS.4)
Item {
    id: page
    readonly property int sidePadding: 28
    readonly property int maxContentWidth: 1000
    property string toastText: ""
    property string query: ""
    property int sortIdx: 0
    property int filterIdx: 0

    function applyView() {
        Backend.appsSetView(query, sortIdx, filterIdx)
    }

    Component.onCompleted: {
        Backend.appsRefresh()
        applyView()
    }

    Connections {
        target: Backend
        function onAppsUninstallFinished(name, ok) {
            page.toastText = ok ? name + " was uninstalled." : "Couldn't uninstall " + name + "."
            toastTimer.restart()
        }
    }
    Timer { id: toastTimer; interval: 5000; onTriggered: page.toastText = "" }

    PageHeader {
        id: pageHeader
        crumbs: ["Apps", "Installed apps"]
        x: page.sidePadding
        y: 4
    }

    AppsMenu {
        id: menu
        property var target: null
        onChosen: (i) => {
            if (!target)
                return
            if (entries[i].action === "advanced")
                Router.open("pages/apps/AppAdvancedPage.qml", { appId: target.appId })
            else if (entries[i].action === "uninstall") {
                confirm.target = target
                confirm.parent = menu.parent
                confirm.open()
            }
        }
    }
    AppsConfirm {
        id: confirm
        property var target: null
        message: "This app and its related info will be uninstalled."
        onAccepted: if (target) Backend.appsUninstall(target.appId)
    }

    ListView {
        id: list
        anchors.top: pageHeader.bottom
        anchors.topMargin: 20
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 4
        cacheBuffer: 600
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: FluentScrollBar {}
        model: Backend.appsModel
        readonly property real contentW: Math.min(width - page.sidePadding * 2, page.maxContentWidth)

        header: ColumnLayout {
            x: page.sidePadding
            width: list.contentW
            spacing: 4

            AppsSearch {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search apps"
                onTextChanged: { page.query = text; page.applyView() }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                spacing: 12
                FText { text: "Sort by:"; color: Theme.textSecondary }
                FluentCombo {
                    id: sortBox
                    autoSelect: true
                    minWidth: 190
                    model: ["Name (A to Z)", "Name (Z to A)", "Size (large to small)", "Size (small to large)",
                            "Install date (newest first)", "Install date (oldest first)"]
                    onActivated: { page.sortIdx = currentIndex; page.applyView() }
                }
                FText { text: "Filter by:"; color: Theme.textSecondary; Layout.leftMargin: 12 }
                FluentCombo {
                    id: filterBox
                    autoSelect: true
                    minWidth: 170
                    model: ["All sources", "System packages", "Flatpak", "Other"]
                    onActivated: { page.filterIdx = currentIndex; page.applyView() }
                }
                Item { Layout.fillWidth: true }
                FText {
                    visible: !Backend.appsLoading
                    text: Backend.appsShown + (Backend.appsShown === 1 ? " app found" : " apps found")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontCaption
                }
            }
        }

        footer: Item {
            width: list.width
            height: Backend.appsLoading || Backend.appsShown === 0 ? 120 : 24
            FText {
                anchors.centerIn: parent
                visible: Backend.appsLoading || Backend.appsShown === 0
                text: Backend.appsLoading ? "Loading apps..."
                      : page.query.length ? "We couldn't find any apps matching \"" + page.query + "\"."
                      : "No apps found."
                color: Theme.textSecondary
            }
        }

        delegate: Item {
            id: row
            required property string appId
            required property string name
            required property string icon
            required property string details
            required property string source
            required property string sizeText
            required property string dateText
            required property bool canUninstall
            required property bool isFlatpak
            readonly property bool busy: Backend.appsBusyId === appId

            width: list.width
            height: 64

            Rectangle {
                x: page.sidePadding
                width: list.contentW
                height: parent.height
                radius: Theme.radius
                color: Theme.cardBg
                border.color: Theme.cardBorder
                opacity: row.busy ? 0.6 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    spacing: 0
                    Icon { name: row.icon; size: 32; Layout.rightMargin: 16 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        FText { text: row.name; Layout.fillWidth: true; elide: Text.ElideRight }
                        FText {
                            text: row.busy ? "Uninstalling..." : (row.details.length ? row.details : row.source)
                            font.pixelSize: Theme.fontCaption
                            color: Theme.textSecondary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                    ColumnLayout {
                        Layout.preferredWidth: 90
                        Layout.rightMargin: 8
                        spacing: 1
                        FText { text: row.sizeText; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary; Layout.alignment: Qt.AlignRight }
                        FText { text: row.dateText; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary; Layout.alignment: Qt.AlignRight }
                    }
                    Rectangle {
                        id: more
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: Theme.radius
                        enabled: !row.busy && (row.canUninstall || row.isFlatpak)
                        opacity: enabled ? 1 : 0.4
                        color: mma.pressed ? Theme.subtlePressed : mma.containsMouse ? Theme.subtleHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durFaster } }
                        Icon { anchors.centerIn: parent; name: "fl:more_horizontal_20_regular"; size: 16 }
                        MouseArea {
                            id: mma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                const e = []
                                if (row.isFlatpak)
                                    e.push({ text: "Advanced options", icon: "fl:settings_20_regular", action: "advanced" })
                                e.push({ text: "Uninstall", icon: "fl:delete_20_regular", action: "uninstall", enabled: row.canUninstall })
                                menu.entries = e
                                menu.target = { appId: row.appId }
                                menu.parent = more
                                menu.open()
                            }
                        }
                    }
                }
            }
        }
    }

    // result toast
    Rectangle {
        visible: page.toastText.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        implicitWidth: toastLabel.implicitWidth + 40
        implicitHeight: 44
        radius: Theme.radiusLarge
        color: Theme.flyoutBg
        border.color: Theme.flyoutBorder
        FText { id: toastLabel; anchors.centerIn: parent; text: page.toastText }
    }
}
