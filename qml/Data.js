.pragma library

// Navigation + list pages. Each entry opens one of:
//   page: a QML page in this folder   kcm: a Plasma KCM (kcmshell6)   cmd: a command
// Icons: "name|fallback|fallback" from the icon theme, or qml/icons/<name>.svg

// Top-level page with its own QML that also shows a list of `items`
function custom(title, icon, page, items) {
    return { title: title, icon: icon, page: page, props: { pageTitle: title, items: items } }
}

function list(title, icon, items) {
    return { title: title, icon: icon, page: "KcmListPage.qml",
             props: { pageTitle: title, items: items } }
}

var system = [
    { icon: "fl:desktop_20_regular", title: "Display", desc: "Monitors, brightness, night light, display profile", page: "DisplayPage.qml" },
    { icon: "fl:speaker_2_20_regular", title: "Sound", desc: "Volume levels, output, input, sound devices", page: "SoundPage.qml" },
    { icon: "fl:alert_20_regular", title: "Notifications", desc: "Alerts from apps and system, do not disturb", kcm: "kcm_notifications" },
    { icon: "fl:battery_charge_20_regular", title: "Power & battery", desc: "Screen and sleep, battery usage, power mode", page: "PowerPage.qml" },
    { icon: "fl:storage_20_regular", title: "Storage", desc: "Storage space, drives, disk usage", cmd: ["filelight", "/"] },
    { icon: "fl:phone_laptop_20_regular", title: "Nearby sharing", desc: "KDE Connect, phones and other devices", kcm: "kcm_kdeconnect" },
    { icon: "fl:window_multiple_20_regular", title: "Multitasking", desc: "Virtual desktops, task switching, screen edges", kcm: "kcm_kwin_virtualdesktops" },
    { icon: "fl:keyboard_20_regular", title: "Shortcuts", desc: "Global and app keyboard shortcuts", kcm: "kcm_keys" },
    { icon: "fl:remote_20_regular", title: "Remote Desktop", desc: "Remote desktop users, connection permissions", kcm: "kcm_krdpserver" },
    { icon: "fl:sign_out_20_regular", title: "Session", desc: "Login, logout, restore previous session", kcm: "kcm_smserver" },
    { icon: "fl:apps_add_in_20_regular", title: "Optional features", desc: "Extra functionality for your device", cmd: ["plasma-discover"] },
    { icon: "fl:info_20_regular", title: "About", desc: "Device specifications, rename PC, OS and Plasma versions", page: "AboutPage.qml" }
]

var nav = [
    { title: "Home", icon: "fl:home_20_color", page: "HomePage.qml", props: {} },
    list("System", "fl:laptop_20_color", system),
    custom("Bluetooth & devices", "fl:bluetooth_20_filled@0078d4", "BluetoothPage.qml", [
        { icon: "fl:print_20_regular", title: "Printers & scanners", desc: "Preferences, troubleshoot", kcm: "kcm_printer_manager" },
        { icon: "fl:cursor_20_regular", title: "Mouse", desc: "Buttons, pointer speed, scrolling", kcm: "kcm_mouse" },
        { icon: "fl:cursor_20_regular", title: "Touchpad", desc: "Taps, gestures, scrolling, zooming", kcm: "kcm_touchpad" },
        { icon: "fl:keyboard_20_regular", title: "Keyboard", desc: "Layouts, repeat rate, NumLock", kcm: "kcm_keyboard" },
        { icon: "fl:tablet_20_regular", title: "Drawing tablet", desc: "Pen buttons, screen mapping", kcm: "kcm_tablet" },
        { icon: "fl:usb_stick_20_regular", title: "Removable storage", desc: "What happens when you plug in drives", kcm: "kcm_device_automounter" },
        { icon: "fl:xbox_controller_20_regular", title: "Game controllers", desc: "Test and set up gamepads", kcm: "kcm_gamecontroller" }
    ]),
    custom("Network & internet", "fl:wifi_20_color", "NetworkPage.qml", [
        { icon: "fl:wifi_1_20_regular", title: "Advanced network settings", desc: "Ethernet, VPN, hotspot, IP and DNS", kcm: "kcm_networkmanagement" },
        { icon: "fl:globe_20_regular", title: "Proxy", desc: "Proxy server for network connections", kcm: "kcm_proxy" },
        { icon: "fl:shield_20_regular", title: "Firewall", desc: "Allow and block network traffic", kcm: "kcm_firewall" }
    ]),
    list("Personalization", "fl:paint_brush_20_color", [
        { icon: "fl:color_20_regular", title: "Colors", desc: "Accent color, transparency effects, color theme", page: "ColorsPage.qml" },
        { icon: "fl:paint_brush_20_regular", title: "Themes", desc: "Global theme, layout, splash screen", kcm: "kcm_lookandfeel" },
        { icon: "fl:board_20_regular", title: "Plasma style", desc: "Panel and widget appearance", kcm: "kcm_desktoptheme" },
        { icon: "fl:window_20_regular", title: "Window decorations", desc: "Title bar buttons and borders", kcm: "kcm_kwindecoration" },
        { icon: "fl:icons_20_regular", title: "Icons", desc: "Icon theme", kcm: "kcm_icons" },
        { icon: "fl:cursor_20_regular", title: "Cursors", desc: "Pointer theme and size", kcm: "kcm_cursortheme" },
        { icon: "fl:text_font_20_regular", title: "Fonts", desc: "Font families, sizes, anti-aliasing", kcm: "kcm_fonts" },
        { icon: "fl:lock_closed_20_regular", title: "Lock screen", desc: "Lock screen appearance and timeout", kcm: "kcm_screenlocker" },
        { icon: "fl:sparkle_20_regular", title: "Desktop effects", desc: "Animations, blur, window effects", kcm: "kcm_kwin_effects" }
    ]),
    list("Apps", "fl:apps_20_color", [
        { icon: "fl:apps_list_20_regular", title: "Default apps", desc: "Defaults for web, mail, files, and more", kcm: "kcm_componentchooser" },
        { icon: "fl:document_20_regular", title: "File associations", desc: "Which app opens each file type", kcm: "kcm_filetypes" },
        { icon: "fl:apps_20_regular", title: "Startup", desc: "Apps that start automatically when you sign in", kcm: "kcm_autostart" },
        { icon: "fl:store_microsoft_20_regular", title: "Installed apps", desc: "Install, update, and remove apps", cmd: ["plasma-discover", "--mode", "Installed"] },
        { icon: "fl:shield_20_regular", title: "Flatpak permissions", desc: "What Flatpak apps are allowed to access", kcm: "kcm_flatpak" }
    ]),
    list("Accounts", "fl:person_20_color", [
        { icon: "fl:person_20_regular", title: "Your info", desc: "Name, picture, password", kcm: "kcm_users" },
        { icon: "fl:wallet_20_regular", title: "Wallet", desc: "Saved passwords and secrets", kcm: "kcm_kwallet5" },
        { icon: "fl:people_20_regular", title: "Online accounts", desc: "Google, Nextcloud, and other accounts", kcm: "kcm_kaccounts" }
    ]),
    list("Time & language", "fl:globe_20_color", [
        { icon: "fl:clock_20_regular", title: "Date & time", desc: "Time zone, automatic clock", page: "DateTimePage.qml" },
        { icon: "fl:local_language_20_regular", title: "Region & language", desc: "Language, formats, measurement units", kcm: "kcm_regionandlang" },
        { icon: "fl:keyboard_20_regular", title: "Typing", desc: "Keyboard layouts and input methods", kcm: "kcm_keyboard" },
        { icon: "fl:text_grammar_wand_20_regular", title: "Spell check", desc: "Dictionaries and auto-correct", kcm: "kcm_spellchecking" }
    ]),
    list("Gaming", "fl:xbox_controller_20_filled@737373", [
        { icon: "fl:xbox_controller_20_regular", title: "Game controllers", desc: "Test and set up gamepads", kcm: "kcm_gamecontroller" },
        { icon: "fl:games_20_regular", title: "Steam", desc: "Open Steam", cmd: ["steam"] }
    ]),
    list("Accessibility", "fl:accessibility_20_filled@0f6cbd", [
        { icon: "fl:accessibility_20_regular", title: "Accessibility", desc: "Bell, modifier keys, keyboard filters, mouse navigation", kcm: "kcm_access" },
        { icon: "fl:zoom_in_20_regular", title: "Magnifier", desc: "Zoom effect settings", kcm: "kcm_kwin_effects" },
        { icon: "fl:text_font_20_regular", title: "Text size", desc: "Font sizes", kcm: "kcm_fonts" }
    ]),
    list("Privacy & security", "fl:shield_20_color", [
        { icon: "fl:history_20_regular", title: "Activity history", desc: "Recent files and locations", kcm: "kcm_recentFiles" },
        { icon: "fl:lock_closed_20_regular", title: "Screen locking", desc: "Lock after idle and on wake", kcm: "kcm_screenlocker" },
        { icon: "fl:shield_20_regular", title: "Firewall", desc: "Allow and block network traffic", kcm: "kcm_firewall" },
        { icon: "fl:data_usage_20_regular", title: "Diagnostics & feedback", desc: "What usage data Plasma shares", kcm: "kcm_feedback" }
    ]),
    list("System updates", "fl:arrow_sync_20_color", [
        { icon: "fl:arrow_sync_20_regular", title: "Check for updates", desc: "Open Discover's updates page", cmd: ["plasma-discover", "--mode", "Update"] },
        { icon: "fl:store_microsoft_20_regular", title: "Discover", desc: "Software center", cmd: ["plasma-discover"] }
    ])
]

function navIndexOf(title) {
    for (var i = 0; i < nav.length; ++i)
        if (nav[i].title === title)
            return i
    return 0
}

// Settings that live inside custom pages (searchable too)
var pageSettings = [
    { title: "Dark mode", kw: "dark light theme color mode", nav: "Personalization", icon: "fl:color_20_regular", page: "ColorsPage.qml" },
    { title: "Accent color", kw: "accent highlight color", nav: "Personalization", icon: "fl:color_20_regular", page: "ColorsPage.qml" },
    { title: "Transparency effects", kw: "blur transparent translucent", nav: "Personalization", icon: "fl:color_20_regular", page: "ColorsPage.qml" },
    { title: "Night light", kw: "night color blue light warm", nav: "System", icon: "fl:desktop_20_regular", page: "DisplayPage.qml" },
    { title: "Display resolution", kw: "resolution screen size", nav: "System", icon: "fl:desktop_20_regular", page: "DisplayPage.qml" },
    { title: "Scale", kw: "scale dpi zoom size text", nav: "System", icon: "fl:desktop_20_regular", page: "DisplayPage.qml" },
    { title: "Refresh rate", kw: "hz refresh fps", nav: "System", icon: "fl:desktop_20_regular", page: "DisplayPage.qml" },
    { title: "Brightness", kw: "brightness dim", nav: "System", icon: "fl:desktop_20_regular", page: "DisplayPage.qml" },
    { title: "Wallpaper", kw: "background wallpaper desktop", nav: "Home", icon: "fl:home_20_regular" },
    { title: "Volume", kw: "volume sound speaker output mute", nav: "System", icon: "fl:speaker_2_20_regular", page: "SoundPage.qml" },
    { title: "Microphone", kw: "mic microphone input recording", nav: "System", icon: "fl:mic_20_regular", page: "SoundPage.qml" },
    { title: "Wi-Fi", kw: "wifi wireless network internet", nav: "Network & internet", icon: "fl:wifi_1_20_regular" },
    { title: "Power mode", kw: "power performance battery saver profile", nav: "System", icon: "fl:gauge_20_regular", page: "PowerPage.qml" },
    { title: "Screen and sleep", kw: "sleep screen timeout turn off", nav: "System", icon: "fl:desktop_20_regular", page: "PowerPage.qml" },
    { title: "Time zone", kw: "time zone timezone clock", nav: "Time & language", icon: "fl:earth_20_regular", page: "DateTimePage.qml" },
    { title: "Rename this PC", kw: "rename hostname computer name", nav: "System", icon: "fl:laptop_20_color", page: "AboutPage.qml" }
]

function search(q) {
    q = q.toLowerCase().trim()
    var out = [], seen = {}
    function add(r) {
        var k = r.title + "|" + r.path
        if (!seen[k]) { seen[k] = true; out.push(r) }
    }
    for (var i = 0; i < nav.length; ++i) {
        var n = nav[i]
        if (n.title.toLowerCase().indexOf(q) >= 0)
            add({ title: n.title, icon: n.icon, path: "", nav: i, entry: null })
        var items = (n.props && n.props.items) || []
        for (var j = 0; j < items.length; ++j) {
            var e = items[j]
            if ((e.title + " " + (e.desc || "")).toLowerCase().indexOf(q) >= 0)
                add({ title: e.title, icon: e.icon, path: n.title, nav: i, entry: e })
        }
    }
    for (var s = 0; s < pageSettings.length; ++s) {
        var p = pageSettings[s]
        if ((p.title + " " + p.kw).toLowerCase().indexOf(q) >= 0)
            add({ title: p.title, icon: p.icon, path: p.nav, nav: navIndexOf(p.nav),
                  entry: p.page ? { page: p.page } : null })
    }
    return out.slice(0, 12)
}
