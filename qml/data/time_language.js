.pragma library
.import "helpers.js" as H

// Time & language section. Owned by the Time & language agent.
var P = "pages/time_language/"

var entry = H.custom("Time & language", "fl:globe_20_color", P + "TimeLanguagePage.qml", [
    { icon: "fl:clock_20_regular", title: "Date & time", desc: "Time zones, automatic clock, calendar", page: P + "DateTimePage.qml" },
    { icon: "fl:local_language_20_regular", title: "Language & region", desc: "Display language, preferred languages, regional format", page: P + "LanguageRegionPage.qml",
      items: [
        { title: "Change formats", page: P + "ChangeFormatsPage.qml" },
        { title: "Language options", page: P + "LanguageOptionsPage.qml", props: { code: "en_US", name: "English (United States)" } }
      ] },
    { icon: "fl:keyboard_20_regular", title: "Typing", desc: "Spell check, touch keyboard, advanced keyboard settings", page: P + "TypingPage.qml",
      items: [
        { title: "Advanced keyboard settings", page: P + "AdvancedKeyboardPage.qml" },
        { title: "Keyboards", page: P + "KeyboardLayoutsPage.qml" },
        { title: "Touch keyboard", page: P + "TouchKeyboardPage.qml" }
      ] }
])

var settings = [
    { title: "Time zone", kw: "time zone timezone clock utc", icon: "fl:earth_20_regular", page: P + "DateTimePage.qml" },
    { title: "Set time automatically", kw: "ntp clock sync internet time", icon: "fl:clock_20_regular", page: P + "DateTimePage.qml" },
    { title: "Set time zone automatically", kw: "location geotimezone", icon: "fl:earth_20_regular", page: P + "DateTimePage.qml" },
    { title: "Set the date and time manually", kw: "change date time clock", icon: "fl:calendar_clock_20_regular", page: P + "DateTimePage.qml" },
    { title: "Show time and date in the system tray", kw: "taskbar clock date", icon: "fl:clock_20_regular", page: P + "DateTimePage.qml" },
    { title: "Show seconds in system tray clock", kw: "taskbar clock seconds", icon: "fl:clock_20_regular", page: P + "DateTimePage.qml" },
    { title: "Additional clocks", kw: "extra clocks time zones world", icon: "fl:globe_clock_20_regular", page: P + "DateTimePage.qml" },
    { title: "Windows display language", kw: "language display preferred translate", icon: "fl:local_language_20_regular", page: P + "LanguageRegionPage.qml" },
    { title: "Preferred languages", kw: "add language remove", icon: "fl:translate_20_regular", page: P + "LanguageRegionPage.qml" },
    { title: "Country or region", kw: "region paper measurement address", icon: "fl:earth_20_regular", page: P + "LanguageRegionPage.qml" },
    { title: "Regional format", kw: "locale date number currency format", icon: "fl:number_symbol_20_regular", page: P + "LanguageRegionPage.qml" },
    { title: "Change formats", kw: "first day of week short date long date time format", icon: "fl:calendar_ltr_20_regular", page: P + "ChangeFormatsPage.qml" },
    { title: "Administrative language settings", kw: "system locale localectl", icon: "fl:settings_20_regular", page: P + "LanguageRegionPage.qml" },
    { title: "Highlight misspelled words", kw: "spell check spelling sonnet", icon: "fl:text_grammar_wand_20_regular", page: P + "TypingPage.qml" },
    { title: "Autocorrect misspelled words", kw: "spell check autocorrect", icon: "fl:text_grammar_wand_20_regular", page: P + "TypingPage.qml" },
    { title: "Touch keyboard", kw: "virtual keyboard on-screen", icon: "fl:keyboard_dock_20_regular", page: P + "TouchKeyboardPage.qml" },
    { title: "Keyboards", kw: "keyboard layout add input method language", icon: "fl:keyboard_20_regular", page: P + "KeyboardLayoutsPage.qml" },
    { title: "Input language hot keys", kw: "switch keyboard layout shortcut alt shift", icon: "fl:keyboard_20_regular", page: P + "AdvancedKeyboardPage.qml" },
    { title: "Key repeat delay and rate", kw: "keyboard repeat delay rate numlock num lock", icon: "fl:keyboard_20_regular", page: P + "AdvancedKeyboardPage.qml" },
    { title: "Emoji panel", kw: "emoji emojier", icon: "fl:keyboard_20_regular", page: P + "TypingPage.qml" }
]
