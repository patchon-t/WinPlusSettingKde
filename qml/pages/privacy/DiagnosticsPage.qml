import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Privacy & security", "Diagnostics & feedback"]

    // KUserFeedback::Provider telemetry levels (provider.h:162-165)
    readonly property var levels: [0, 16, 32, 48, 64]
    readonly property var labels: ["Off", "Basic system information", "Basic usage statistics",
                                   "Detailed system information", "Detailed usage statistics"]

    Component.onCompleted: Backend.refreshPrvDiagnostics()

    FText {
        text: "Plasma can share anonymous information about your system and how you use it to help KDE improve the software. Nothing is sent unless you choose a level here."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.bottomMargin: 8
    }

    SettingsCard {
        icon: "fl:data_usage_20_regular"
        title: "Diagnostic data"
        description: "Choose how much information Plasma shares with KDE"
        FluentCombo {
            minWidth: 220
            model: page.labels
            currentIndex: Math.max(0, page.levels.indexOf(Backend.prvFeedbackLevel))
            onActivated: (i) => Backend.setPrvFeedbackLevel(page.levels[i])
        }
    }
}
