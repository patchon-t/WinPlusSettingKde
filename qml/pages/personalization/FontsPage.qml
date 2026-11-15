import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Fonts"]

    readonly property var fs: Backend.fontState
    property string query: ""
    property string language: ""

    Component.onCompleted: {
        if (fs.loaded !== true)
            Backend.refreshFonts()
        Backend.filterFonts(page.query, page.language)
    }

    // ---------------------------------------------------------- add fonts
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 112
        radius: Theme.radius
        color: Theme.cardBg
        border.color: dropArea.containsDrag ? Theme.accent : Theme.cardBorder
        border.width: dropArea.containsDrag ? 2 : 1

        DropArea {
            id: dropArea
            anchors.fill: parent
            onDropped: (drop) => { if (drop.hasUrls) Backend.installFonts(drop.urls) }
        }
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8
            FText {
                text: "Drag and drop to install"
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignHCenter
            }
            FText {
                text: "Fonts are installed for your account"
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }
            FluentButton {
                text: "Browse files"
                Layout.alignment: Qt.AlignHCenter
                onClicked: fontDialog.open()
            }
        }
    }

    // ---------------------------------------------------------- available fonts
    SectionHeader { text: "Available fonts" }

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 6
        spacing: 12

        TextField {
            id: search
            Layout.fillWidth: true
            implicitHeight: 32
            color: Theme.text
            placeholderText: "Type here to search"
            placeholderTextColor: Theme.textSecondary
            font.pixelSize: Theme.fontBody
            leftPadding: 11
            selectByMouse: true
            onTextChanged: { page.query = text; Backend.filterFonts(page.query, page.language) }
            background: Rectangle {
                radius: Theme.radius
                color: Theme.controlBgFocus
                border.color: Theme.controlBorder
                clip: true
                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                    height: search.activeFocus ? 2 : 1
                    color: search.activeFocus ? Theme.accent : Theme.controlBorderBottom
                }
            }
        }
        FText { text: "Filter by:"; color: Theme.textSecondary }
        FluentCombo {
            model: ["All languages"].concat(page.fs.langs || [])
            currentIndex: Math.max(0, (page.fs.langs || []).indexOf(page.language) + 1)
            minWidth: 190
            onActivated: (i) => {
                page.language = i === 0 ? "" : page.fs.langs[i - 1]
                Backend.filterFonts(page.query, page.language)
            }
        }
    }

    FText {
        text: fs.loading === true ? "Loading fonts..." : ((fs.count || 0) + " fonts found")
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 360
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        clip: true

        ListView {
            id: fontList
            anchors.fill: parent
            anchors.margins: 1
            model: page.fs.list || []
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: FluentScrollBar {}
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 56
                color: rma.pressed ? Theme.cardBgPressed : rma.containsMouse ? Theme.cardBgHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durFaster } }
                Rectangle {
                    visible: row.index > 0
                    width: parent.width
                    height: 1
                    color: Theme.divider
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 16
                    Text {
                        text: "Abc"
                        font.family: row.modelData.family
                        font.pixelSize: 24
                        color: Theme.text
                        Layout.preferredWidth: 72
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        FText { text: row.modelData.family; Layout.fillWidth: true; elide: Text.ElideRight }
                        FText {
                            text: row.modelData.faces + (row.modelData.faces === 1 ? " font face" : " font faces")
                            font.pixelSize: Theme.fontCaption
                            color: Theme.textSecondary
                        }
                    }
                    Glyph { lines: Theme.gChevronRight; width: 14; height: 14 }
                }
                MouseArea {
                    id: rma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Router.open("pages/personalization/FontDetailPage.qml", { family: row.modelData.family })
                }
            }
        }
        FText {
            anchors.centerIn: parent
            visible: fontList.count === 0 && fs.loading !== true
            text: "No fonts found"
            color: Theme.textSecondary
        }
    }

    // ---------------------------------------------------------- related
    SectionHeader { text: "Related settings" }

    SettingsCard {
        icon: "fl:text_font_size_20_regular"
        title: "Adjust ClearType text"
        description: "Not available yet"
        enabled: false
    }

    FileDialog {
        id: fontDialog
        title: "Choose fonts to install"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Fonts (*.ttf *.otf *.ttc *.pfb)"]
        onAccepted: Backend.installFonts(selectedFiles)
    }
}
