import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import WinSettings
import "../.."

// Win11 › Gaming › Captures. Screenshots and recordings are made by Spectacle;
// these are its save folders (spectaclerc [ImageSave]/[VideoSave]).
SettingsPage {
    id: page
    crumbs: ["Gaming", "Captures"]
    property string pickKind: "image"

    Component.onCompleted: Backend.refreshGaming()

    function localPath(url) {
        var s = url.toString()
        return s.startsWith("file://") ? decodeURIComponent(s.substring(7)) : s
    }
    function pick(kind) {
        pickKind = kind
        folderDialog.title = kind === "image" ? "Choose where screenshots are saved"
                                              : "Choose where recordings are saved"
        folderDialog.currentFolder = "file://" + (kind === "image" ? Backend.gamingScreenshotDir
                                                                   : Backend.gamingRecordingDir)
        folderDialog.open()
    }

    SectionHeader { text: "Captures location" }
    SettingsCard {
        icon: "fl:image_20_regular"
        title: "Screenshots"
        description: Backend.gamingScreenshotDir
        RowLayout {
            spacing: 8
            FluentButton { text: "Open folder"; onClicked: Backend.openGamingCaptureDir("image") }
            FluentButton { text: "Change"; onClicked: page.pick("image") }
        }
    }
    SettingsCard {
        icon: "fl:record_20_regular"
        title: "Recordings"
        description: Backend.gamingRecordingDir
        RowLayout {
            spacing: 8
            FluentButton { text: "Open folder"; onClicked: Backend.openGamingCaptureDir("video") }
            FluentButton { text: "Change"; onClicked: page.pick("video") }
        }
    }

    FolderDialog {
        id: folderDialog
        onAccepted: Backend.setGamingCaptureDir(page.pickKind, page.localPath(selectedFolder))
    }
}
