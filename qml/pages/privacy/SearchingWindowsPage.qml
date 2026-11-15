import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import WinSettings
import "../.."

// Baloo file indexer settings (baloofilerc)
SettingsPage {
    id: page
    crumbs: ["Privacy & security", "Searching Windows"]

    Component.onCompleted: Backend.refreshPrvSearch()

    SectionHeader { text: "Find my files"; Layout.topMargin: 0 }

    SettingsCard {
        icon: "fl:search_20_regular"
        title: "Index my files"
        description: "Build a search index so file searches are fast"
        FluentToggle {
            checked: Backend.prvBalooEnabled
            onToggled: (v) => Backend.setPrvBalooEnabled(v)
        }
    }

    SettingsCard {
        icon: "fl:document_20_regular"
        title: "Index file names only"
        description: "Don't index the contents of files (Classic). Turn off for Enhanced search."
        enabled: Backend.prvBalooEnabled
        FluentToggle {
            checked: Backend.prvBalooBasic
            onToggled: (v) => Backend.setPrvBalooBasic(v)
        }
    }

    SettingsCard {
        icon: "fl:folder_20_regular"
        title: "Include hidden folders"
        description: "Index folders whose names start with a dot"
        enabled: Backend.prvBalooEnabled
        FluentToggle {
            checked: Backend.prvBalooHidden
            onToggled: (v) => Backend.setPrvBalooHidden(v)
        }
    }

    SectionHeader { text: "Exclude folders from search" }

    SettingsCard {
        icon: "fl:folder_add_20_regular"
        title: "Add an excluded folder"
        description: "Files in these folders won't appear in search results"
        enabled: Backend.prvBalooEnabled
        FluentButton { text: "Add an excluded folder"; onClicked: folderDialog.open() }
    }

    Repeater {
        model: Backend.prvBalooExcluded
        delegate: SettingsCard {
            required property string modelData
            icon: "fl:folder_20_regular"
            title: modelData.replace(/\/$/, "").split("/").pop() || modelData
            description: modelData
            IconButton {
                icon: "fl:dismiss_20_regular"
                tooltip: "Remove"
                onClicked: Backend.removePrvExcludedFolder(modelData)
            }
        }
    }

    FText {
        visible: Backend.prvBalooExcluded.length === 0
        text: "No folders are excluded."
        color: Theme.textSecondary
        Layout.topMargin: 8
        Layout.alignment: Qt.AlignHCenter
    }

    FolderDialog {
        id: folderDialog
        title: "Choose a folder to exclude"
        onAccepted: Backend.addPrvExcludedFolder(selectedFolder.toString())
    }
}
