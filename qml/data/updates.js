.pragma library
.import "helpers.js" as H

// System updates section. Owned by the System updates agent.
var P = "pages/updates/"

var entry = H.list("System updates", "fl:arrow_sync_20_color", [
    { icon: "fl:arrow_sync_20_regular", title: "Check for updates", desc: "Open Discover's updates page", cmd: ["plasma-discover", "--mode", "Update"] },
    { icon: "fl:store_microsoft_20_regular", title: "Discover", desc: "Software center", cmd: ["plasma-discover"] }
])

var settings = []
