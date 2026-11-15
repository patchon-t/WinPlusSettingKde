import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accessibility", "Text size"]

    property int pending: Backend.a11yTextScale

    Connections {
        target: Backend
        function onA11yTextChanged() { page.pending = Backend.a11yTextScale }
    }

    // Live preview box
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: pv.implicitHeight + 40
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        clip: true
        ColumnLayout {
            id: pv
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 20
            spacing: 4
            FText {
                text: "Text size preview"
                font.weight: Font.DemiBold
                font.pixelSize: Math.round(Theme.fontBody * page.pending / 100)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            FText {
                text: "The quick brown fox jumps over the lazy dog."
                font.pixelSize: Math.round(Theme.fontBody * page.pending / 100)
                color: Theme.textSecondary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    SettingsCard {
        icon: "fl:text_font_size_20_regular"
        title: "Text size"
        description: "Drag the slider to make the text on screen larger"
        FluentSlider {
            id: sl
            from: 100; to: 225; stepSize: 1
            value: page.pending
            onMoved: page.pending = Math.round(value)
        }
        FText {
            text: page.pending + "%"
            Layout.preferredWidth: 44
            horizontalAlignment: Text.AlignRight
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        FluentButton {
            text: "Apply"
            accent: true
            enabled: page.pending !== Backend.a11yTextScale && !Backend.a11yTextBusy
            onClicked: Backend.a11yApplyTextSize(page.pending)
        }
    }
}
