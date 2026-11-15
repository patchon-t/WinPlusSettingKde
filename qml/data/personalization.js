.pragma library
.import "helpers.js" as H

// Personalization section. Owned by the Personalization agent.
var P = "pages/personalization/"

var entry = H.custom("Personalization", "fl:paint_brush_20_color", P + "PersonalizationPage.qml", [
    { icon: "fl:image_20_regular", title: "Background", desc: "Background image, color, slideshow", page: P + "BackgroundPage.qml" },
    { icon: "fl:color_20_regular", title: "Colors", desc: "Accent color, transparency effects, color theme", page: P + "ColorsPage.qml" },
    { icon: "fl:paint_brush_20_regular", title: "Themes", desc: "Install, create, manage", page: P + "ThemesPage.qml", items: [
        { icon: "fl:board_20_regular", title: "Plasma style", desc: "Panel and widget appearance", page: P + "PlasmaStylePage.qml" },
        { icon: "fl:window_20_regular", title: "Window decorations", desc: "Title bar buttons and borders", page: P + "WindowDecorationsPage.qml" },
        { icon: "fl:icons_20_regular", title: "Icons", desc: "Icon theme", page: P + "IconsPage.qml" },
        { icon: "fl:cursor_20_regular", title: "Cursors", desc: "Pointer theme and size", page: P + "CursorsPage.qml" },
        { icon: "fl:sparkle_20_regular", title: "Splash screen", desc: "Screen shown while Plasma starts", page: P + "SplashPage.qml" },
        { icon: "fl:app_generic_20_regular", title: "Application style", desc: "Look of buttons and controls in apps", page: P + "AppStylePage.qml" }
    ] },
    { icon: "fl:lightbulb_20_regular", title: "Dynamic Lighting", desc: "Connected devices, effects, app settings", page: P + "DynamicLightingPage.qml" },
    { icon: "fl:lock_closed_20_regular", title: "Lock screen", desc: "Lock screen images, apps, animations", page: P + "LockScreenPage.qml" },
    { icon: "fl:keyboard_20_regular", title: "Text input", desc: "Input language switcher", page: P + "TextInputPage.qml" },
    { icon: "fl:apps_20_regular", title: "Start", desc: "Recent apps and items, folders", page: P + "StartPage.qml" },
    { icon: "fl:panel_bottom_20_regular", title: "Taskbar", desc: "Taskbar behaviors, system pins", page: P + "TaskbarPage.qml" },
    { icon: "fl:text_font_20_regular", title: "Fonts", desc: "Install, manage", page: P + "FontsPage.qml", items: [
        { icon: "fl:text_font_20_regular", title: "Font details", desc: "Preview, faces, uninstall", page: P + "FontDetailPage.qml", props: { family: "Noto Sans" } }
    ] }
])

var settings = [
    { title: "Lock screen timeout", kw: "screen timeout lock automatically idle autolock", icon: "fl:lock_closed_20_regular", page: P + "LockScreenPage.qml" },
    { title: "Lock screen picture", kw: "lock screen wallpaper slideshow spotlight", icon: "fl:lock_closed_20_regular", page: P + "LockScreenPage.qml" },
    { title: "Taskbar alignment", kw: "taskbar panel left center align", icon: "fl:panel_bottom_20_regular", page: P + "TaskbarPage.qml" },
    { title: "Automatically hide the taskbar", kw: "taskbar panel autohide hide", icon: "fl:panel_bottom_20_regular", page: P + "TaskbarPage.qml" },
    { title: "Combine taskbar buttons", kw: "taskbar group labels combine", icon: "fl:panel_bottom_20_regular", page: P + "TaskbarPage.qml" },
    { title: "Show badges on taskbar apps", kw: "taskbar badges notification count", icon: "fl:panel_bottom_20_regular", page: P + "TaskbarPage.qml" },
    { title: "System tray icons", kw: "tray hidden icons overflow", icon: "fl:panel_bottom_20_regular", page: P + "TaskbarPage.qml" },
    { title: "Start menu layout", kw: "start menu kickoff launcher grid list compact pinned", icon: "fl:apps_20_regular", page: P + "StartPage.qml" },
    { title: "Show recently added apps", kw: "start menu new apps recent", icon: "fl:apps_20_regular", page: P + "StartPage.qml" },
    { title: "Activity history", kw: "recent files recommended jump lists history", icon: "fl:apps_20_regular", page: P + "StartPage.qml" },
    { title: "Install fonts", kw: "fonts add install typeface uninstall", icon: "fl:text_font_20_regular", page: P + "FontsPage.qml" },
    { title: "Input language switcher", kw: "keyboard layout indicator osd language", icon: "fl:keyboard_20_regular", page: P + "TextInputPage.qml" },
    { title: "Global theme", kw: "look and feel theme apply breeze", icon: "fl:paint_brush_20_regular", page: P + "ThemesPage.qml" },
    { title: "Mouse pointer size", kw: "cursor size pointer theme", icon: "fl:cursor_20_regular", page: P + "CursorsPage.qml" },
    { title: "Title bar buttons", kw: "minimize maximize close buttons left right border size", icon: "fl:window_20_regular", page: P + "WindowDecorationsPage.qml" },
    { title: "Icon theme", kw: "icons theme papirus breeze", icon: "fl:icons_20_regular", page: P + "IconsPage.qml" },
    { title: "Switch between light and dark automatically", kw: "automatic dark light sunset schedule", icon: "fl:weather_sunny_20_regular", page: P + "ColorsPage.qml" },
    { title: "Desktop background", kw: "wallpaper picture image slideshow solid color fit fill stretch tile center spotlight", icon: "fl:image_20_regular", page: P + "BackgroundPage.qml" },
    { title: "Dark mode", kw: "dark light theme color mode", icon: "fl:color_20_regular", page: P + "ColorsPage.qml" },
    { title: "Accent color", kw: "accent highlight color", icon: "fl:color_20_regular", page: P + "ColorsPage.qml" },
    { title: "Transparency effects", kw: "blur transparent translucent", icon: "fl:color_20_regular", page: P + "ColorsPage.qml" }
]
