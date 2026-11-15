.pragma library
.import "helpers.js" as H

// Time & language section. Owned by the Time & language agent.
var P = "pages/time_language/"

var entry = H.list("Time & language", "fl:globe_20_color", [
    { icon: "fl:clock_20_regular", title: "Date & time", desc: "Time zone, automatic clock", page: P + "DateTimePage.qml" },
    { icon: "fl:local_language_20_regular", title: "Region & language", desc: "Language, formats, measurement units", kcm: "kcm_regionandlang" },
    { icon: "fl:keyboard_20_regular", title: "Typing", desc: "Keyboard layouts and input methods", kcm: "kcm_keyboard" },
    { icon: "fl:text_grammar_wand_20_regular", title: "Spell check", desc: "Dictionaries and auto-correct", kcm: "kcm_spellchecking" }
])

var settings = [
    { title: "Time zone", kw: "time zone timezone clock", icon: "fl:earth_20_regular", page: P + "DateTimePage.qml" }
]
