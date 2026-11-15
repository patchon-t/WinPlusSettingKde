"""Apps: installed apps, default apps, startup.

Owned by the Apps section.

* Installed apps  = .desktop files from the XDG data dirs (scanned in a worker
  thread when the page opens), enriched with `flatpak list` (Flatpak) and
  `dpkg-query` (distribution packages) where those tools exist.
* Default apps    = `xdg-mime query default` / `xdg-mime default`.
* Startup         = XDG autostart entries; "off" = Hidden=true in the user copy
  (SITEMAP APP.STA.1, plasma-workspace/kcms/autostart/autostartmodel.cpp).
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import threading
import time
from pathlib import Path

from PySide6.QtCore import (Property, QAbstractListModel, QMimeDatabase, QModelIndex, QObject,
                            Qt, Signal, Slot)

from .util import HOME, has, kread, kwrite, spawn

# --------------------------------------------------------------------------- helpers
_FLATPAK_DIRS = [HOME / ".local/share/flatpak/exports/share",
                 Path("/var/lib/flatpak/exports/share")]
_SNAP_DIR = Path("/var/lib/snapd/desktop")
_LANGS: list[str] = []


def _apps_langs() -> list[str]:
    if not _LANGS:
        raw = os.environ.get("LC_MESSAGES") or os.environ.get("LANG") or ""
        base = raw.split(".")[0].split("@")[0]
        if base and base not in ("C", "POSIX"):
            _LANGS.append(base)
            if "_" in base:
                _LANGS.append(base.split("_")[0])
    return _LANGS


def _apps_data_dirs() -> list[Path]:
    """Application dirs in precedence order (user first), incl. Flatpak/Snap exports."""
    home = Path(os.environ.get("XDG_DATA_HOME") or HOME / ".local/share")
    dirs = [home]
    dirs += [Path(p) for p in (os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share").split(":") if p]
    dirs += _FLATPAK_DIRS + [_SNAP_DIR]
    out, seen = [], set()
    for d in dirs:
        if str(d) not in seen:
            seen.add(str(d))
            out.append(d)
    return out


def _apps_parse_desktop(path: Path) -> dict | None:
    """Minimal [Desktop Entry] parser. Returns the keys we need (or None)."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    ent: dict[str, str] = {}
    names: dict[str, str] = {}
    inside = False
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("["):
            if inside:
                break
            inside = line == "[Desktop Entry]"
            continue
        if not inside or "=" not in line:
            continue
        k, _, v = line.partition("=")
        k, v = k.strip(), v.strip()
        if k.startswith("Name["):
            names[k[5:-1]] = v
        elif k in ("Name", "Type", "Icon", "NoDisplay", "Hidden", "MimeType", "OnlyShowIn",
                   "NotShowIn", "Categories", "Exec", "TryExec", "Comment", "X-SnapInstanceName",
                   "X-GNOME-Autostart-enabled", "X-GNOME-Autostart-Delay"):
            ent[k] = v
    for lang in _apps_langs():
        if lang in names:
            ent["Name"] = names[lang]
            break
    return ent


def _apps_split(v: str) -> list[str]:
    return [x for x in v.split(";") if x]


def _apps_shown_in_kde(ent: dict) -> bool:
    only, notshow = _apps_split(ent.get("OnlyShowIn", "")), _apps_split(ent.get("NotShowIn", ""))
    return "KDE" not in notshow and (not only or "KDE" in only)


def _apps_fmt_size(n: int) -> str:
    if n <= 0:
        return ""
    for unit, div in (("GB", 1 << 30), ("MB", 1 << 20), ("KB", 1 << 10)):
        if n >= div:
            v = n / div
            return f"{v:.2f} {unit}" if unit == "GB" else f"{v:.1f} {unit}" if v < 100 else f"{v:.0f} {unit}"
    return f"{n} bytes"


def _apps_parse_size(s: str) -> int:
    m = re.match(r"\s*([\d.,]+)\s*([A-Za-z]*)", s.replace(" ", " ").replace(" ", " "))
    if not m:
        return 0
    try:
        val = float(m.group(1).replace(",", "."))
    except ValueError:
        return 0
    mult = {"": 1, "bytes": 1, "b": 1, "kb": 10**3, "kib": 1 << 10, "mb": 10**6, "mib": 1 << 20,
            "gb": 10**9, "gib": 1 << 30}.get(m.group(2).lower(), 1)
    return int(val * mult)


def _apps_fmt_date(ts: float) -> str:
    return time.strftime("%-m/%-d/%Y", time.localtime(ts)) if ts > 0 else ""


def _apps_run(args, timeout=20) -> str:
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return r.stdout if r.returncode == 0 else ""


def _apps_scan() -> list[dict]:
    """Runs in a worker thread. Reads every visible .desktop file."""
    seen: set[str] = set()
    apps: list[dict] = []
    for base in _apps_data_dirs():
        root = base / "applications"
        if not root.is_dir():
            continue
        for dp, _dn, fns in os.walk(root):
            for fn in fns:
                if not fn.endswith(".desktop"):
                    continue
                p = Path(dp) / fn
                did = str(p.relative_to(root)).replace("/", "-")
                if did in seen:
                    continue
                seen.add(did)                       # a higher dir masks lower ones
                ent = _apps_parse_desktop(p)
                if not ent or ent.get("Type", "Application") != "Application":
                    continue
                if ent.get("NoDisplay", "").lower() == "true" or ent.get("Hidden", "").lower() == "true":
                    continue
                if not ent.get("Name") or not _apps_shown_in_kde(ent):
                    continue
                tryexec = ent.get("TryExec", "")
                if tryexec and not shutil.which(tryexec) and not os.path.exists(tryexec):
                    continue
                try:
                    mtime = p.stat().st_mtime
                except OSError:
                    mtime = 0
                is_flat = "/flatpak/exports/" in str(p)
                is_snap = str(p).startswith(str(_SNAP_DIR)) or "X-SnapInstanceName" in ent
                src = "flatpak" if is_flat else "snap" if is_snap else "user" if base == (
                    Path(os.environ.get("XDG_DATA_HOME") or HOME / ".local/share")) else "package"
                apps.append({
                    "id": did, "name": ent["Name"], "icon": ent.get("Icon", "") or "application-x-executable",
                    "comment": ent.get("Comment", ""), "path": str(p), "src": src,
                    "mimes": _apps_split(ent.get("MimeType", "")),
                    "cats": _apps_split(ent.get("Categories", "")),
                    "exec": ent.get("Exec", ""), "date": mtime,
                    "pkg": ent.get("X-SnapInstanceName", "") if is_snap else (did[:-8] if is_flat else ""),
                    "version": "", "publisher": "", "size": 0, "inst": "",
                })
    _apps_enrich_flatpak(apps)
    _apps_enrich_dpkg(apps)
    return apps


def _apps_enrich_flatpak(apps: list[dict]):
    if not has("flatpak") or not any(a["src"] == "flatpak" for a in apps):
        return
    out = _apps_run(["flatpak", "list", "--app",
                     "--columns=application,version,origin,installation,size"], 20)
    info = {}
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) >= 4:
            info[parts[0].strip()] = parts
    for a in apps:
        if a["src"] != "flatpak" or a["pkg"] not in info:
            continue
        p = info[a["pkg"]]
        a["version"], a["publisher"], a["inst"] = p[1].strip(), p[2].strip(), p[3].strip()
        a["size"] = _apps_parse_size(p[4]) if len(p) > 4 else 0


def _apps_enrich_dpkg(apps: list[dict]):
    if not has("dpkg-query"):
        return
    pk = [a for a in apps if a["src"] == "package"]
    if not pk:
        return
    owner: dict[str, str] = {}
    out = _apps_run(["dpkg-query", "-S", *[a["path"] for a in pk]], 20)
    for line in out.splitlines():
        head, sep, path = line.rpartition(": ")
        if sep:
            owner[path] = head.split(",")[0].strip()
    info: dict[str, tuple] = {}
    out = _apps_run(["dpkg-query", "-W", "-f=${Package}\t${Version}\t${Maintainer}\t${Installed-Size}\n"], 20)
    for line in out.splitlines():
        p = line.split("\t")
        if len(p) == 4:
            info[p[0]] = p
    for a in pk:
        pkg = owner.get(a["path"], "")
        if not pkg:
            continue
        base = pkg.split(":")[0]
        a["pkg"] = base
        row = info.get(base)
        if row:
            a["version"] = row[1]
            a["publisher"] = re.sub(r"\s*<[^>]*>", "", row[2]).strip()
            try:
                a["size"] = int(row[3]) * 1024
            except ValueError:
                pass


class _AppsModel(QAbstractListModel):
    ROLES = ["appId", "name", "icon", "version", "publisher", "source", "sizeText", "dateText",
             "canUninstall", "isFlatpak", "details"]

    def __init__(self, parent=None):
        super().__init__(parent)
        self._rows: list[dict] = []
        self._names = {Qt.UserRole + 1 + i: r.encode() for i, r in enumerate(self.ROLES)}

    def roleNames(self):
        return self._names

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._rows)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(self._rows):
            return None
        key = self.ROLES[role - Qt.UserRole - 1] if role > Qt.UserRole else None
        return self._rows[index.row()].get(key) if key else None

    def reset(self, rows):
        self.beginResetModel()
        self._rows = rows
        self.endResetModel()


_SRC_LABEL = {"flatpak": "Flatpak", "package": "System package", "snap": "Snap", "user": "User"}
_FS = [  # (token, Win11-style label)
    ("xdg-documents", "Documents folder"), ("xdg-download", "Downloads folder"),
    ("xdg-music", "Music library"), ("xdg-pictures", "Pictures library"),
    ("xdg-videos", "Videos library"), ("home", "Home folder"), ("host", "File system")]


# --------------------------------------------------------------------------- mixin
class AppsMixin:
    appsChanged = Signal()          # revision bumped: scan finished / list changed
    appsViewChanged = Signal()
    appsDefaultsChanged = Signal()
    appsStartupChanged = Signal()
    appsPermsChanged = Signal()
    appsTerminalChanged = Signal()
    appsUninstallFinished = Signal(str, bool)
    _apps_scanned = Signal(object)

    def _init_apps(self):
        self._apps_all: list[dict] = []
        self._apps_byid: dict[str, dict] = {}
        self._apps_rev = 0
        self._apps_loading = False
        self._apps_scan_done = False
        self._apps_model = _AppsModel(self)
        self._apps_q, self._apps_sort, self._apps_filter = "", 0, 0
        self._apps_total = 0
        self._apps_shown = 0
        self._apps_busy_id = ""
        self._apps_defaults: dict = {}
        self._apps_startup: list = []
        self._apps_perms: dict = {}
        self._apps_terminal = ""
        self._apps_scanned.connect(self._apps_on_scanned)

    # ------------------------------------------------------ properties
    appsModel = Property(QObject, lambda self: self._apps_model, constant=True)
    appsRevision = Property(int, lambda self: self._apps_rev, notify=appsChanged)
    appsLoading = Property(bool, lambda self: self._apps_loading, notify=appsViewChanged)
    appsTotal = Property(int, lambda self: self._apps_total, notify=appsViewChanged)
    appsShown = Property(int, lambda self: self._apps_shown, notify=appsViewChanged)
    appsBusyId = Property(str, lambda self: self._apps_busy_id, notify=appsViewChanged)
    appsDefaults = Property("QVariantMap", lambda self: self._apps_defaults, notify=appsDefaultsChanged)
    appsStartup = Property("QVariantList", lambda self: self._apps_startup, notify=appsStartupChanged)
    appsPerms = Property("QVariantMap", lambda self: self._apps_perms, notify=appsPermsChanged)
    appsTerminalId = Property(str, lambda self: self._apps_terminal, notify=appsTerminalChanged)

    # ------------------------------------------------------ installed apps: scan
    @Slot()
    def appsRefresh(self):
        """Scan .desktop files off the GUI thread (no-op if already scanned/scanning)."""
        if self._apps_loading or self._apps_scan_done:
            return
        self._apps_loading = True
        self.appsViewChanged.emit()
        threading.Thread(target=lambda: self._apps_scanned.emit(_apps_scan()), daemon=True).start()

    @Slot()
    def appsRescan(self):
        self._apps_scan_done = False
        self.appsRefresh()

    def _apps_on_scanned(self, apps):
        self._apps_all = apps
        self._apps_byid = {a["id"]: a for a in apps}
        self._apps_loading = False
        self._apps_scan_done = True
        self._apps_total = len(apps)
        self._apps_rev += 1
        self._apps_apply()
        self.appsChanged.emit()
        self.appsViewChanged.emit()

    @Slot(str, int, int)
    def appsSetView(self, query: str, sort: int, flt: int):
        """sort: 0 name A-Z, 1 name Z-A, 2 size large-small, 3 size small-large,
        4 newest first, 5 oldest first.  flt: 0 all, 1 system packages, 2 Flatpak, 3 other."""
        self._apps_q, self._apps_sort, self._apps_filter = query.strip().lower(), sort, flt
        self._apps_apply()
        self.appsViewChanged.emit()

    def _apps_apply(self):
        q, flt = self._apps_q, self._apps_filter
        rows = []
        for a in self._apps_all:
            if flt == 1 and a["src"] != "package":
                continue
            if flt == 2 and a["src"] != "flatpak":
                continue
            if flt == 3 and a["src"] in ("package", "flatpak"):
                continue
            if q and q not in a["name"].lower() and q not in a["pkg"].lower():
                continue
            rows.append(a)
        s = self._apps_sort
        if s in (0, 1):
            rows.sort(key=lambda a: a["name"].lower(), reverse=s == 1)
        elif s in (2, 3):
            rows.sort(key=lambda a: (a["size"] <= 0, -a["size"] if s == 2 else a["size"], a["name"].lower()))
        else:
            rows.sort(key=lambda a: a["date"], reverse=s == 4)
        self._apps_shown = len(rows)
        self._apps_model.reset([self._apps_row(a) for a in rows])

    def _apps_row(self, a: dict) -> dict:
        parts = [x for x in (a["version"], a["publisher"]) if x]
        return {
            "appId": a["id"], "name": a["name"], "icon": a["icon"], "version": a["version"],
            "publisher": a["publisher"], "source": _SRC_LABEL.get(a["src"], ""),
            "sizeText": _apps_fmt_size(a["size"]), "dateText": _apps_fmt_date(a["date"]),
            "canUninstall": self._apps_can_uninstall(a), "isFlatpak": a["src"] == "flatpak",
            "details": "  |  ".join(parts),
        }

    @staticmethod
    def _apps_can_uninstall(a: dict) -> bool:
        if a["src"] == "flatpak":
            return has("flatpak") and bool(a["pkg"])
        return a["src"] == "package" and bool(a["pkg"]) and has("pkcon")

    @Slot(str, result="QVariantMap")
    def appsInfo(self, app_id: str):
        a = self._apps_byid.get(app_id)
        if not a:
            return {}
        r = self._apps_row(a)
        r.update({"pkg": a["pkg"], "comment": a["comment"], "mimeCount": len(a["mimes"]),
                  "installation": a["inst"]})
        return r

    # ------------------------------------------------------ uninstall
    @Slot(str)
    def appsUninstall(self, app_id: str):
        a = self._apps_byid.get(app_id)
        if not a or not self._apps_can_uninstall(a) or self._apps_busy_id:
            return
        if a["src"] == "flatpak":
            args = ["flatpak", "uninstall", "--assumeyes", "--noninteractive",
                    "--system" if a["inst"] == "system" else "--user", a["pkg"]]
        else:
            args = ["pkcon", "remove", "-y", a["pkg"]]    # PackageKit asks polkit
        self._apps_busy_id = app_id
        self.appsViewChanged.emit()

        def done(ok, _out):
            self._apps_busy_id = ""
            if ok:
                self._apps_all = [x for x in self._apps_all if x["id"] != app_id]
                self._apps_byid.pop(app_id, None)
                self._apps_total = len(self._apps_all)
                self._apps_rev += 1
                self._apps_apply()
                self.appsChanged.emit()
            self.appsViewChanged.emit()
            self.appsUninstallFinished.emit(a["name"], ok)
        self._async(args, done, 600000)

    # ------------------------------------------------------ flatpak permissions (APP.INS.4)
    @staticmethod
    def _apps_keyfile(text: str) -> dict:
        """[Context] of a flatpak metadata/override keyfile -> {key: [values]}."""
        ctx, inside = {}, False
        for line in text.splitlines():
            line = line.strip()
            if line.startswith("["):
                inside = line == "[Context]"
            elif inside and "=" in line:
                k, _, v = line.partition("=")
                ctx[k.strip()] = [x for x in v.split(";") if x]
        return ctx

    @Slot(str)
    def appsLoadPerms(self, app_id: str):
        a = self._apps_byid.get(app_id)
        self._apps_perms = {}
        self.appsPermsChanged.emit()
        if not a or a["src"] != "flatpak":
            return
        pkg, scope = a["pkg"], ("--system" if a["inst"] == "system" else "--user")

        def got_info(_ok, info):
            def got_over(_ok2, over):
                ctx = self._apps_keyfile(info)
                for k, vals in self._apps_keyfile(over).items():     # overrides win ("!x" removes x)
                    cur = ctx.setdefault(k, [])
                    for v in vals:
                        if v.startswith("!"):
                            cur[:] = [c for c in cur if c.split(":")[0] != v[1:]]
                        elif v not in cur:
                            cur[:] = [c for c in cur if c.split(":")[0] != v.split(":")[0]] + [v]
                fs = {c.split(":")[0]: c for c in ctx.get("filesystems", [])}
                perms = {
                    "network": "network" in ctx.get("shared", []),
                    "sound": "pulseaudio" in ctx.get("sockets", []),
                    "devices": "all" in ctx.get("devices", []),
                    "fs": {tok: (tok in fs, fs.get(tok, "").endswith(":ro")) for tok, _l in _FS},
                    "ok": bool(info.strip()),
                }
                self._apps_perms = {"id": app_id, **perms}
                self.appsPermsChanged.emit()
            self._async(["flatpak", "override", scope, "--show", pkg], got_over, 8000)
        self._async(["flatpak", "info", "--show-permissions", pkg], got_info, 8000)

    @Slot(str, str, bool)
    def appsSetPerm(self, app_id: str, key: str, on: bool):
        """key: network | sound | devices | fs:<token>  (flatpak override --user ...)."""
        a = self._apps_byid.get(app_id)
        if not a or a["src"] != "flatpak":
            return
        if key == "network":
            flag = ("--share=" if on else "--unshare=") + "network"
        elif key == "sound":
            flag = ("--socket=" if on else "--nosocket=") + "pulseaudio"
        elif key == "devices":
            flag = ("--device=" if on else "--nodevice=") + "all"
        elif key.startswith("fs:") and key[3:] in dict(_FS):
            flag = ("--filesystem=" if on else "--nofilesystem=") + key[3:]
        else:
            return
        p = dict(self._apps_perms)
        if key.startswith("fs:"):
            fs = dict(p.get("fs", {}))
            fs[key[3:]] = (on, False)
            p["fs"] = fs
        else:
            p[key] = on
        self._apps_perms = p
        self.appsPermsChanged.emit()
        self._async(["flatpak", "override", "--user", flag, a["pkg"]],
                    lambda *_: self.appsLoadPerms(app_id), 8000)

    @Slot(str)
    def appsResetPerms(self, app_id: str):
        a = self._apps_byid.get(app_id)
        if a and a["src"] == "flatpak":
            self._async(["flatpak", "override", "--user", "--reset", a["pkg"]],
                        lambda *_: self.appsLoadPerms(app_id), 8000)

    @Slot(result="QVariantList")
    def appsFsList(self):
        return [{"token": t, "label": lbl} for t, lbl in _FS]

    # ------------------------------------------------------ default apps
    @staticmethod
    def _apps_mime_label(mime: str) -> str:
        if mime.startswith("x-scheme-handler/"):
            return mime.split("/", 1)[1] + ":"
        mt = QMimeDatabase().mimeTypeForName(mime)
        if mt.isValid():
            suf = mt.preferredSuffix()
            return (f".{suf}  " if suf else "") + mt.comment()
        return mime

    def _apps_app_ref(self, did: str) -> dict:
        a = self._apps_byid.get(did)
        return {"id": did, "name": a["name"] if a else did.removesuffix(".desktop"),
                "icon": a["icon"] if a else "application-x-executable"} if did else {"id": "", "name": "", "icon": ""}

    @Slot(str, result="QVariantList")
    def appsHandlerApps(self, query: str):
        """Apps that declare at least one MIME type (Default apps list)."""
        q = query.strip().lower()
        rows = [{"id": a["id"], "name": a["name"], "icon": a["icon"], "count": len(a["mimes"])}
                for a in self._apps_all if a["mimes"] and (not q or q in a["name"].lower())]
        rows.sort(key=lambda r: r["name"].lower())
        return rows

    @Slot(str, result="QVariantList")
    def appsMimesOf(self, app_id: str):
        a = self._apps_byid.get(app_id)
        if not a:
            return []
        rows = [{"mime": m, "label": self._apps_mime_label(m), "link": m.startswith("x-scheme-handler/")}
                for m in a["mimes"]]
        rows.sort(key=lambda r: (r["link"], r["label"].lower()))
        return rows

    @Slot(str, result="QVariantList")
    def appsHandlersFor(self, mime: str):
        rows = [{"id": a["id"], "name": a["name"], "icon": a["icon"]}
                for a in self._apps_all if mime in a["mimes"]]
        rows.sort(key=lambda r: r["name"].lower())
        return rows

    @Slot("QStringList")
    def appsQueryDefaults(self, mimes):
        """xdg-mime query default for each type, one async shell for all of them."""
        mimes = [m for m in mimes if m]
        if not mimes or not has("xdg-mime"):
            return
        script = 'for m in "$@"; do printf "%s\\t%s\\n" "$m" "$(xdg-mime query default "$m")"; done'

        def done(_ok, out):
            d = dict(self._apps_defaults)
            for line in out.splitlines():
                mime, _, did = line.partition("\t")
                d[mime] = self._apps_app_ref(did.strip())
            self._apps_defaults = d
            self.appsDefaultsChanged.emit()
        self._async(["sh", "-c", script, "sh", *mimes], done, 30000)

    @Slot(str, str)
    def appsSetDefault(self, mime: str, desktop_id: str):
        d = dict(self._apps_defaults)
        d[mime] = self._apps_app_ref(desktop_id)
        self._apps_defaults = d
        self.appsDefaultsChanged.emit()
        self._async(["xdg-mime", "default", desktop_id, mime], lambda *_: None, 8000)

    @Slot(str, result="QVariantList")
    def appsSearchTypes(self, text: str):
        """File type (.pdf) or link type (mailto) -> [{mime,label,link}]."""
        t = text.strip().lower()
        if not t:
            return []
        db, found, seen = QMimeDatabase(), [], set()

        def add(mime):
            if mime not in seen:
                seen.add(mime)
                found.append({"mime": mime, "label": self._apps_mime_label(mime),
                              "link": mime.startswith("x-scheme-handler/")})
        if "/" in t:
            add(t)
        elif t.startswith("."):
            for mt in db.mimeTypesForFileName("x" + t):
                add(mt.name())
        else:
            for mt in db.mimeTypesForFileName("x." + t):
                add(mt.name())
            scheme = t.rstrip(":/")
            if scheme.isalpha() or scheme.replace("-", "").isalnum():
                add("x-scheme-handler/" + scheme)
        return found

    @Slot(str, str, result="QVariantList")
    def appsAllTypes(self, kind: str, query: str):
        """kind 'file' | 'link' -> every declared type with its resolved default app."""
        q = query.strip().lower()
        want_link = kind == "link"
        mimes = {m for a in self._apps_all for m in a["mimes"] if m.startswith("x-scheme-handler/") == want_link}
        defaults = self._apps_mimeapps_defaults()
        rows = []
        for m in sorted(mimes):
            label = self._apps_mime_label(m)
            if q and q not in label.lower() and q not in m.lower():
                continue
            did = next((i for i in defaults.get(m, []) if i in self._apps_byid), "")
            if not did:
                did = next((a["id"] for a in self._apps_all if m in a["mimes"]), "")
            ref = self._apps_app_ref(did)
            rows.append({"mime": m, "label": label, "defId": ref["id"], "defName": ref["name"],
                         "defIcon": ref["icon"]})
        rows.sort(key=lambda r: r["label"].lower())
        return rows

    @staticmethod
    def _apps_mimeapps_defaults() -> dict:
        """[Default Applications] of the mimeapps.list chain, first file wins."""
        cfg = Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config")
        data = Path(os.environ.get("XDG_DATA_HOME") or HOME / ".local/share")
        files = [cfg / "mimeapps.list", data / "applications/mimeapps.list"]
        files += [Path(p) / "mimeapps.list" for p in (os.environ.get("XDG_CONFIG_DIRS") or "/etc/xdg").split(":") if p]
        files += [Path(p) / "applications/mimeapps.list"
                  for p in (os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share").split(":") if p]
        res: dict[str, list] = {}
        for f in files:
            try:
                text = f.read_text(errors="replace")
            except OSError:
                continue
            inside = False
            for line in text.splitlines():
                line = line.strip()
                if line.startswith("["):
                    inside = line == "[Default Applications]"
                elif inside and "=" in line:
                    k, _, v = line.partition("=")
                    res.setdefault(k.strip(), []).extend(_apps_split(v))
        return res

    # ------------------------------------------------------ terminal emulator (APP.DEF.4 = SYS.DEV.2)
    @Slot()
    def appsRefreshTerminal(self):
        self._apps_terminal = kread("kdeglobals", "General", "TerminalService", "org.kde.konsole.desktop")
        self.appsTerminalChanged.emit()

    @Slot(result="QVariantList")
    def appsTerminals(self):
        rows = [{"id": a["id"], "name": a["name"], "icon": a["icon"]}
                for a in self._apps_all if "TerminalEmulator" in a["cats"]]
        rows.sort(key=lambda r: r["name"].lower())
        return rows

    @Slot(str)
    def appsSetTerminal(self, desktop_id: str):
        a = self._apps_byid.get(desktop_id)
        if not a:
            return
        cmd = re.sub(r"%[a-zA-Z]", "", a["exec"]).split()
        kwrite("kdeglobals", "General", "TerminalApplication", cmd[0] if cmd else "konsole")
        kwrite("kdeglobals", "General", "TerminalService", desktop_id)
        self._apps_terminal = desktop_id
        self.appsTerminalChanged.emit()

    # ------------------------------------------------------ startup
    @staticmethod
    def _apps_autostart_dirs():
        cfg = Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config")
        user = cfg / "autostart"
        system = [Path(p) / "autostart" for p in (os.environ.get("XDG_CONFIG_DIRS") or "/etc/xdg").split(":") if p]
        return user, system

    @staticmethod
    def _apps_ent_enabled(ent: dict) -> bool:
        return (ent.get("Hidden", "").lower() != "true"
                and ent.get("X-GNOME-Autostart-enabled", "true").lower() != "false")

    @Slot(int)
    def appsRefreshStartup(self, sort: int = 0):
        """sort: 0 name, 1 status (on first)."""
        user, system = self._apps_autostart_dirs()
        files: dict[str, Path] = {}
        for d in [user, *system]:            # user copy overrides the system one
            if d.is_dir():
                for p in d.glob("*.desktop"):
                    files.setdefault(p.name, p)
        rows = []
        for name, p in files.items():
            ent = _apps_parse_desktop(p)
            if not ent or not ent.get("Name") or not _apps_shown_in_kde(ent):
                continue
            tryexec = ent.get("TryExec", "")
            if tryexec and not shutil.which(tryexec) and not os.path.exists(tryexec):
                continue
            rows.append({"file": name, "name": ent["Name"], "comment": ent.get("Comment", ""),
                         "icon": ent.get("Icon", "") or "application-x-executable",
                         "enabled": self._apps_ent_enabled(ent), "system": p.parent != user})
        rows.sort(key=lambda r: (not r["enabled"], r["name"].lower()) if sort == 1 else r["name"].lower())
        self._apps_startup = rows
        self.appsStartupChanged.emit()

    @Slot(str, bool)
    def appsSetStartup(self, file: str, enabled: bool):
        if "/" in file or not file.endswith(".desktop"):
            return
        user, system = self._apps_autostart_dirs()
        target = user / file
        src = target if target.exists() else next((d / file for d in system if (d / file).exists()), None)
        if src is None:
            return
        try:
            text = src.read_text(errors="replace")
            lines = text.splitlines()
            out, in_entry, done = [], False, False
            for line in lines:
                s = line.strip()
                if s.startswith("["):
                    if in_entry and not done:
                        out.append(f"Hidden={'false' if enabled else 'true'}")
                        done = True
                    in_entry = s == "[Desktop Entry]"
                elif in_entry and (s.startswith("Hidden=") or s.startswith("X-GNOME-Autostart-enabled=")):
                    if s.startswith("Hidden="):
                        line = f"Hidden={'false' if enabled else 'true'}"
                        done = True
                    else:
                        line = f"X-GNOME-Autostart-enabled={'true' if enabled else 'false'}"
                out.append(line)
            if in_entry and not done:
                out.append(f"Hidden={'false' if enabled else 'true'}")
            user.mkdir(parents=True, exist_ok=True)
            target.write_text("\n".join(out) + "\n")
        except OSError:
            return
        self._apps_startup = [dict(r, enabled=enabled) if r["file"] == file else r
                              for r in self._apps_startup]
        self.appsStartupChanged.emit()

    @Slot(result="QVariantList")
    def appsStartupScripts(self):
        """Plasma login / logout scripts (APP.STA.3)."""
        base = Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config")
        rows = []
        for sub, label in (("plasma-workspace/env", "Runs before sign-in finishes"),
                           ("plasma-workspace/shutdown", "Runs when you sign out")):
            d = base / sub
            if d.is_dir():
                for p in sorted(d.iterdir()):
                    if p.is_file():
                        rows.append({"name": p.name, "desc": label, "path": str(p), "dir": str(d)})
        return rows

    @Slot(str)
    def appsOpenFolder(self, path: str):
        spawn(["xdg-open", path])
