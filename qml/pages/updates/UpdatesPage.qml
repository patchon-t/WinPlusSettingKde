import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 24H2 › Windows Update, on Linux: distro packages (PackageKit/apt) + Flatpak.
SettingsPage {
    id: page
    crumbs: ["System updates"]
    property string pageTitle      // set by Data.js (H.custom)
    property var items: []         // sub pages, used by search

    readonly property string st: Backend.updatesState
    readonly property bool busy: st === "checking" || st === "installing"

    Component.onCompleted: Backend.refreshUpdates()

    function heroTitle() {
        if (st === "checking") return "Checking for updates…"
        if (st === "installing") return Backend.updatesMessage
        if (st === "available") return "Updates available"
        if (st === "restart") return "Restart required"
        if (st === "uptodate") return "You're up to date"
        if (st === "error") return "There were problems installing some updates"
        return "Check for updates"
    }
    function heroIcon() {
        if (st === "uptodate") return "fl:checkmark_circle_24_filled@0f7b0f"
        if (st === "error") return "fl:error_circle_24_regular@c42b1c"
        return "fl:arrow_sync_circle_24_regular@" + Theme.accentBase.toString().substring(1)
    }

    // ---------------------------------------------------------------- hero
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 16
        spacing: 16

        Item {
            Layout.preferredWidth: 72
            Layout.preferredHeight: 72
            Icon {
                anchors.centerIn: parent
                name: page.heroIcon()
                size: 64
                RotationAnimator on rotation {
                    running: page.busy
                    loops: Animation.Infinite
                    from: 0; to: 360; duration: 1600
                    onRunningChanged: if (!running) parent.rotation = 0
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            FText {
                text: page.heroTitle()
                font.pixelSize: Theme.fontSubtitle
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            FText {
                text: page.st === "available" || page.st === "restart" || page.st === "error"
                      ? Backend.updatesMessage
                      : (Backend.updatesLastChecked.length ? "Last checked: " + Backend.updatesLastChecked : "")
                visible: text.length > 0
                color: Theme.textSecondary
                font.pixelSize: Theme.fontCaption
            }
            ProgressBar {
                visible: page.busy
                indeterminate: true
                Layout.preferredWidth: 260
                Layout.topMargin: 6
            }
        }
        FluentButton {
            accent: true
            enabled: !page.busy
            text: page.st === "available" ? "Download & install all"
                  : page.st === "restart" ? "Restart now" : "Check for updates"
            onClicked: page.st === "available" ? Backend.installUpdates()
                       : page.st === "restart" ? Backend.restartForUpdates()
                       : Backend.checkForUpdates()
        }
    }

    // ---------------------------------------------------------------- update list
    Repeater {
        model: Backend.updatesList
        delegate: SettingsCard {
            required property var modelData
            icon: modelData.source === "Flatpak" ? "fl:box_20_regular" : "fl:arrow_download_20_regular"
            title: modelData.name
            description: (modelData.version ? "Version " + modelData.version + " · " : "") + modelData.source
            FText {
                text: page.st === "installing" ? "Installing" : "Pending install"
                color: Theme.textSecondary
                font.pixelSize: Theme.fontCaption
            }
        }
    }

    // ---------------------------------------------------------------- more options
    SectionHeader { text: "More options" }
    SettingsCard {
        icon: "fl:pause_20_regular"
        title: "Pause updates"
        description: Backend.updatesPausedUntil.length
                     ? "Paused until " + Backend.updatesPausedUntil + ". This app won't check for updates until then."
                     : "Stop this app from checking for updates for a while"
        FluentButton {
            visible: Backend.updatesPausedUntil.length > 0
            text: "Resume updates"
            onClicked: Backend.pauseUpdates(0)
        }
        FluentCombo {
            visible: Backend.updatesPausedUntil.length === 0
            autoSelect: true
            minWidth: 170
            model: ["Pause for 1 week", "Pause for 2 weeks", "Pause for 3 weeks",
                    "Pause for 4 weeks", "Pause for 5 weeks"]
            currentIndex: 0
            onActivated: (i) => Backend.pauseUpdates(i + 1)
        }
    }
    SettingsCard {
        icon: "fl:history_20_regular"
        title: "Update history"
        clickable: true
        onClicked: Router.open("pages/updates/UpdateHistoryPage.qml", {})
    }
    SettingsCard {
        icon: "fl:options_20_regular"
        title: "Advanced options"
        description: "Optional updates (firmware), automatic updates, update on restart"
        clickable: true
        onClicked: Router.open("pages/updates/UpdateAdvancedPage.qml", {})
    }
}
