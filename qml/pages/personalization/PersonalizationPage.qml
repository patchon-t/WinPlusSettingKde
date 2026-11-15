import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 Personalization: desktop preview + "Select a theme to apply", then the card list
KcmListPage {
    id: page

    Component.onCompleted: Backend.refreshLookAndFeel()

    header: Component {
        Rectangle {
            id: top
            readonly property var themes: Backend.lookAndFeel.themes || []
            Layout.fillWidth: true
            Layout.bottomMargin: 12
            implicitHeight: Math.max(188, strip.implicitHeight + 40)
            radius: Theme.radiusLarge
            color: Theme.cardBg
            border.color: Theme.cardBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 24

                PerPreview { Layout.alignment: Qt.AlignTop }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 10
                    FText { text: "Select a theme to apply"; font.weight: Font.DemiBold }
                    FText {
                        visible: top.themes.length === 0
                        text: "No global themes found"
                        font.pixelSize: Theme.fontCaption
                        color: Theme.textSecondary
                    }
                    Flow {
                        id: strip
                        Layout.fillWidth: true
                        spacing: 10
                        Repeater {
                            model: top.themes.slice(0, 6)
                            delegate: PerThumb {
                                required property var modelData
                                thumbWidth: 100
                                thumbHeight: 60
                                source: modelData.preview
                                label: modelData.name
                                selected: modelData.id === Backend.lookAndFeel.current
                                onClicked: Backend.applyLookAndFeel(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
