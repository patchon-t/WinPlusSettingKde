.pragma library
.import "helpers.js" as H

// Personalization section. Owned by the Personalization agent.
var P = "pages/personalization/"

var entry = H.custom("Personalization", "fl:paint_brush_20_color", P + "PersonalizationPage.qml", [
    { icon: "fl:image_20_regular", title: "Background", desc: "Background image, color, slideshow", page: P + "BackgroundPage.qml" },
    { icon: "fl:color_20_regular", title: "Colors", desc: "Accent color, transparency effects, color theme", page: P + "ColorsPage.qml" }
])

var settings = [
    { title: "Desktop background", kw: "wallpaper picture image slideshow solid color fit fill stretch tile center spotlight", icon: "fl:image_20_regular", page: P + "BackgroundPage.qml" },
    { title: "Dark mode", kw: "dark light theme color mode", icon: "fl:color_20_regular", page: P + "ColorsPage.qml" },
    { title: "Accent color", kw: "accent highlight color", icon: "fl:color_20_regular", page: P + "ColorsPage.qml" },
    { title: "Transparency effects", kw: "blur transparent translucent", icon: "fl:color_20_regular", page: P + "ColorsPage.qml" }
]
