.pragma library

// Navigation + list pages. Each entry opens one of:
//   page: a QML page in this folder   kcm: a Plasma KCM (kcmshell6)   cmd: a command
// Icons: "name|fallback|fallback" from the icon theme, or qml/icons/<name>.svg

function list(title, icon, items) {
    return { title: title, icon: icon, page: "KcmListPage.qml",
             props: { pageTitle: title, items: items } }
}

var system = [
    { icon: "video-display|monitor", title: "Display", desc: "Monitors, brightness, night light, display profile", page: "DisplayPage.qml" },
    { icon: "audio-volume-high|audio-speakers", title: "Sound", desc: "Volume levels, output, input, sound devices", kcm: "kcm_pulseaudio" },
    { icon: "preferences-desktop-notification-bell|notifications", title: "Notifications", desc: "Alerts from apps and system, do not disturb", kcm: "kcm_notifications" },
    { icon: "battery-full|battery", title: "Power & battery", desc: "Screen and sleep, battery usage, power mode", kcm: "kcm_powerdevilprofilesconfig" },
    { icon: "drive-harddisk", title: "Storage", desc: "Storage space, drives, disk usage", cmd: ["filelight", "/"] },
    { icon: "kdeconnect|smartphone", title: "Nearby sharing", desc: "KDE Connect, phones and other devices", kcm: "kcm_kdeconnect" },
    { icon: "virtual-desktops|window-duplicate", title: "Multitasking", desc: "Virtual desktops, task switching, screen edges", kcm: "kcm_kwin_virtualdesktops" },
    { icon: "preferences-desktop-keyboard-shortcut|configure-shortcuts", title: "Shortcuts", desc: "Global and app keyboard shortcuts", kcm: "kcm_keys" },
    { icon: "krdc|preferences-system-network-remote", title: "Remote Desktop", desc: "Remote desktop users, connection permissions", kcm: "kcm_krdpserver" },
    { icon: "system-log-out|preferences-system-login", title: "Session", desc: "Login, logout, restore previous session", kcm: "kcm_smserver" },
    { icon: "plasmadiscover|system-software-install", title: "Optional features", desc: "Extra functionality for your device", cmd: ["plasma-discover"] },
    { icon: "help-about|dialog-information", title: "About", desc: "Device specifications, OS and Plasma versions", kcm: "kcm_about-distro" }
]

var nav = [
    { title: "Home", icon: "user-home|go-home", page: "HomePage.qml", props: {} },
    list("System", "computer|preferences-system", system),
    list("Bluetooth & devices", "preferences-system-bluetooth|bluetooth", [
        { icon: "preferences-system-bluetooth|bluetooth", title: "Bluetooth", toggle: "bluetooth" },
        { icon: "preferences-system-bluetooth|bluetooth", title: "Devices", desc: "Paired and connected Bluetooth devices", kcm: "kcm_bluetooth" },
        { icon: "printer", title: "Printers & scanners", desc: "Preferences, troubleshoot", kcm: "kcm_printer_manager" },
        { icon: "input-mouse", title: "Mouse", desc: "Buttons, pointer speed, scrolling", kcm: "kcm_mouse" },
        { icon: "input-touchpad", title: "Touchpad", desc: "Taps, gestures, scrolling, zooming", kcm: "kcm_touchpad" },
        { icon: "input-keyboard", title: "Keyboard", desc: "Layouts, repeat rate, NumLock", kcm: "kcm_keyboard" },
        { icon: "input-tablet|tablet", title: "Drawing tablet", desc: "Pen buttons, screen mapping", kcm: "kcm_tablet" },
        { icon: "drive-removable-media|media-removable", title: "Removable storage", desc: "What happens when you plug in drives", kcm: "kcm_device_automounter" },
        { icon: "input-gamepad|applications-games", title: "Game controllers", desc: "Test and set up gamepads", kcm: "kcm_gamecontroller" }
    ]),
    list("Network & internet", "preferences-system-network|network-wired", [
        { icon: "network-wired|network-wireless", title: "Connections", desc: "Wi-Fi, Ethernet, VPN, mobile broadband", kcm: "kcm_networkmanagement" },
        { icon: "preferences-system-network-proxy|network-server", title: "Proxy", desc: "Proxy server for network connections", kcm: "kcm_proxy" },
        { icon: "security-high|firewall-config", title: "Firewall", desc: "Allow and block network traffic", kcm: "kcm_firewall" }
    ]),
    list("Personalization", "preferences-desktop-theme|preferences-desktop-color", [
        { icon: "preferences-desktop-color|color-management", title: "Colors", desc: "Accent color, transparency effects, color theme", page: "ColorsPage.qml" },
        { icon: "preferences-desktop-theme-global|preferences-desktop-theme", title: "Themes", desc: "Global theme, layout, splash screen", kcm: "kcm_lookandfeel" },
        { icon: "preferences-desktop-plasma-theme|preferences-desktop-theme", title: "Plasma style", desc: "Panel and widget appearance", kcm: "kcm_desktoptheme" },
        { icon: "preferences-desktop-theme-windowdecorations|window", title: "Window decorations", desc: "Title bar buttons and borders", kcm: "kcm_kwindecoration" },
        { icon: "preferences-desktop-icons", title: "Icons", desc: "Icon theme", kcm: "kcm_icons" },
        { icon: "preferences-desktop-cursors|input-mouse", title: "Cursors", desc: "Pointer theme and size", kcm: "kcm_cursortheme" },
        { icon: "preferences-desktop-font", title: "Fonts", desc: "Font families, sizes, anti-aliasing", kcm: "kcm_fonts" },
        { icon: "system-lock-screen|preferences-desktop-user-password", title: "Lock screen", desc: "Lock screen appearance and timeout", kcm: "kcm_screenlocker" },
        { icon: "preferences-desktop-effects", title: "Desktop effects", desc: "Animations, blur, window effects", kcm: "kcm_kwin_effects" }
    ]),
    list("Apps", "preferences-desktop-default-applications|applications-all", [
        { icon: "preferences-desktop-default-applications", title: "Default apps", desc: "Defaults for web, mail, files, and more", kcm: "kcm_componentchooser" },
        { icon: "preferences-desktop-filetype-association|application-x-zerosize", title: "File associations", desc: "Which app opens each file type", kcm: "kcm_filetypes" },
        { icon: "system-run|preferences-system-startup", title: "Startup", desc: "Apps that start automatically when you sign in", kcm: "kcm_autostart" },
        { icon: "plasmadiscover|system-software-install", title: "Installed apps", desc: "Install, update, and remove apps", cmd: ["plasma-discover", "--mode", "Installed"] },
        { icon: "flatpak-discover|application-x-executable", title: "Flatpak permissions", desc: "What Flatpak apps are allowed to access", kcm: "kcm_flatpak" }
    ]),
    list("Accounts", "preferences-system-users|system-users", [
        { icon: "user-identity|preferences-system-users", title: "Your info", desc: "Name, picture, password", kcm: "kcm_users" },
        { icon: "kwalletmanager|wallet-open", title: "Wallet", desc: "Saved passwords and secrets", kcm: "kcm_kwallet5" },
        { icon: "preferences-online-accounts|applications-internet", title: "Online accounts", desc: "Google, Nextcloud, and other accounts", kcm: "kcm_kaccounts" }
    ]),
    list("Time & language", "preferences-system-time|preferences-desktop-locale", [
        { icon: "preferences-system-time", title: "Date & time", desc: "Time zone, automatic clock", kcm: "kcm_clock" },
        { icon: "preferences-desktop-locale", title: "Region & language", desc: "Language, formats, measurement units", kcm: "kcm_regionandlang" },
        { icon: "input-keyboard", title: "Typing", desc: "Keyboard layouts and input methods", kcm: "kcm_keyboard" },
        { icon: "tools-check-spelling", title: "Spell check", desc: "Dictionaries and auto-correct", kcm: "kcm_spellchecking" }
    ]),
    list("Gaming", "applications-games|input-gamepad", [
        { icon: "input-gamepad|applications-games", title: "Game controllers", desc: "Test and set up gamepads", kcm: "kcm_gamecontroller" },
        { icon: "steam|applications-games", title: "Steam", desc: "Open Steam", cmd: ["steam"] }
    ]),
    list("Accessibility", "preferences-desktop-accessibility", [
        { icon: "preferences-desktop-accessibility", title: "Accessibility", desc: "Bell, modifier keys, keyboard filters, mouse navigation", kcm: "kcm_access" },
        { icon: "zoom-in", title: "Magnifier", desc: "Zoom effect settings", kcm: "kcm_kwin_effects" },
        { icon: "preferences-desktop-font", title: "Text size", desc: "Font sizes", kcm: "kcm_fonts" }
    ]),
    list("Privacy & security", "preferences-system-privacy|security-high", [
        { icon: "document-open-recent", title: "Activity history", desc: "Recent files and locations", kcm: "kcm_recentFiles" },
        { icon: "system-lock-screen", title: "Screen locking", desc: "Lock after idle and on wake", kcm: "kcm_screenlocker" },
        { icon: "security-high|firewall-config", title: "Firewall", desc: "Allow and block network traffic", kcm: "kcm_firewall" },
        { icon: "preferences-desktop-feedback|plasma", title: "Diagnostics & feedback", desc: "What usage data Plasma shares", kcm: "kcm_feedback" }
    ]),
    list("System updates", "system-software-update|update-none", [
        { icon: "system-software-update", title: "Check for updates", desc: "Open Discover's updates page", cmd: ["plasma-discover", "--mode", "Update"] },
        { icon: "plasmadiscover|system-software-install", title: "Discover", desc: "Software center", cmd: ["plasma-discover"] }
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
    { title: "Dark mode", kw: "dark light theme color mode", nav: "Personalization", icon: "preferences-desktop-color", page: "ColorsPage.qml" },
    { title: "Accent color", kw: "accent highlight color", nav: "Personalization", icon: "preferences-desktop-color", page: "ColorsPage.qml" },
    { title: "Transparency effects", kw: "blur transparent translucent", nav: "Personalization", icon: "preferences-desktop-color", page: "ColorsPage.qml" },
    { title: "Night light", kw: "night color blue light warm", nav: "System", icon: "video-display", page: "DisplayPage.qml" },
    { title: "Display resolution", kw: "resolution screen size", nav: "System", icon: "video-display", page: "DisplayPage.qml" },
    { title: "Scale", kw: "scale dpi zoom size text", nav: "System", icon: "video-display", page: "DisplayPage.qml" },
    { title: "Refresh rate", kw: "hz refresh fps", nav: "System", icon: "video-display", page: "DisplayPage.qml" },
    { title: "Brightness", kw: "brightness dim", nav: "System", icon: "video-display", page: "DisplayPage.qml" },
    { title: "Wallpaper", kw: "background wallpaper desktop", nav: "Home", icon: "user-home" }
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
