import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Personalization", "Themes"]

    readonly property var themes: Backend.lookAndFeel.themes || []
    readonly property string currentName: {
        for (let i = 0; i < themes.length; ++i)
            if (themes[i].id === Backend.lookAndFeel.current)
                return themes[i].name
        return Backend.lookAndFeel.current || ""
    }
    readonly property var bgNames: ({ "org.kde.image": "Picture", "org.kde.color": "Solid color",
                                      "org.kde.slideshow": "Slideshow", "org.kde.potd": "Windows spotlight" })
    readonly property string cursorName: {
        const c = Backend.themeChoices.cursors
        if (!c)
            return ""
        for (let i = 0; i < c.items.length; ++i)
            if (c.items[i].id === c.current)
                return c.items[i].name
        return c.current
    }

    Component.onCompleted: {
        Backend.refreshLookAndFeel()
        Backend.refreshMisc()
        Backend.refreshPlasma()
        Backend.refreshThemeChoices("cursors")
    }

    // A small "current theme" tile (Background / Color / Sounds / Mouse cursor)
    component Tile: Rectangle {
        id: tile
        property string label
        property string value
        property string target
        implicitWidth: 120
        implicitHeight: 56
        radius: Theme.radius
        color: tma.pressed ? Theme.cardBgPressed : tma.containsMouse ? Theme.cardBgHover : Theme.controlBg
        Behavior on color { ColorAnimation { duration: Theme.durFaster } }
        border.color: Theme.cardBorder
        Column {
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            width: parent.width - 24
            spacing: 2
            FText { text: tile.label; font.weight: Font.DemiBold; width: parent.width; elide: Text.ElideRight }
            FText {
                text: tile.value
                font.pixelSize: Theme.fontCaption
                color: Theme.textSecondary
                width: parent.width
                elide: Text.ElideRight
            }
        }
        MouseArea {
            id: tma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Router.open(tile.target, {})
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: topRow.implicitHeight + 40
        radius: Theme.radiusLarge
        color: Theme.cardBg
        border.color: Theme.cardBorder
        RowLayout {
            id: topRow
            anchors.fill: parent
            anchors.margins: 20
            spacing: 24
            PerPreview { Layout.alignment: Qt.AlignTop }
            GridLayout {
                columns: 2
                columnSpacing: 8
                rowSpacing: 8
                Layout.alignment: Qt.AlignTop
                Tile {
                    label: "Background"
                    value: page.bgNames[Backend.plasmaState.bgPlugin] || "Picture"
                    target: "pages/personalization/BackgroundPage.qml"
                }
                Tile {
                    label: "Color"
                    value: Backend.dark ? "Dark" : "Light"
                    target: "pages/personalization/ColorsPage.qml"
                }
                Tile {
                    label: "Sounds"
                    value: Backend.miscState.sounds || ""
                    target: "pages/system/SoundPage.qml"
                }
                Tile {
                    label: "Mouse cursor"
                    value: page.cursorName
                    target: "pages/personalization/CursorsPage.qml"
                }
            }
            Item { Layout.fillWidth: true }
        }
    }

    SectionHeader { text: "Current theme: " + page.currentName; visible: page.currentName.length > 0 }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: thumbCol.implicitHeight + 40
        radius: Theme.radius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        ColumnLayout {
            id: thumbCol
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12
            FText {
                visible: page.themes.length === 0
                text: "No global themes found"
                color: Theme.textSecondary
            }
            Flow {
                id: thumbs
                Layout.fillWidth: true
                spacing: 12
                Repeater {
                    model: page.themes
                    delegate: PerThumb {
                        required property var modelData
                        thumbWidth: 148
                        thumbHeight: 90
                        source: modelData.preview
                        label: modelData.name
                        selected: modelData.id === Backend.lookAndFeel.current
                        onClicked: Backend.applyLookAndFeel(modelData.id)
                    }
                }
            }
        }
    }

    SettingsCard {
        icon: "fl:arrow_download_20_regular"
        title: "Browse themes"
        description: "Not available yet"
        enabled: false
        FluentButton { text: "Browse themes"; enabled: false }
    }

    SectionHeader { text: "Related settings" }

    SettingsCard {
        icon: "fl:board_20_regular"
        title: "Plasma style"
        description: "Panel and widget appearance"
        clickable: true
        onClicked: Router.open("pages/personalization/PlasmaStylePage.qml", {})
    }
    SettingsCard {
        icon: "fl:window_20_regular"
        title: "Window decorations"
        description: "Title bar buttons and borders"
        clickable: true
        onClicked: Router.open("pages/personalization/WindowDecorationsPage.qml", {})
    }
    SettingsCard {
        icon: "fl:icons_20_regular"
        title: "Icons"
        description: "Icon theme"
        clickable: true
        onClicked: Router.open("pages/personalization/IconsPage.qml", {})
    }
    SettingsCard {
        icon: "fl:cursor_20_regular"
        title: "Cursors"
        description: "Pointer theme and size"
        clickable: true
        onClicked: Router.open("pages/personalization/CursorsPage.qml", {})
    }
    SettingsCard {
        icon: "fl:sparkle_20_regular"
        title: "Splash screen"
        description: "Screen shown while Plasma starts"
        clickable: true
        onClicked: Router.open("pages/personalization/SplashPage.qml", {})
    }
    SettingsCard {
        icon: "fl:app_generic_20_regular"
        title: "Application style"
        description: "Look of buttons and controls in apps"
        clickable: true
        onClicked: Router.open("pages/personalization/AppStylePage.qml", {})
    }
    SettingsCard {
        icon: "fl:color_20_regular"
        title: "Contrast themes"
        description: "Color themes for low vision, light sensitivity"
        clickable: true
        onClicked: Router.open("pages/accessibility/ContrastThemesPage.qml", {})
    }
}
