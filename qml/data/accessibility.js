.pragma library
.import "helpers.js" as H

// Accessibility section. Owned by the Accessibility agent.
var P = "pages/accessibility/"

// `section` groups the cards on the top page (Vision / Hearing / Interaction).
var entry = H.custom("Accessibility", "fl:accessibility_20_filled@0f6cbd", P + "AccessibilityPage.qml", [
    { section: "Vision", icon: "fl:text_font_size_20_regular", title: "Text size", desc: "Text size in Windows and apps", page: P + "TextSizePage.qml" },
    { section: "Vision", icon: "fl:sparkle_20_regular", title: "Visual effects", desc: "Transparency, animations, notification timeout", page: P + "VisualEffectsPage.qml" },
    { section: "Vision", icon: "fl:cursor_20_regular", title: "Mouse pointer and touch", desc: "Mouse pointer style, size, touch indicator", page: P + "MousePointerPage.qml" },
    { section: "Vision", icon: "fl:zoom_in_20_regular", title: "Magnifier", desc: "Zoom in on parts of the screen, magnifier view and tracking", page: P + "MagnifierPage.qml" },
    { section: "Vision", icon: "fl:color_20_regular", title: "Color filters", desc: "Color filters for color blindness and light sensitivity", page: P + "ColorFiltersPage.qml" },
    { section: "Vision", icon: "fl:circle_half_fill_20_regular", title: "Contrast themes", desc: "Color themes for low vision, light sensitivity", page: P + "ContrastThemesPage.qml" },
    { section: "Vision", icon: "fl:person_voice_20_regular", title: "Narrator", desc: "Screen reader", page: P + "NarratorPage.qml" },
    { section: "Hearing", icon: "fl:speaker_2_20_regular", title: "Audio", desc: "Mono audio, flash my screen during audio notifications", page: P + "AudioPage.qml" },
    { section: "Interaction", icon: "fl:keyboard_20_regular", title: "Keyboard", desc: "Sticky keys, filter keys, toggle keys, on-screen keyboard", page: P + "KeyboardPage.qml" },
    { section: "Interaction", icon: "fl:cursor_hover_20_regular", title: "Mouse", desc: "Mouse keys, speed, acceleration", page: P + "MousePage.qml" }
])

var settings = [
    { title: "Text size", kw: "font size bigger larger scale text", icon: "fl:text_font_size_20_regular", page: P + "TextSizePage.qml" },
    { title: "Transparency effects", kw: "blur translucent acrylic", icon: "fl:transparency_square_20_regular", page: P + "VisualEffectsPage.qml" },
    { title: "Animation effects", kw: "animations motion reduce", icon: "fl:play_20_regular", page: P + "VisualEffectsPage.qml" },
    { title: "Dismiss notifications after this amount of time", kw: "notification timeout popup", icon: "fl:alert_20_regular", page: P + "VisualEffectsPage.qml" },
    { title: "Mouse pointer style", kw: "cursor theme white black", icon: "fl:cursor_20_regular", page: P + "MousePointerPage.qml" },
    { title: "Mouse pointer size", kw: "cursor size bigger", icon: "fl:cursor_20_regular", page: P + "MousePointerPage.qml" },
    { title: "Touch indicator", kw: "touch points finger", icon: "fl:tap_single_20_regular", page: P + "MousePointerPage.qml" },
    { title: "Shake cursor to find it", kw: "shake mouse pointer locate", icon: "fl:cursor_20_regular", page: P + "MousePointerPage.qml" },
    { title: "Magnifier", kw: "zoom screen magnify lens", icon: "fl:zoom_in_20_regular", page: P + "MagnifierPage.qml" },
    { title: "Invert colors", kw: "invert negative magnifier", icon: "fl:zoom_in_20_regular", page: P + "MagnifierPage.qml" },
    { title: "Color filters", kw: "grayscale colorblind deuteranopia protanopia tritanopia", icon: "fl:color_20_regular", page: P + "ColorFiltersPage.qml" },
    { title: "Contrast themes", kw: "high contrast aquatic desert dusk night sky", icon: "fl:circle_half_fill_20_regular", page: P + "ContrastThemesPage.qml" },
    { title: "Narrator", kw: "screen reader orca blind", icon: "fl:person_voice_20_regular", page: P + "NarratorPage.qml" },
    { title: "Flash my screen during audio notifications", kw: "visual bell flash sound", icon: "fl:speaker_2_20_regular", page: P + "AudioPage.qml" },
    { title: "Mono audio", kw: "mono stereo left right", icon: "fl:speaker_2_20_regular", page: P + "AudioPage.qml" },
    { title: "Sticky keys", kw: "modifier shift ctrl alt latch", icon: "fl:keyboard_20_regular", page: P + "StickyKeysPage.qml" },
    { title: "Filter keys", kw: "slow keys bounce keys repeat", icon: "fl:keyboard_20_regular", page: P + "FilterKeysPage.qml" },
    { title: "Toggle keys", kw: "caps lock num lock sound beep", icon: "fl:keyboard_123_20_regular", page: P + "KeyboardPage.qml" },
    { title: "On-screen keyboard", kw: "virtual keyboard touch", icon: "fl:keyboard_dock_20_regular", page: P + "KeyboardPage.qml" },
    { title: "Mouse keys", kw: "numpad move pointer keyboard", icon: "fl:cursor_hover_20_regular", page: P + "MousePage.qml" }
]
