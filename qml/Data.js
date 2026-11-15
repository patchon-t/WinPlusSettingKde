.pragma library
.import "data/home.js" as Home
.import "data/system.js" as System
.import "data/bluetooth.js" as Bluetooth
.import "data/network.js" as Network
.import "data/personalization.js" as Personalization
.import "data/apps.js" as Apps
.import "data/accounts.js" as Accounts
.import "data/time_language.js" as TimeLanguage
.import "data/gaming.js" as Gaming
.import "data/accessibility.js" as Accessibility
.import "data/privacy.js" as Privacy
.import "data/updates.js" as Updates

// Merges the per-section files in data/. Each section file exports:
//   entry     its nav entry (see data/helpers.js for the entry format)
//   settings  [{ title, kw, icon, page?, props? }] settings inside its pages, for search
// Don't add section content here: edit data/<section>.js instead.

var sections = [Home, System, Bluetooth, Network, Personalization, Apps,
                Accounts, TimeLanguage, Gaming, Accessibility, Privacy, Updates]

var nav = sections.map(function (s) { return s.entry })

// Search index of settings inside pages; nav = owning section title
var pageSettings = []
sections.forEach(function (s) {
    (s.settings || []).forEach(function (p) {
        var c = {}
        for (var k in p) c[k] = p[k]
        c.nav = s.entry.title
        pageSettings.push(c)
    })
})

function navIndexOf(title) {
    for (var i = 0; i < nav.length; ++i)
        if (nav[i].title === title)
            return i
    return 0
}

function search(q) {
    q = q.toLowerCase().trim()
    var out = [], seen = {}
    function add(r) {
        var k = r.title + "|" + r.path
        if (!seen[k]) { seen[k] = true; out.push(r) }
    }
    function children(e) {
        return (e.props && e.props.items) || e.items || []
    }
    function walk(items, navI, path) {
        for (var j = 0; j < items.length; ++j) {
            var e = items[j]
            if ((e.title + " " + (e.desc || "")).toLowerCase().indexOf(q) >= 0)
                add({ title: e.title, icon: e.icon, path: path, nav: navI, entry: e })
            walk(children(e), navI, path + " > " + e.title)
        }
    }
    for (var i = 0; i < nav.length; ++i) {
        var n = nav[i]
        if (n.title.toLowerCase().indexOf(q) >= 0)
            add({ title: n.title, icon: n.icon, path: "", nav: i, entry: null })
        walk(children(n), i, n.title)
    }
    for (var s = 0; s < pageSettings.length; ++s) {
        var p = pageSettings[s]
        if ((p.title + " " + p.kw).toLowerCase().indexOf(q) >= 0)
            add({ title: p.title, icon: p.icon, path: p.nav, nav: navIndexOf(p.nav),
                  entry: p.page ? { page: p.page, props: p.props || {} } : null })
    }
    return out.slice(0, 12)
}
