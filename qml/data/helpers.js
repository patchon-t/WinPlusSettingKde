.pragma library

// Shared builders for the per-section nav files in this folder.
//
// An entry opens exactly one of:
//   page:  a QML page, path relative to qml/  (e.g. "pages/system/DisplayPage.qml")
//          props: {...} are passed to the page
//   kcm:   a Plasma KCM (temporary hand-off, to be replaced by a native page)
//   cmd:   a command to spawn, e.g. ["plasma-discover"]
// Optional: icon ("fl:<stem>"), desc (card subtitle), items (sub entries,
// walked by search), toggle (inline toggle id, see KcmListPage).

// Top-level page with its own QML that also shows a list of `items`
function custom(title, icon, page, items) {
    return { title: title, icon: icon, page: page, props: { pageTitle: title, items: items } }
}

// Plain list page (KcmListPage) of `items`
function list(title, icon, items) {
    return { title: title, icon: icon, page: "KcmListPage.qml",
             props: { pageTitle: title, items: items } }
}
