.pragma library
.import "helpers.js" as H

// Privacy & security section. Owned by the Privacy & security agent.
var P = "pages/privacy/"

// One entry per App-permissions page: all use the same reusable page with different props.
function perm(title, desc, icon, kind, o) {
    var props = { kind: kind, title: title, icon: icon }
    for (var k in o) props[k] = o[k]
    return { group: "App permissions", icon: icon, title: title, desc: desc, page: P + "PrvAppPermissionPage.qml", props: props }
}

var firewallItems = [
    { icon: "fl:fire_20_regular", title: "Firewall & network protection", page: P + "FirewallPage.qml" }
]

var entry = H.custom("Privacy & security", "fl:shield_20_color", P + "PrivacyPage.qml", [
    { group: "Security", icon: "fl:shield_20_regular", title: "Windows Security",
      desc: "Firewall and device security for your device", page: P + "WindowsSecurityPage.qml", items: firewallItems },
    { group: "Security", icon: "fl:lock_closed_20_regular", title: "Device encryption",
      desc: "Protect your data by encrypting your drives", page: P + "DeviceEncryptionPage.qml" },

    { group: "Windows permissions", icon: "fl:data_usage_20_regular", title: "Diagnostics & feedback",
      desc: "Diagnostic data and usage statistics", page: P + "DiagnosticsPage.qml" },
    { group: "Windows permissions", icon: "fl:history_20_regular", title: "Activity history",
      desc: "Store and clear your activity history on this device", page: P + "ActivityHistoryPage.qml" },
    { group: "Windows permissions", icon: "fl:search_info_20_regular", title: "Search permissions",
      desc: "Search history on this device", page: P + "SearchPermissionsPage.qml" },
    { group: "Windows permissions", icon: "fl:search_20_regular", title: "Searching Windows",
      desc: "Search indexing for faster results", page: P + "SearchingWindowsPage.qml" },

    perm("Location", "Which apps can access your location", "fl:location_20_regular", "location",
         { master: "Location services", masterDesc: "Not available on Linux. Control location per app below.",
           letTitle: "Let apps access your location", subject: "your location" }),
    perm("Camera", "Which apps can use your camera", "fl:camera_20_regular", "camera",
         { master: "Camera access", masterDesc: "Not available on Linux. Control the camera per app below.",
           letTitle: "Let apps access your camera", subject: "your camera" }),
    perm("Microphone", "Which apps can use your microphone", "fl:mic_20_regular", "microphone",
         { master: "Microphone access", masterDesc: "Not available on Linux. Control the microphone per app below.",
           letTitle: "Let apps access your microphone", subject: "your microphone" }),
    perm("Notifications", "Which apps can send notifications", "fl:alert_20_regular", "notifications",
         { letTitle: "Let apps send notifications", subject: "notifications" }),
    perm("Documents", "Which apps can access your documents", "fl:document_20_regular", "documents",
         { letTitle: "Let apps access your documents folder", subject: "your documents folder" }),
    perm("Downloads folder", "Which apps can access your downloads", "fl:arrow_download_20_regular", "downloads",
         { letTitle: "Let apps access your downloads folder", subject: "your downloads folder" }),
    perm("Music library", "Which apps can access your music", "fl:music_note_2_20_regular", "music",
         { letTitle: "Let apps access your music library", subject: "your music library" }),
    perm("Pictures", "Which apps can access your pictures", "fl:image_20_regular", "pictures",
         { letTitle: "Let apps access your pictures library", subject: "your pictures library" }),
    perm("Videos", "Which apps can access your videos", "fl:video_20_regular", "videos",
         { letTitle: "Let apps access your videos library", subject: "your videos library" }),
    perm("File system", "Which apps can access all your files", "fl:folder_20_regular", "files",
         { letTitle: "Let apps access your file system", subject: "your whole file system" }),
    perm("Screenshots and apps", "Which apps can take screenshots", "fl:screenshot_20_regular", "screenshot",
         { letTitle: "Let apps take screenshots of other windows", subject: "screenshots" })
])

var settings = [
    { title: "Windows Security", kw: "antivirus virus firewall protection security", icon: "fl:shield_20_regular", page: P + "WindowsSecurityPage.qml" },
    { title: "Firewall & network protection", kw: "ufw firewall rules port allow block deny network", icon: "fl:fire_20_regular", page: P + "FirewallPage.qml" },
    { title: "Device encryption", kw: "luks bitlocker encrypt drive disk lsblk", icon: "fl:lock_closed_20_regular", page: P + "DeviceEncryptionPage.qml" },
    { title: "Diagnostics & feedback", kw: "telemetry usage statistics feedback data collection plasma", icon: "fl:data_usage_20_regular", page: P + "DiagnosticsPage.qml" },
    { title: "Activity history", kw: "recent files history clear remember kactivitymanagerd timeline", icon: "fl:history_20_regular", page: P + "ActivityHistoryPage.qml" },
    { title: "Clear activity history", kw: "delete recent files forget history", icon: "fl:delete_20_regular", page: P + "ActivityHistoryPage.qml" },
    { title: "Search history on this device", kw: "krunner history search suggestions", icon: "fl:search_info_20_regular", page: P + "SearchPermissionsPage.qml" },
    { title: "Searching Windows", kw: "baloo index indexing find my files enhanced classic", icon: "fl:search_20_regular", page: P + "SearchingWindowsPage.qml" },
    { title: "Exclude folders from search", kw: "baloo exclude folder index", icon: "fl:folder_add_20_regular", page: P + "SearchingWindowsPage.qml" }
]
