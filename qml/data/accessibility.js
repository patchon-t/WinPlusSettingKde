.pragma library
.import "helpers.js" as H

// Accessibility section. Owned by the Accessibility agent.
var P = "pages/accessibility/"

var entry = H.list("Accessibility", "fl:accessibility_20_filled@0f6cbd", [
    { icon: "fl:accessibility_20_regular", title: "Accessibility", desc: "Bell, modifier keys, keyboard filters, mouse navigation", kcm: "kcm_access" },
    { icon: "fl:zoom_in_20_regular", title: "Magnifier", desc: "Zoom effect settings", kcm: "kcm_kwin_effects" },
    { icon: "fl:text_font_20_regular", title: "Text size", desc: "Font sizes", kcm: "kcm_fonts" }
])

var settings = []
