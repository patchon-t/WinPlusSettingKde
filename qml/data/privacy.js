.pragma library
.import "helpers.js" as H

// Privacy & security section. Owned by the Privacy & security agent.
var P = "pages/privacy/"

var entry = H.list("Privacy & security", "fl:shield_20_color", [
    { icon: "fl:history_20_regular", title: "Activity history", desc: "Recent files and locations", kcm: "kcm_recentFiles" },
    { icon: "fl:lock_closed_20_regular", title: "Screen locking", desc: "Lock after idle and on wake", kcm: "kcm_screenlocker" },
    { icon: "fl:shield_20_regular", title: "Firewall", desc: "Allow and block network traffic", kcm: "kcm_firewall" },
    { icon: "fl:data_usage_20_regular", title: "Diagnostics & feedback", desc: "What usage data Plasma shares", kcm: "kcm_feedback" }
])

var settings = []
