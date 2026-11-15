import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Expanded card with read-only key / value rows (Display information, About specs).
ExpanderCard {
    id: sc
    property var rows: []           // [{k, v}]
    property bool copyButton: false
    function asText() { return rows.map(r => r.k + "\t" + r.v).join("\n") }
    expanded: true
    headerControls: [
        FluentButton {
            visible: sc.copyButton
            text: "Copy"
            onClicked: Backend.copyText(sc.asText())
        }
    ]
    Repeater {
        model: sc.rows
        delegate: RowLayout {
            required property var modelData
            required property int index
            Layout.fillWidth: true
            Layout.leftMargin: 56
            Layout.rightMargin: 48
            Layout.topMargin: index === 0 ? 14 : 4
            Layout.bottomMargin: index === sc.rows.length - 1 ? 16 : 0
            spacing: 12
            FText {
                text: modelData.k
                color: Theme.textSecondary
                Layout.preferredWidth: 180
            }
            FText {
                text: modelData.v
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
        }
    }
}
