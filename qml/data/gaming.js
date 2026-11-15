.pragma library
.import "helpers.js" as H

// Gaming section (Win11 24H2: Game Bar, Captures, Game Mode).
var P = "pages/gaming/"

// Sub pages are passed as items so search and the smoke test find them;
// GamingPage lays out its own cards.
var entry = H.custom("Gaming", "fl:xbox_controller_20_filled@737373", P + "GamingPage.qml", [
    { icon: "fl:xbox_controller_20_regular", title: "Game Bar", desc: "Controller and keyboard shortcuts", page: P + "GameBarPage.qml" },
    { icon: "fl:video_clip_20_regular", title: "Captures", desc: "Save locations, recording preferences", page: P + "CapturesPage.qml" },
    { icon: "fl:top_speed_20_regular", title: "Game Mode", desc: "Optimize your PC for play", page: P + "GameModePage.qml" }
])

var settings = [
    { title: "Screenshots location", kw: "screenshot capture save folder spectacle", icon: "fl:image_20_regular", page: P + "CapturesPage.qml" },
    { title: "Recordings location", kw: "recording video clip capture save folder", icon: "fl:record_20_regular", page: P + "CapturesPage.qml" },
    { title: "Use a game controller as a mouse", kw: "gamepad controller mouse pointer joystick", icon: "fl:cursor_20_regular", page: P + "GamingPage.qml" },
    { title: "Game Mode", kw: "game mode performance gamemode", icon: "fl:top_speed_20_regular", page: P + "GameModePage.qml" }
]
