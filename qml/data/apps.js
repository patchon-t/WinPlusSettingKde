.pragma library
.import "helpers.js" as H

// Apps section. Owned by the Apps agent.
var P = "pages/apps/"

var entry = H.list("Apps", "fl:apps_20_color", [
    { icon: "fl:apps_list_20_regular", title: "Default apps", desc: "Defaults for web, mail, files, and more", kcm: "kcm_componentchooser" },
    { icon: "fl:document_20_regular", title: "File associations", desc: "Which app opens each file type", kcm: "kcm_filetypes" },
    { icon: "fl:apps_20_regular", title: "Startup", desc: "Apps that start automatically when you sign in", kcm: "kcm_autostart" },
    { icon: "fl:store_microsoft_20_regular", title: "Installed apps", desc: "Install, update, and remove apps", cmd: ["plasma-discover", "--mode", "Installed"] },
    { icon: "fl:shield_20_regular", title: "Flatpak permissions", desc: "What Flatpak apps are allowed to access", kcm: "kcm_flatpak" }
])

var settings = []
