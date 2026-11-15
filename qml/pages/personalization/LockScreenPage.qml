import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Lock screen"]

    readonly property var ls: Backend.lockState
    readonly property var plugins: ["org.kde.image", "org.kde.slideshow", "org.kde.potd"]
    readonly property int modeIndex: Math.max(0, plugins.indexOf(ls.plugin))
    readonly property var timeoutValues: [0, 1, 2, 3, 5, 10, 15, 30]
    readonly property int timeoutNow: ls.autolock === false ? 0 : (ls.timeout || 5)

    function localPath(url) {
        return decodeURIComponent(String(url).replace(/^file:\/\//, ""))
    }

    Component.onCompleted: Backend.refreshLockScreen()

    PerPreview {
        Layout.bottomMargin: 12
        source: page.modeIndex === 0 && page.ls.image ? "file://" + page.ls.image : Backend.wallpaperUrl
    }

    ExpanderCard {
        icon: "fl:lock_closed_20_regular"
        title: "Personalize your lock screen"
        description: "A picture, slideshow, or the picture of the day"
        expanded: true
        headerControls: [
            FluentCombo {
                model: ["Picture", "Slideshow", "Windows spotlight"]
                currentIndex: page.modeIndex
                onActivated: (i) => Backend.setLockPlugin(page.plugins[i])
            }
        ]

        // ---- Picture
        ColumnLayout {
            visible: page.modeIndex === 0
            Layout.fillWidth: true
            Layout.leftMargin: 56
            Layout.rightMargin: 48
            Layout.topMargin: 16
            Layout.bottomMargin: 20
            spacing: 10
            FText { text: "Recent images" }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: Backend.wallpapers.slice(0, 5)
                    delegate: PerThumb {
                        required property var modelData
                        source: modelData.thumb
                        selected: modelData.path === page.ls.image
                        onClicked: Backend.setLockWallpaper(modelData.path)
                    }
                }
            }
        }
        ExpanderRow {
            visible: page.modeIndex === 0
            title: "Choose a photo"
            FluentButton { text: "Browse photos"; onClicked: photoDialog.open() }
        }

        // ---- Slideshow
        ExpanderRow {
            visible: page.modeIndex === 1
            title: "Choose albums for your slideshow"
            description: (page.ls.slidePaths && page.ls.slidePaths.length) ? page.ls.slidePaths.join(", ")
                                                                           : "Plasma's default wallpapers"
            FluentButton { text: "Browse"; onClicked: albumDialog.open() }
        }

        // ---- Spotlight
        ExpanderRow {
            visible: page.modeIndex === 2
            title: "Picture of the day"
            description: "Plasma downloads a new picture every day (needs the Picture of the Day wallpaper from kdeplasma-addons)"
        }
    }

    SettingsCard {
        icon: "fl:desktop_20_regular"
        title: "Show the lock screen background picture on the sign-in screen"
        description: "Not available yet"
        enabled: false
        FluentToggle { checked: false }
    }

    SectionHeader { text: "Related settings" }

    SettingsCard {
        icon: "fl:timer_20_regular"
        title: "Screen timeout"
        description: "Lock the screen automatically when you are away"
        FluentCombo {
            model: ["Never", "1 minute", "2 minutes", "3 minutes", "5 minutes", "10 minutes", "15 minutes", "30 minutes"]
            currentIndex: Math.max(0, page.timeoutValues.indexOf(page.timeoutNow))
            onActivated: (i) => Backend.setLockTimeout(page.timeoutValues[i])
        }
    }

    FileDialog {
        id: photoDialog
        title: "Choose a photo"
        nameFilters: ["Images (*.jpg *.jpeg *.png *.webp *.avif)"]
        onAccepted: Backend.setLockWallpaper(page.localPath(selectedFile))
    }
    FolderDialog {
        id: albumDialog
        title: "Choose an album for your slideshow"
        onAccepted: Backend.setLockSlideshowFolder(page.localPath(selectedFolder))
    }
}
