.pragma library
.import "helpers.js" as H

// System section. Owned by the System agent.
var P = "pages/system/"

var entry = H.list("System", "fl:laptop_20_color", [
    { icon: "fl:desktop_20_regular", title: "Display", desc: "Monitors, brightness, night light, display profile", page: P + "DisplayPage.qml",
      items: [
        { icon: "fl:weather_moon_20_regular", title: "Night light", desc: "Use warmer colors to help block blue light", page: P + "NightLightPage.qml" },
        { icon: "fl:hdr_20_regular", title: "HDR", desc: "Brighter, more vivid picture in HDR content", page: P + "HdrPage.qml" },
        { icon: "fl:desktop_20_regular", title: "Advanced display", desc: "Display information, refresh rate", page: P + "AdvancedDisplayPage.qml" },
        { icon: "fl:developer_board_20_regular", title: "Graphics", desc: "Variable refresh rate, screen tearing", page: P + "GraphicsPage.qml" },
        { icon: "fl:resize_20_regular", title: "Custom scaling", desc: "Enter a custom scaling size", page: P + "CustomScalingPage.qml" }
      ] },
    { icon: "fl:speaker_2_20_regular", title: "Sound", desc: "Volume levels, output, input, sound devices", page: P + "SoundPage.qml" },
    { icon: "fl:battery_charge_20_regular", title: "Power & battery", desc: "Screen and sleep, battery usage, power mode", page: P + "PowerPage.qml" },
    { icon: "fl:info_20_regular", title: "About", desc: "Device specifications, rename PC, OS and Plasma versions", page: P + "AboutPage.qml" }
])

// Settings inside pages, for search. nav = section title (set by Data.js)
var settings = [
    { title: "Night light", kw: "night color blue light warm", icon: "fl:desktop_20_regular", page: P + "NightLightPage.qml" },
    { title: "Display resolution", kw: "resolution screen size", icon: "fl:desktop_20_regular", page: P + "DisplayPage.qml" },
    { title: "Scale", kw: "scale dpi zoom size text", icon: "fl:desktop_20_regular", page: P + "DisplayPage.qml" },
    { title: "Refresh rate", kw: "hz refresh fps", icon: "fl:desktop_20_regular", page: P + "AdvancedDisplayPage.qml" },
    { title: "Brightness", kw: "brightness dim", icon: "fl:desktop_20_regular", page: P + "DisplayPage.qml" },
    { title: "Volume", kw: "volume sound speaker output mute", icon: "fl:speaker_2_20_regular", page: P + "SoundPage.qml" },
    { title: "Microphone", kw: "mic microphone input recording", icon: "fl:mic_20_regular", page: P + "SoundPage.qml" },
    { title: "Power mode", kw: "power performance battery saver profile", icon: "fl:gauge_20_regular", page: P + "PowerPage.qml" },
    { title: "Screen and sleep", kw: "sleep screen timeout turn off", icon: "fl:desktop_20_regular", page: P + "PowerPage.qml" },
    { title: "Rename this PC", kw: "rename hostname computer name", icon: "fl:laptop_20_color", page: P + "AboutPage.qml" }
]
