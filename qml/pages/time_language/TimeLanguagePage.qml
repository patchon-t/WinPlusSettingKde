import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Time & language top page: big clock header above the section cards
KcmListPage {
    id: page

    Component.onCompleted: Backend.refreshTime()

    header: Component {
        ColumnLayout {
            id: hdr
            property date now: new Date()
            function tzLabel() {
                const i = Backend.timezones.indexOf(Backend.timezone)
                return i >= 0 ? Backend.timezoneLabels[i] : Backend.timezone.replace(/_/g, " ")
            }
            Layout.bottomMargin: 12
            spacing: 0
            Timer { interval: 1000; repeat: true; running: true; onTriggered: hdr.now = new Date() }
            RowLayout {
                spacing: 16
                Icon { name: "fl:clock_20_regular"; size: 40 }
                ColumnLayout {
                    spacing: 0
                    FText {
                        text: Qt.formatTime(hdr.now, Qt.locale().timeFormat(Locale.ShortFormat))
                        font.pixelSize: 40
                        font.weight: Font.DemiBold
                    }
                    FText {
                        text: Qt.formatDate(hdr.now, Qt.locale().dateFormat(Locale.LongFormat))
                              + (hdr.tzLabel().length ? "  ·  " + hdr.tzLabel() : "")
                        font.pixelSize: Theme.fontCaption
                        color: Theme.textSecondary
                    }
                }
            }
        }
    }
}
