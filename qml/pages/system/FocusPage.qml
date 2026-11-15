import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Focus"]

    property int dndLeft: 0
    property int durIndex: 2
    readonly property var minutes: [15, 30, 45, 60, 90, 120, 180, 240]
    readonly property var labels: ["15 minutes", "30 minutes", "45 minutes", "1 hour", "1.5 hours", "2 hours", "3 hours", "4 hours"]
    function refreshDnd() { dndLeft = Backend.sysDndRemaining() }
    function fmt(s) {
        const m = Math.floor(s / 60), sec = s % 60
        return (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec
    }
    Component.onCompleted: { Backend.sysCfgReload(); refreshDnd() }
    Connections { target: Backend; function onSysCfgChanged() { page.refreshDnd() } }
    Timer { interval: 1000; repeat: true; running: page.dndLeft > 0; onTriggered: page.refreshDnd() }

    // big timer card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 220
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 14
            FText {
                Layout.alignment: Qt.AlignHCenter
                text: page.dndLeft > 0 ? page.fmt(page.dndLeft)
                      : page.dndLeft < 0 ? "Do not disturb is on" : page.minutes[page.durIndex] + ":00"
                font.pixelSize: 56
                font.weight: Font.DemiBold
            }
            FText {
                Layout.alignment: Qt.AlignHCenter
                text: page.dndLeft > 0 ? "Focus session in progress" : "Stay on task. Notifications are silenced during a focus session."
                color: Theme.textSecondary
                font.pixelSize: Theme.fontCaption
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                FluentCombo {
                    minWidth: 150
                    visible: page.dndLeft === 0
                    model: page.labels
                    currentIndex: page.durIndex
                    onActivated: (i) => page.durIndex = i
                }
                FluentButton {
                    text: page.dndLeft === 0 ? "Start focus session" : "Stop focus session"
                    accent: page.dndLeft === 0
                    onClicked: page.dndLeft === 0 ? Backend.sysFocusStart(page.minutes[page.durIndex]) : Backend.sysFocusStop()
                }
            }
        }
    }

    SectionHeader { text: "Focus settings" }
    SettingsCard {
        icon: "fl:apps_20_regular"
        title: "Show badges on taskbar apps"
        description: "Show unread counts on app icons in the task manager"
        SysCfgToggle { cfgFile: "plasmanotifyrc"; cfgGroup: "Badges"; cfgKey: "InTaskManager"; cfgDefault: true }
    }
    SettingsCard {
        icon: "fl:alert_snooze_20_regular"
        title: "Turn on do not disturb"
        description: "Silence notifications until you turn it off"
        FluentToggle {
            checked: page.dndLeft !== 0
            onToggled: (c) => Backend.sysDndSet(c)
        }
    }
}
