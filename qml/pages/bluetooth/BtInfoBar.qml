import QtQuick
import QtQuick.Layouts
import "../.."

// Win11 InfoBar. severity: "info" | "warning" | "success"
Rectangle {
    id: bar
    property string title
    property string message
    property string severity: "info"
    Layout.fillWidth: true
    implicitHeight: Math.max(48, rl.implicitHeight + 24)
    radius: Theme.radius
    color: Theme.cardBg
    border.color: Theme.cardBorder

    RowLayout {
        id: rl
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12
        Icon {
            name: bar.severity === "warning" ? "fl:warning_20_regular"
                  : bar.severity === "success" ? "fl:checkmark_circle_20_regular" : "fl:info_20_regular"
            size: 20
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            FText { text: bar.title; visible: text.length > 0; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            FText {
                text: bar.message
                visible: text.length > 0
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }
}
