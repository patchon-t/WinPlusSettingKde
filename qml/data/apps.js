.pragma library
.import "helpers.js" as H

// Apps section. Owned by the Apps agent.
var P = "pages/apps/"

var entry = H.list("Apps", "fl:apps_20_color", [
    { icon: "fl:apps_list_detail_20_regular", title: "Installed apps", desc: "Uninstall and manage the apps on this device",
      page: P + "InstalledAppsPage.qml",
      items: [
          { icon: "fl:settings_20_regular", title: "Advanced options", page: P + "AppAdvancedPage.qml", props: { appId: "org.example.App.desktop" } }
      ] },
    { icon: "fl:apps_list_20_regular", title: "Default apps", desc: "Defaults for file types, link types and terminal",
      page: P + "DefaultAppsPage.qml",
      items: [
          { icon: "fl:app_generic_20_regular", title: "Defaults for an app", page: P + "DefaultAppPage.qml", props: { appId: "org.example.App.desktop" } },
          { icon: "fl:document_multiple_20_regular", title: "Choose defaults by file type", page: P + "DefaultTypesPage.qml", props: { kind: "file" } },
          { icon: "fl:link_multiple_20_regular", title: "Choose defaults by link type", page: P + "DefaultTypesPage.qml", props: { kind: "link" } }
      ] },
    { icon: "fl:rocket_20_regular", title: "Startup", desc: "Apps that start automatically when you sign in",
      page: P + "StartupPage.qml" }
])

var settings = [
    { title: "Uninstall an app", kw: "remove delete installed apps programs flatpak package", icon: "fl:apps_list_detail_20_regular", page: P + "InstalledAppsPage.qml" },
    { title: "App permissions (Flatpak)", kw: "advanced options network sound microphone files folders sandbox override", icon: "fl:settings_20_regular", page: P + "AppAdvancedPage.qml", props: { appId: "" } },
    { title: "Default web browser", kw: "browser http https link default apps", icon: "fl:globe_20_regular", page: P + "DefaultAppsPage.qml" },
    { title: "Default email app", kw: "mail mailto default apps", icon: "fl:mail_20_regular", page: P + "DefaultAppsPage.qml" },
    { title: "Default terminal app", kw: "terminal konsole console shell emulator", icon: "fl:window_console_20_regular", page: P + "DefaultAppsPage.qml" },
    { title: "Set a default for a file type or link type", kw: "file association mime extension open with .pdf", icon: "fl:document_20_regular", page: P + "DefaultAppsPage.qml" },
    { title: "Choose defaults by file type", kw: "file associations mime types", icon: "fl:document_multiple_20_regular", page: P + "DefaultTypesPage.qml", props: { kind: "file" } },
    { title: "Choose defaults by link type", kw: "protocol url scheme http mailto", icon: "fl:link_multiple_20_regular", page: P + "DefaultTypesPage.qml", props: { kind: "link" } },
    { title: "Startup apps", kw: "autostart login sign-in run at startup boot", icon: "fl:rocket_20_regular", page: P + "StartupPage.qml" }
]
