"""Privacy & security: app permissions (Flatpak), activity history, diagnostics,
search (Baloo / KRunner), firewall (ufw), device encryption (lsblk).

Every key / method used here is listed as verified in SITEMAP.md section 10.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from PySide6.QtCore import Signal, Slot

from .util import HOME, has, kread, kwrite, prop

# ---------------------------------------------------------------- app permissions
# Portal permission-store tables: (table, id, allow values, deny values, value when unset).
# SRC xdg-desktop-portal shared/xdp-types.h; location value = [accuracy, timestamp]
# (desktop-portal/location.c set_location_permissions); the others are "yes" / "no".
_PRV_PORTAL = {
    "location": ("location", "location", ["EXACT", "0"], ["NONE", "0"], False),
    "camera": ("devices", "camera", ["yes"], ["no"], False),
    "notifications": ("notifications", "notification", ["yes"], ["no"], True),
    "screenshot": ("screenshot", "screenshot", ["yes"], ["no"], False),
}
_PRV_ALLOW_WORDS = {"yes", "EXACT", "CITY", "NEIGHBORHOOD", "STREET"}

# Static Flatpak sandbox holes: (metadata key, token, override flag). Tokens from
# SRC flatpak-kcm/flatpakpermission.cpp:108-125 (xdg-*, host); socket pulseaudio is a flatpak socket name.
_PRV_STATIC = {
    "microphone": ("sockets", "pulseaudio", "socket"),
    "documents": ("filesystems", "xdg-documents", "filesystem"),
    "downloads": ("filesystems", "xdg-download", "filesystem"),
    "music": ("filesystems", "xdg-music", "filesystem"),
    "pictures": ("filesystems", "xdg-pictures", "filesystem"),
    "videos": ("filesystems", "xdg-videos", "filesystem"),
    "files": ("filesystems", "host", "filesystem"),
}

_PRV_UFW_RULE = re.compile(r"^\[\s*(\d+)\]\s+(.+?)\s{2,}(ALLOW|DENY|REJECT|LIMIT)(?:\s+(IN|OUT|FWD))?\s+(.*)$")
_PRV_TOKEN = re.compile(r"^[A-Za-z0-9_.:/,-]+$")


def _prv_keyfile(text: str) -> dict:
    """Parse the [Context] group of flatpak metadata / override output -> {key: [items]}."""
    out, grp = {}, ""
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("["):
            grp = line
        elif grp == "[Context]" and "=" in line:
            k, v = line.split("=", 1)
            out[k.strip()] = [x for x in v.split(";") if x]
    return out


def _prv_effective(meta: dict, override: dict, key: str) -> list:
    items = list(meta.get(key, []))
    for it in override.get(key, []):
        if it.startswith("!"):
            bare = it[1:]
            items = [x for x in items if x != bare and x.split(":")[0] != bare]
        else:
            items.append(it)
    return [x.split(":")[0] for x in items]


def _prv_expand(p: str) -> str:
    p = p.strip()
    if p.startswith("$HOME"):
        p = str(HOME) + p[5:]
    elif p.startswith("~"):
        p = str(HOME) + p[1:]
    return p


class PrivacyMixin:
    prvPermChanged = Signal()
    prvActivityChanged = Signal()
    prvActivityResult = Signal(bool, str)
    prvDiagChanged = Signal()
    prvSearchChanged = Signal()
    prvFirewallChanged = Signal()
    prvFirewallResult = Signal(bool, str)
    prvEncChanged = Signal()

    def _init_privacy(self):
        self._prv_kind = ""
        self._prvPermApps = []
        self._prvPermLoading = False
        self._prvFlatpak = has("flatpak")
        self._prvActWhat = 0
        self._prvActMonths = 4
        self._prvFeedback = 0
        self._prvSearchHist = 2
        self._prvBalooOn = True
        self._prvBalooBasic = False
        self._prvBalooHidden = False
        self._prvBalooExcluded = []
        self._prvUfwInstalled = has("ufw")
        self._prvUfwEnabled = False
        self._prvUfwRules = []
        self._prvUfwRulesLoaded = False
        self._prvUfwBusy = False
        self._prvEncDevices = []
        self._prvEncRoot = -1          # -1 unknown, 0 not encrypted, 1 encrypted
        self._prvEncLoaded = False

    prvFlatpak = prop("prvFlatpak", bool)
    prvPermApps = prop("prvPermApps", list, prvPermChanged)
    prvPermLoading = prop("prvPermLoading", bool, prvPermChanged)
    prvActivityWhat = prop("prvActWhat", int, prvActivityChanged)
    prvActivityMonths = prop("prvActMonths", int, prvActivityChanged)
    prvFeedbackLevel = prop("prvFeedback", int, prvDiagChanged)
    prvSearchHistory = prop("prvSearchHist", int, prvSearchChanged)
    prvBalooEnabled = prop("prvBalooOn", bool, prvSearchChanged)
    prvBalooBasic = prop("prvBalooBasic", bool, prvSearchChanged)
    prvBalooHidden = prop("prvBalooHidden", bool, prvSearchChanged)
    prvBalooExcluded = prop("prvBalooExcluded", list, prvSearchChanged)
    prvUfwInstalled = prop("prvUfwInstalled", bool)
    prvUfwEnabled = prop("prvUfwEnabled", bool, prvFirewallChanged)
    prvUfwRules = prop("prvUfwRules", list, prvFirewallChanged)
    prvUfwRulesLoaded = prop("prvUfwRulesLoaded", bool, prvFirewallChanged)
    prvUfwBusy = prop("prvUfwBusy", bool, prvFirewallChanged)
    prvEncDevices = prop("prvEncDevices", list, prvEncChanged)
    prvEncRoot = prop("prvEncRoot", int, prvEncChanged)
    prvEncLoaded = prop("prvEncLoaded", bool, prvEncChanged)

    # ---------------------------------------------------------------- app permissions
    @Slot(str)
    def refreshPrvPermission(self, kind: str):
        if kind not in _PRV_PORTAL and kind not in _PRV_STATIC:
            return
        self._prv_kind = kind
        self._prvPermApps = []
        self._prvPermLoading = self._prvFlatpak
        self.prvPermChanged.emit()
        if not self._prvFlatpak:
            return

        def listed(ok, out):
            if self._prv_kind != kind:
                return
            apps = []
            for line in out.splitlines():
                parts = line.split("\t")
                if parts[0].strip():
                    apps.append({"id": parts[0].strip(),
                                 "name": (parts[1].strip() if len(parts) > 1 and parts[1].strip() else parts[0].strip()),
                                 "allowed": False})
            apps.sort(key=lambda a: a["name"].lower())
            if not ok or not apps:
                self._prv_perm_done([])
            elif kind in _PRV_PORTAL:
                self._prv_load_portal(kind, apps)
            else:
                self._prv_load_static(kind, apps)

        self._async(["flatpak", "list", "--app", "--columns=application,name"], listed, 15000)

    def _prv_perm_done(self, apps):
        self._prvPermApps = apps
        self._prvPermLoading = False
        self.prvPermChanged.emit()

    def _prv_load_portal(self, kind, apps):
        table, oid, _allow, _deny, unset = _PRV_PORTAL[kind]

        def got(ok, out):
            if self._prv_kind != kind:
                return
            state = {}
            for line in out.splitlines():
                t = line.split()
                if len(t) >= 4 and t[0] == table and t[1] == oid:
                    state[t[2]] = t[3].split(",")[0] in _PRV_ALLOW_WORDS
            for a in apps:
                a["allowed"] = state.get(a["id"], unset)
            self._prv_perm_done(apps)

        self._async(["flatpak", "permissions", table, oid], got, 15000)

    def _prv_load_static(self, kind, apps):
        key, token, _flag = _PRV_STATIC[kind]
        script = ('for a in "$@"; do echo "@@APP $a"; flatpak info --show-permissions "$a" 2>/dev/null; '
                  'echo "@@OVR"; flatpak override --user --show "$a" 2>/dev/null; done')

        def got(ok, out):
            if self._prv_kind != kind:
                return
            res = {}
            for chunk in out.split("@@APP ")[1:]:
                head, _, rest = chunk.partition("\n")
                meta_txt, _, ovr_txt = rest.partition("@@OVR")
                items = _prv_effective(_prv_keyfile(meta_txt), _prv_keyfile(ovr_txt), key)
                res[head.strip()] = token in items or (token != "host" and key == "filesystems" and "host" in items)
            for a in apps:
                a["allowed"] = res.get(a["id"], False)
            self._prv_perm_done(apps)

        self._async(["sh", "-c", script, "sh", *[a["id"] for a in apps]], got, 60000)

    def _prv_write_perm(self, kind, app_id, allowed, done=None):
        if kind in _PRV_PORTAL:
            table, oid, allow, deny, _u = _PRV_PORTAL[kind]
            args = ["flatpak", "permission-set", table, oid, app_id, *(allow if allowed else deny)]
        else:
            _key, token, flag = _PRV_STATIC[kind]
            args = ["flatpak", "override", "--user",
                    f"--{flag if allowed else 'no' + flag}={token}", app_id]
        self._async(args, done, 15000)

    @Slot(str, str, bool)
    def setPrvAppPermission(self, kind: str, app_id: str, allowed: bool):
        for a in self._prvPermApps:
            if a["id"] == app_id:
                a["allowed"] = allowed
        self._prvPermApps = list(self._prvPermApps)
        self.prvPermChanged.emit()
        self._prv_write_perm(kind, app_id, allowed,
                             lambda ok, _o: None if ok else self.refreshPrvPermission(kind))

    @Slot(str, bool)
    def setPrvAllPermissions(self, kind: str, allowed: bool):
        for a in self._prvPermApps:
            if a["allowed"] != allowed:
                a["allowed"] = allowed
                self._prv_write_perm(kind, a["id"], allowed)
        self._prvPermApps = list(self._prvPermApps)
        self.prvPermChanged.emit()

    # ---------------------------------------------------------------- activity history
    _PRV_ACT = ("kactivitymanagerd-pluginsrc", "Plugin-org.kde.ActivityManager.Resources.Scoring")

    @Slot()
    def refreshPrvActivity(self):
        f, g = self._PRV_ACT
        self._prvActWhat = int(kread(f, g, "what-to-remember", "0") or 0)
        self._prvActMonths = int(kread(f, g, "keep-history-for", "4") or 4)
        self.prvActivityChanged.emit()

    @Slot(bool)
    def setPrvActivityStore(self, on: bool):
        f, g = self._PRV_ACT
        v = (self._prvActWhat if self._prvActWhat == 1 else 0) if on else 2
        self._prvActWhat = v
        kwrite(f, g, "what-to-remember", str(v), "int")
        self.prvActivityChanged.emit()

    @Slot(int)
    def setPrvActivityMonths(self, months: int):
        f, g = self._PRV_ACT
        self._prvActMonths = months
        kwrite(f, g, "keep-history-for", str(months), "int")
        self.prvActivityChanged.emit()

    @Slot()
    def clearPrvActivity(self):
        # DeleteRecentStats(s activity, i count, s what): empty activity = all, what "everything"
        # (SRC kactivitymanagerd StatsPlugin.cpp:401-415; same call as plasma-desktop kcm_recentFiles.cpp:191)
        def done(ok, _o):
            self.prvActivityResult.emit(ok, "Activity history cleared." if ok else "Couldn't clear activity history.")
        self._async(["dbus-send", "--session", "--dest=org.kde.ActivityManager", "--type=method_call",
                     "/ActivityManager/Resources/Scoring",
                     "org.kde.ActivityManager.ResourcesScoring.DeleteRecentStats",
                     "string:", "int32:0", "string:everything"], done, 15000)

    # ---------------------------------------------------------------- diagnostics
    @Slot()
    def refreshPrvDiagnostics(self):
        self._prvFeedback = int(kread("PlasmaUserFeedback", "Global", "FeedbackLevel", "0") or 0)
        self.prvDiagChanged.emit()

    @Slot(int)
    def setPrvFeedbackLevel(self, level: int):
        self._prvFeedback = level
        kwrite("PlasmaUserFeedback", "Global", "FeedbackLevel", str(level), "int")
        self.prvDiagChanged.emit()

    # ---------------------------------------------------------------- search
    @Slot()
    def refreshPrvSearch(self):
        self._prvSearchHist = int(kread("krunnerrc", "General", "historyBehavior", "2") or 2)
        self._prvBalooOn = kread("baloofilerc", "Basic Settings", "Indexing-Enabled", "true") != "false"
        self._prvBalooBasic = kread("baloofilerc", "General", "only basic indexing", "false") == "true"
        self._prvBalooHidden = kread("baloofilerc", "General", "index hidden folders", "false") == "true"
        raw = kread("baloofilerc", "General", "exclude folders", "")
        self._prvBalooExcluded = [_prv_expand(p) for p in raw.split(",") if p.strip()]
        self.prvSearchChanged.emit()

    @Slot(int)
    def setPrvSearchHistory(self, v: int):
        self._prvSearchHist = v
        kwrite("krunnerrc", "General", "historyBehavior", str(v), "int")
        self.prvSearchChanged.emit()

    @Slot(bool)
    def setPrvBalooEnabled(self, on: bool):
        self._prvBalooOn = on
        kwrite("baloofilerc", "Basic Settings", "Indexing-Enabled", "true" if on else "false", "bool")
        self.prvSearchChanged.emit()

    @Slot(bool)
    def setPrvBalooBasic(self, on: bool):
        self._prvBalooBasic = on
        kwrite("baloofilerc", "General", "only basic indexing", "true" if on else "false", "bool")
        self.prvSearchChanged.emit()

    @Slot(bool)
    def setPrvBalooHidden(self, on: bool):
        self._prvBalooHidden = on
        kwrite("baloofilerc", "General", "index hidden folders", "true" if on else "false", "bool")
        self.prvSearchChanged.emit()

    def _prv_save_excluded(self):
        kwrite("baloofilerc", "General", "exclude folders", ",".join(self._prvBalooExcluded))
        self.prvSearchChanged.emit()

    @Slot(str)
    def addPrvExcludedFolder(self, url: str):
        p = url[7:] if url.startswith("file://") else url
        from urllib.parse import unquote
        p = unquote(p)
        if not p or "," in p:
            return
        p = p.rstrip("/") + "/"
        if p in self._prvBalooExcluded:
            return
        self._prvBalooExcluded = self._prvBalooExcluded + [p]
        self._prv_save_excluded()

    @Slot(str)
    def removePrvExcludedFolder(self, path: str):
        self._prvBalooExcluded = [p for p in self._prvBalooExcluded if p != path]
        self._prv_save_excluded()

    # ---------------------------------------------------------------- firewall (ufw)
    @Slot()
    def refreshPrvFirewall(self):
        self._prvUfwInstalled = has("ufw")
        try:
            txt = Path("/etc/ufw/ufw.conf").read_text()
            self._prvUfwEnabled = bool(re.search(r"^ENABLED=yes", txt, re.M))
        except OSError:
            pass
        self.prvFirewallChanged.emit()

    @Slot()
    def loadPrvFirewallRules(self):
        if not self._prvUfwInstalled or self._prvUfwBusy:
            return
        self._prvUfwBusy = True
        self.prvFirewallChanged.emit()

        def done(ok, out):
            self._prvUfwBusy = False
            if ok:
                rules = []
                for line in out.splitlines():
                    if line.startswith("Status:"):
                        self._prvUfwEnabled = "inactive" not in line
                    m = _PRV_UFW_RULE.match(line)
                    if m:
                        rules.append({"num": int(m.group(1)), "to": m.group(2).strip(), "action": m.group(3),
                                      "dir": m.group(4) or "IN", "from": m.group(5).strip()})
                self._prvUfwRules = rules
                self._prvUfwRulesLoaded = True
            else:
                self.prvFirewallResult.emit(False, "Couldn't read the firewall rules (authentication was cancelled?).")
            self.prvFirewallChanged.emit()

        self._async(["pkexec", "ufw", "status", "numbered"], done, 120000)

    def _prv_ufw(self, args, msg):
        if self._prvUfwBusy:
            return
        self._prvUfwBusy = True
        self.prvFirewallChanged.emit()

        def done(ok, out):
            self._prvUfwBusy = False
            self.prvFirewallResult.emit(ok, msg if ok else "The firewall command failed or was cancelled.")
            self.refreshPrvFirewall()
            if ok and self._prvUfwRulesLoaded:
                self.loadPrvFirewallRules()

        self._async(["pkexec", "ufw", "--force", *args], done, 120000)

    @Slot(bool)
    def setPrvFirewallEnabled(self, on: bool):
        self._prv_ufw(["enable" if on else "disable"],
                      "Firewall turned on." if on else "Firewall turned off.")

    @Slot(str, str, str)
    def addPrvFirewallRule(self, action: str, direction: str, rule: str):
        toks = rule.split()
        if action not in ("allow", "deny", "reject", "limit") or direction not in ("in", "out") \
                or not toks or not all(_PRV_TOKEN.match(t) for t in toks):
            self.prvFirewallResult.emit(False, "Enter a port such as 443 or 8000:8100/tcp, or an app profile name.")
            return
        self._prv_ufw([action, direction, *toks], "Rule added.")

    @Slot(int)
    def removePrvFirewallRule(self, num: int):
        self._prv_ufw(["delete", str(num)], "Rule deleted.")

    # ---------------------------------------------------------------- device encryption
    @Slot()
    def refreshPrvEncryption(self):
        def done(ok, out):
            self._prvEncLoaded = True
            devs, root = [], -1
            try:
                tree = json.loads(out)["blockdevices"] if ok else []
            except (ValueError, KeyError):
                tree = []

            def walk(node, enc):
                nonlocal root
                here = enc or node.get("type") == "crypt" or node.get("fstype") == "crypto_LUKS"
                mounts = [m for m in (node.get("mountpoints") or []) if m]
                if "/" in mounts:
                    root = 1 if here else 0
                found = here
                for ch in node.get("children") or []:
                    found = walk(ch, here) or found
                return found

            for d in tree:
                if d.get("type") != "disk":
                    continue
                enc = walk(d, False)
                devs.append({"name": d.get("name", ""), "size": d.get("size", ""), "encrypted": enc})
            self._prvEncDevices = devs
            self._prvEncRoot = root
            self.prvEncChanged.emit()

        self._async(["lsblk", "-J", "-o", "NAME,TYPE,FSTYPE,SIZE,MOUNTPOINTS"], done, 8000)
