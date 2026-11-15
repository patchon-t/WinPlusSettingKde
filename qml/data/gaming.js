.pragma library
.import "helpers.js" as H

// Gaming section. Owned by the Gaming agent.
var P = "pages/gaming/"

var entry = H.list("Gaming", "fl:xbox_controller_20_filled@737373", [
    { icon: "fl:xbox_controller_20_regular", title: "Game controllers", desc: "Test and set up gamepads", kcm: "kcm_gamecontroller" },
    { icon: "fl:games_20_regular", title: "Steam", desc: "Open Steam", cmd: ["steam"] }
])

var settings = []
