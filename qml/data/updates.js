.pragma library
.import "helpers.js" as H

// System updates section (the Win11 "Windows Update" page).
var P = "pages/updates/"

// Sub pages are passed as items so search and the smoke test find them.
var entry = H.custom("System updates", "fl:arrow_sync_20_color", P + "UpdatesPage.qml", [
    { icon: "fl:history_20_regular", title: "Update history", desc: "Packages, firmware and Flatpak updates you installed", page: P + "UpdateHistoryPage.qml" },
    { icon: "fl:options_20_regular", title: "Advanced options", desc: "Optional updates, automatic updates", page: P + "UpdateAdvancedPage.qml" }
])

var settings = [
    { title: "Check for updates", kw: "update upgrade check install packages discover", icon: "fl:arrow_sync_20_regular", page: P + "UpdatesPage.qml" },
    { title: "Pause updates", kw: "pause updates stop", icon: "fl:pause_20_regular", page: P + "UpdatesPage.qml" },
    { title: "Optional updates", kw: "firmware fwupd driver optional", icon: "fl:developer_board_20_regular", page: P + "UpdateAdvancedPage.qml" },
    { title: "Install updates automatically", kw: "automatic unattended updates", icon: "fl:arrow_sync_20_regular", page: P + "UpdateAdvancedPage.qml" }
]
