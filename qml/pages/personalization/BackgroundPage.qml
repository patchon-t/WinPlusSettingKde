import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Background"]

    readonly property var ps: Backend.plasmaState
    readonly property bool scripted: ps.available === true
    readonly property var modes: ["picture", "color", "slideshow", "spotlight"]
    readonly property string mode: {
        const i = ["org.kde.image", "org.kde.color", "org.kde.slideshow", "org.kde.potd"].indexOf(ps.bgPlugin)
        return modes[i < 0 ? 0 : i]
    }
    readonly property var fitValues: [2, 1, 0, 3, 6]
    readonly property var intervalValues: [60, 600, 1800, 3600, 21600, 86400]
    readonly property var solidColors: [
        "#ffb900", "#ff8c00", "#f7630c", "#ca5010", "#da3b01", "#ef6950", "#d13438", "#ff4343",
        "#e74856", "#e81123", "#ea005e", "#c30052", "#e3008c", "#bf0077", "#c239b3", "#9a0089",
        "#0078d7", "#0063b1", "#8e8cd8", "#6b69d6", "#8764b8", "#744da9", "#b146c2", "#881798",
        "#0099bc", "#2d7d9a", "#00b7c3", "#038387", "#00b294", "#018574", "#00cc6a", "#10893e",
        "#7a7574", "#5d5a58", "#68768a", "#515c6b", "#567c73", "#486860", "#498205", "#107c10",
        "#767676", "#4c4a48", "#69797e", "#4a5459", "#647c64", "#525e54", "#847545", "#000000"
    ]

    function localPath(url) {
        return decodeURIComponent(String(url).replace(/^file:\/\//, ""))
    }

    Component.onCompleted: Backend.refreshPlasma()

    PerPreview {
        Layout.bottomMargin: 12
        backdrop: page.mode === "color" ? page.ps.color : "transparent"
        source: page.mode === "color" ? "" : Backend.wallpaperUrl
    }

    FText {
        visible: page.ps.loaded === true && !page.scripted
        text: "Couldn't reach Plasma Shell. Only picture changes are available."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.bottomMargin: 4
    }

    ExpanderCard {
        icon: "fl:image_20_regular"
        title: "Personalize your background"
        description: "A picture, solid color, or slideshow for your desktop"
        expanded: true
        headerControls: [
            FluentCombo {
                enabled: page.scripted
                model: ["Picture", "Solid color", "Slideshow", "Windows spotlight"]
                currentIndex: page.modes.indexOf(page.mode)
                onActivated: (i) => Backend.setBackgroundMode(page.modes[i])
            }
        ]

        // ---- Picture
        ColumnLayout {
            visible: page.mode === "picture"
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
                        selected: modelData.path === Backend.wallpaper
                        onClicked: Backend.setWallpaper(modelData.path)
                    }
                }
            }
            FText {
                visible: Backend.wallpapers.length === 0
                text: "No pictures found in /usr/share/wallpapers"
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
            }
        }
        ExpanderRow {
            visible: page.mode === "picture"
            title: "Choose a photo"
            FluentButton { text: "Browse photos"; onClicked: photoDialog.open() }
        }

        // ---- Solid color
        ColumnLayout {
            visible: page.mode === "color"
            Layout.fillWidth: true
            Layout.leftMargin: 56
            Layout.rightMargin: 48
            Layout.topMargin: 16
            Layout.bottomMargin: 20
            spacing: 8
            FText { text: "Choose your background color" }
            GridLayout {
                columns: 8
                columnSpacing: 4
                rowSpacing: 4
                Repeater {
                    model: page.solidColors
                    delegate: PerSwatch {
                        required property var modelData
                        swatchColor: modelData
                        selectedColor: page.ps.color || ""
                        onPicked: (c) => Backend.setBackgroundColor(c)
                    }
                }
            }
        }
        ExpanderRow {
            visible: page.mode === "color"
            title: "Custom color"
            FluentButton { text: "View colors"; onClicked: solidDialog.open() }
        }

        // ---- Slideshow
        ExpanderRow {
            visible: page.mode === "slideshow"
            title: "Choose an album for your slideshow"
            description: (page.ps.slidePaths && page.ps.slidePaths.length) ? page.ps.slidePaths.join(", ")
                                                                           : "Plasma's default wallpapers"
            FluentButton { text: "Browse"; onClicked: albumDialog.open() }
        }
        ExpanderRow {
            visible: page.mode === "slideshow"
            title: "Change picture every"
            FluentCombo {
                model: ["1 minute", "10 minutes", "30 minutes", "1 hour", "6 hours", "1 day"]
                currentIndex: page.intervalValues.indexOf(page.ps.interval)
                onActivated: (i) => Backend.setSlideshowInterval(page.intervalValues[i])
            }
        }
        ExpanderRow {
            visible: page.mode === "slideshow"
            title: "Shuffle the picture order"
            FluentToggle {
                checked: page.ps.shuffle === true
                onToggled: (c) => Backend.setSlideshowShuffle(c)
            }
        }

        // ---- Windows spotlight
        ExpanderRow {
            visible: page.mode === "spotlight"
            title: "Picture of the day"
            description: "Plasma downloads a new picture every day (needs the Picture of the Day wallpaper from kdeplasma-addons)"
        }
    }

    SettingsCard {
        visible: page.mode === "picture" || page.mode === "slideshow" || page.mode === "spotlight"
        icon: "fl:resize_20_regular"
        title: "Choose a fit for your desktop image"
        FluentCombo {
            enabled: page.scripted
            model: ["Fill", "Fit", "Stretch", "Tile", "Center"]
            currentIndex: Math.max(0, page.fitValues.indexOf(page.ps.fill))
            onActivated: (i) => Backend.setBackgroundFit(page.fitValues[i])
        }
    }

    FileDialog {
        id: photoDialog
        title: "Choose a photo"
        nameFilters: ["Images (*.jpg *.jpeg *.png *.webp *.avif)"]
        onAccepted: Backend.setWallpaper(page.localPath(selectedFile))
    }
    FolderDialog {
        id: albumDialog
        title: "Choose an album for your slideshow"
        onAccepted: Backend.setBackgroundSlideshowFolder(page.localPath(selectedFolder))
    }
    ColorDialog {
        id: solidDialog
        title: "Pick a background color"
        onAccepted: Backend.setBackgroundColor(selectedColor.toString())
    }
}
