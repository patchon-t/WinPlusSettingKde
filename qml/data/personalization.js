.pragma library
.import "helpers.js" as H

// Personalization section. Owned by the Personalization agent.
var P = "pages/personalization/"

var entry = H.list("Personalization", "fl:paint_brush_20_color", [
    { icon: "fl:color_20_regular", title: "Colors", desc: "Accent color, transparency effects, color theme", page: P + "ColorsPage.qml" },
    { icon: "fl:paint_brush_20_regular", title: "Themes", desc: "Global theme, layout, splash screen", kcm: "kcm_lookandfeel" },
    { icon: "fl:board_20_regular", title: "Plasma style", desc: "Panel and widget appearance", kcm: "kcm_desktoptheme" },
    { icon: "fl:window_20_regular", title: "Window decorations", desc: "Title bar buttons and borders", kcm: "kcm_kwindecoration" },
    { icon: "fl:icons_20_regular", title: "Icons", desc: "Icon theme", kcm: "kcm_icons" },
    { icon: "fl:cursor_20_regular", title: "Cursors", desc: "Pointer theme and size", kcm: "kcm_cursortheme" },
    { icon: "fl:text_font_20_regular", title: "Fonts", desc: "Font families, sizes, anti-aliasing", kcm: "kcm_fonts" },
    { icon: "fl:lock_closed_20_regular", title: "Lock screen", desc: "Lock screen appearance and timeout", kcm: "kcm_screenlocker" },
    { icon: "fl:sparkle_20_regular", title: "Desktop effects", desc: "Animations, blur, window effects", kcm: "kcm_kwin_effects" }
])

var settings = [
    { title: "Dark mode", kw: "dark light theme color mode", icon: "fl:color_20_regular", page: P + "ColorsPage.qml" },
    { title: "Accent color", kw: "accent highlight color", icon: "fl:color_20_regular", page: P + "ColorsPage.qml" },
    { title: "Transparency effects", kw: "blur transparent translucent", icon: "fl:color_20_regular", page: P + "ColorsPage.qml" }
]
