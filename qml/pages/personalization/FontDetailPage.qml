import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    property string family: ""
    crumbs: ["Personalization", "Fonts", family]

    property var faces: []
    readonly property bool canUninstall: {
        for (let i = 0; i < faces.length; ++i)
            if (faces[i].user)
                return true
        return false
    }

    Component.onCompleted: faces = Backend.fontFaces(family)
    Connections {
        target: Backend
        function onFontStateChanged() { page.faces = Backend.fontFaces(page.family) }
    }

    // ---------------------------------------------------------- preview
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: pcol.implicitHeight + 32
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        ColumnLayout {
            id: pcol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8
            TextField {
                id: sample
                Layout.fillWidth: true
                text: "The quick brown fox jumps over the lazy dog"
                font.family: page.family
                font.pixelSize: sizeSlider.value
                color: Theme.text
                selectByMouse: true
                background: Item {}
                padding: 0
            }
            RowLayout {
                spacing: 12
                FText { text: "Size"; color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
                FluentSlider {
                    id: sizeSlider
                    from: 12
                    to: 72
                    value: 28
                    stepSize: 1
                    implicitWidth: 240
                }
                FText { text: Math.round(sizeSlider.value) + " px"; color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
            }
        }
    }

    // ---------------------------------------------------------- metadata
    SectionHeader { text: "Metadata" }

    SettingsCard {
        icon: "fl:text_font_20_regular"
        title: "Font family"
        FText { text: page.family; color: Theme.textSecondary }
    }

    SectionHeader { text: "Font faces" }

    FText {
        visible: page.faces.length === 0
        text: "This font is no longer installed."
        color: Theme.textSecondary
    }
    Repeater {
        model: page.faces
        delegate: SettingsCard {
            required property var modelData
            title: modelData.style
            description: modelData.file
            FText { text: modelData.user ? "Installed for you" : "Installed for all users"; color: Theme.textSecondary; font.pixelSize: Theme.fontCaption }
        }
    }

    SectionHeader { text: "Uninstall" }

    SettingsCard {
        icon: "fl:delete_20_regular"
        title: "Uninstall this font"
        description: page.canUninstall ? "Remove the font files installed for your account"
                                       : "System fonts can't be removed from here"
        enabled: page.canUninstall
        FluentButton {
            text: "Uninstall"
            onClicked: { Backend.uninstallFont(page.family); Router.back() }
        }
    }
}
