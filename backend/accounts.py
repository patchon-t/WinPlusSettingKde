"""Accounts: your info, sign-in options, other users, wallet.

AccountsService lives on the *system* bus (org.freedesktop.Accounts). Reads and
simple writes go through `busctl --system ... --json=short` run asynchronously
(`--allow-interactive-authorization=yes` lets polkit ask for the admin password).
The one call that carries a secret (SetPassword) goes through QtDBus instead, so
neither the password nor its hash ever appears on a command line.
"""
from __future__ import annotations

import ctypes
import ctypes.util
import json
import os
import pwd
import re
import secrets
import string
import tempfile
from pathlib import Path

from PySide6.QtCore import Property, QProcess, QUrl, Signal, Slot
try:  # Kubuntu ships QtDBus separately (python3-pyside6.qtdbus); without it only password change is disabled
    from PySide6.QtDBus import QDBusConnection, QDBusInterface, QDBusPendingCallWatcher
    _ACC_QTDBUS = True
except ImportError:
    _ACC_QTDBUS = False
from PySide6.QtGui import QImage

from .util import HOME, file_url, has, kread, kwrite, prop

ACCT = "org.freedesktop.Accounts"
ACCT_PATH = "/org/freedesktop/Accounts"
ACCT_USER = "org.freedesktop.Accounts.User"
POLKIT_MS = 120000          # a polkit prompt waits for a human

# "If you've been away, when should we require you to sign in again?"
ACC_AWAY_LABELS = ["Never", "Every time", "1 minute", "3 minutes", "5 minutes",
                   "15 minutes", "30 minutes"]
ACC_AWAY_SECONDS = [None, 0, 60, 180, 300, 900, 1800]   # None = never require

ACC_FINGERS = ["right-index-finger", "left-index-finger", "right-middle-finger",
               "left-middle-finger", "right-ring-finger", "left-ring-finger",
               "right-thumb", "left-thumb", "right-little-finger", "left-little-finger"]
ACC_NAME_RE = re.compile(r"^[a-z_][a-z0-9_-]{0,31}$")


def _acc_crypt_lib():
    name = ctypes.util.find_library("crypt")
    if not name:
        return None
    try:
        lib = ctypes.CDLL(name)
        lib.crypt.restype = ctypes.c_char_p
        lib.crypt.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
        return lib
    except (OSError, AttributeError):
        return None


def _acc_hash_password(plain: str) -> str:
    """SHA-512 crypt(3) hash, the same format kcm_users hands to SetPassword
    (plasma-workspace/kcms/users/src/user.cpp saltPassword)."""
    lib = _acc_crypt_lib()
    if lib is None:
        return ""
    alphabet = string.ascii_letters + string.digits + "./"
    salt = "$6$" + "".join(secrets.choice(alphabet) for _ in range(16)) + "$"
    out = lib.crypt(plain.encode(), salt.encode())
    return out.decode() if out and out.startswith(b"$6$") else ""


def _acc_variant_data(v):
    """busctl --json variant {"type":..,"data":..} -> plain python value."""
    if isinstance(v, dict) and "data" in v and "type" in v:
        return _acc_variant_data(v["data"])
    if isinstance(v, list):
        return [_acc_variant_data(x) for x in v]
    if isinstance(v, dict):
        return {k: _acc_variant_data(x) for k, x in v.items()}
    return v


def _acc_parse_json(out: str):
    try:
        return _acc_variant_data(json.loads(out))
    except (ValueError, TypeError):
        return None


def _acc_props(out: str) -> dict:
    """GetAll reply -> {Name: value}."""
    data = _acc_parse_json(out)
    if isinstance(data, list) and data:
        data = data[0]
    return data if isinstance(data, dict) else {}


class AccountsMixin:
    accountsChanged = Signal()
    accOpFinished = Signal(bool, str)      # (ok, message) after a write
    signInChanged = Signal()
    fingerprintChanged = Signal()
    walletChanged = Signal()

    def _init_accounts(self):
        pw = pwd.getpwuid(os.getuid())
        self._acc_login = pw.pw_name
        self._acc_real = (pw.pw_gecos.split(",")[0] or pw.pw_name).strip()
        self._acc_icon = ""
        self._acc_email = ""
        self._acc_type = -1                 # 0 standard, 1 administrator, -1 unknown
        self._acc_ok = False
        self._acc_path = ""
        self._acc_others = []
        self._acc_loading = False
        self._acc_watchers = []
        self._acc_hash_ok = _ACC_QTDBUS and _acc_crypt_lib() is not None
        # sign-in
        self._acc_away = 0
        self._acc_away_labels = list(ACC_AWAY_LABELS)
        self._acc_restore = True
        # fingerprint
        self._acc_fp_ok = False
        self._acc_fp_fingers = []
        self._acc_fp_busy = False
        self._acc_fp_stage = 0
        self._acc_fp_msg = ""
        self._acc_fp_proc = None
        # wallet
        self._acc_wallet_on = True
        self._acc_wallet_idle = False
        self._acc_wallet_min = 10
        self.refreshAccounts()

    # ---------------------------------------------------- identity (nav pane uses these)
    @Property(str, notify=accountsChanged)
    def userLogin(self):
        return self._acc_login

    @Property(str, notify=accountsChanged)
    def userName(self):
        return self._acc_real

    @Property(str, notify=accountsChanged)
    def avatar(self):
        for p in (self._acc_icon, str(HOME / ".face.icon"), str(HOME / ".face"),
                  str(Path("/var/lib/AccountsService/icons") / self._acc_login)):
            if p and Path(p).is_file():
                try:
                    stamp = int(Path(p).stat().st_mtime)
                except OSError:
                    stamp = 0
                return file_url(p) + "#" + str(stamp)   # fragment busts the image cache
        return ""

    accountType = prop("acc_type", int, accountsChanged)
    userEmail = prop("acc_email", str, accountsChanged)
    accountsAvailable = prop("acc_ok", bool, accountsChanged)
    accountsLoading = prop("acc_loading", bool, accountsChanged)
    otherUsers = prop("acc_others", "QVariantList", accountsChanged)
    passwordSupported = prop("acc_hash_ok", bool, accountsChanged)

    @Property(str, notify=accountsChanged)
    def accountTypeText(self):
        return {0: "Standard user", 1: "Administrator"}.get(self._acc_type, "Local account")

    # ---------------------------------------------------- AccountsService plumbing
    def _acc_busctl(self, args, callback=None, timeout_ms: int = POLKIT_MS):
        self._async(["busctl", "--system", "--json=short",
                     "--allow-interactive-authorization=yes",
                     f"--timeout={timeout_ms // 1000}", *args], callback, timeout_ms + 2000)

    @Slot()
    def refreshAccounts(self):
        """Find the signed-in user, read their properties, then the other users."""
        if self._acc_loading:
            return
        self._acc_loading = True
        self.accountsChanged.emit()

        def fail():
            self._acc_ok = False
            self._acc_loading = False
            self.accountsChanged.emit()

        def found(ok, out):
            path = (_acc_parse_json(out) or [""])[0] if ok else ""
            if not path:
                return fail()
            self._acc_path = path
            self._acc_busctl(["call", ACCT, path, "org.freedesktop.DBus.Properties",
                              "GetAll", "s", ACCT_USER], got_self, 15000)

        def got_self(ok, out):
            p = _acc_props(out) if ok else {}
            if not p:
                return fail()
            self._acc_ok = True
            self._acc_real = (p.get("RealName") or p.get("UserName") or self._acc_login).strip()
            self._acc_login = p.get("UserName") or self._acc_login
            self._acc_icon = p.get("IconFile") or ""
            self._acc_email = p.get("Email") or ""
            self._acc_type = int(p.get("AccountType", -1))
            self._acc_loading = False
            self.accountsChanged.emit()
            self._acc_refresh_others()

        self._acc_busctl(["call", ACCT, ACCT_PATH, ACCT, "FindUserById", "x", str(os.getuid())],
                         found, 15000)

    def _acc_refresh_others(self):
        def listed(ok, out):
            paths = (_acc_parse_json(out) or [[]])[0] if ok else []
            if not paths:
                self._acc_others = []
                self.accountsChanged.emit()
                return
            rows, left = [], [len(paths)]

            def one(path):
                def got(ok2, out2):
                    p = _acc_props(out2) if ok2 else {}
                    if p and not p.get("SystemAccount") and int(p.get("Uid", -1)) != os.getuid():
                        icon = p.get("IconFile") or ""
                        rows.append({
                            "uid": int(p.get("Uid", 0)),
                            "name": p.get("UserName", ""),
                            "fullName": (p.get("RealName") or p.get("UserName") or "").strip(),
                            "admin": int(p.get("AccountType", 0)) == 1,
                            "locked": bool(p.get("Locked", False)),
                            "icon": file_url(icon) if icon and Path(icon).is_file() else "",
                            "path": path})
                    left[0] -= 1
                    if left[0] == 0:
                        rows.sort(key=lambda r: r["uid"])
                        self._acc_others = rows
                        self.accountsChanged.emit()
                self._acc_busctl(["call", ACCT, path, "org.freedesktop.DBus.Properties",
                                  "GetAll", "s", ACCT_USER], got, 15000)

            for p in paths:
                one(p)

        self._acc_busctl(["call", ACCT, ACCT_PATH, ACCT, "ListCachedUsers"], listed, 15000)

    def _acc_write(self, path, method, sig, args, done_msg, fail_msg, then=None):
        """One polkit-gated AccountsService write, then refresh + notify QML."""
        def cb(ok, _out):
            if ok:
                self.refreshAccounts()
            self.accOpFinished.emit(ok, done_msg if ok else fail_msg)
            if then:
                then(ok)
        self._acc_busctl(["call", ACCT, path, ACCT_USER if path != ACCT_PATH else ACCT,
                          method, sig, *[str(a) for a in args]], cb)

    # ---------------------------------------------------- Your info
    @Slot(str)
    def setUserRealName(self, name: str):
        name = name.strip()
        if not name or not self._acc_path:
            return
        self._acc_real = name           # optimistic
        self.accountsChanged.emit()
        self._acc_write(self._acc_path, "SetRealName", "s", [name],
                        "Your name was changed.", "Couldn't change your name.")

    @Slot(str)
    def setUserPicture(self, url: str):
        """Crop to a square, save a temp PNG, hand it to SetIconFile."""
        path = QUrl(url).toLocalFile() if url.startswith("file:") else url
        img = QImage(path)
        if img.isNull() or not self._acc_path:
            self.accOpFinished.emit(False, "That file isn't a picture we can use.")
            return
        side = min(img.width(), img.height())
        img = img.copy((img.width() - side) // 2, (img.height() - side) // 2, side, side)
        if side > 512:
            img = img.scaled(512, 512)
        fd, tmp = tempfile.mkstemp(suffix=".png", prefix="winsettings-face-")
        os.close(fd)
        img.save(tmp, "PNG")
        os.chmod(tmp, 0o644)            # AccountsService reads it as root, but be friendly

        def finished(_ok):
            try:
                os.unlink(tmp)
            except OSError:
                pass
        self._acc_write(self._acc_path, "SetIconFile", "s", [tmp],
                        "Your picture was changed.", "Couldn't change your picture.", finished)

    @Slot()
    def removeUserPicture(self):
        if self._acc_path:
            self._acc_write(self._acc_path, "SetIconFile", "s", [""],
                            "Your picture was removed.", "Couldn't remove your picture.")

    # ---------------------------------------------------- Password (SetPassword via QtDBus)
    def _acc_set_password(self, path: str, plain: str, hint: str, callback):
        if not _ACC_QTDBUS:
            callback(False)
            return
        crypted = _acc_hash_password(plain)
        if not crypted:
            return callback(False)
        iface = QDBusInterface(ACCT, path, ACCT_USER, QDBusConnection.systemBus())
        if not iface.isValid():
            return callback(False)
        iface.setInteractiveAuthorizationAllowed(True)
        watcher = QDBusPendingCallWatcher(iface.asyncCall("SetPassword", crypted, hint))
        self._acc_watchers.append((watcher, iface))

        def done(w):
            ok = not w.isError()
            self._acc_watchers[:] = [x for x in self._acc_watchers if x[0] is not w]
            w.deleteLater()
            callback(ok)
        watcher.finished.connect(done)

    @Slot(str, str)
    def changeUserPassword(self, new_password: str, hint: str):
        if not new_password or not self._acc_path:
            return

        def done(ok):
            self.accOpFinished.emit(ok, "Your password was changed." if ok
                                    else "Couldn't change your password.")
        self._acc_set_password(self._acc_path, new_password, hint, done)

    # ---------------------------------------------------- Sign-in options
    @Slot()
    def refreshSignIn(self):
        req = kread("kscreenlockerrc", "Daemon", "RequirePassword", "true") == "true"
        resume = kread("kscreenlockerrc", "Daemon", "LockOnResume", "true") == "true"
        try:
            grace = int(kread("kscreenlockerrc", "Daemon", "LockGrace", "5"))
        except ValueError:
            grace = 5
        labels = list(ACC_AWAY_LABELS)
        if not req or not resume:
            idx = 0
        elif grace in ACC_AWAY_SECONDS:
            idx = ACC_AWAY_SECONDS.index(grace)
        else:                                   # a value set elsewhere: show it as its own entry
            labels.append(f"{grace // 60} minutes" if grace % 60 == 0 else f"{grace} seconds")
            idx = len(labels) - 1
        self._acc_away_labels, self._acc_away = labels, idx
        self._acc_restore = kread("ksmserverrc", "General", "loginMode",
                                  "restorePreviousLogout") != "emptySession"
        self.signInChanged.emit()

    awayOptions = prop("acc_away_labels", "QVariantList", signInChanged)
    awayIndex = prop("acc_away", int, signInChanged)
    restoreAppsOn = prop("acc_restore", bool, signInChanged)

    @Slot(int)
    def setAwayIndex(self, i: int):
        if not 0 <= i < len(ACC_AWAY_SECONDS):
            return                              # a custom entry is already the current value
        self._acc_away = i
        self.signInChanged.emit()
        secs = ACC_AWAY_SECONDS[i]
        if secs is None:                        # Never
            kwrite("kscreenlockerrc", "Daemon", "RequirePassword", "false", "bool")
            kwrite("kscreenlockerrc", "Daemon", "LockOnResume", "false", "bool")
        else:
            kwrite("kscreenlockerrc", "Daemon", "RequirePassword", "true", "bool")
            kwrite("kscreenlockerrc", "Daemon", "LockOnResume", "true", "bool")
            kwrite("kscreenlockerrc", "Daemon", "LockGrace", str(secs), "int")

    @Slot(bool)
    def setRestoreApps(self, on: bool):
        self._acc_restore = on
        self.signInChanged.emit()
        kwrite("ksmserverrc", "General", "loginMode",
               "restorePreviousLogout" if on else "emptySession")

    # ---------------------------------------------------- Fingerprint (fprintd CLI)
    fingerprintAvailable = prop("acc_fp_ok", bool, fingerprintChanged)
    fingerprints = prop("acc_fp_fingers", "QVariantList", fingerprintChanged)
    fingerprintBusy = prop("acc_fp_busy", bool, fingerprintChanged)
    fingerprintStage = prop("acc_fp_stage", int, fingerprintChanged)
    fingerprintMessage = prop("acc_fp_msg", str, fingerprintChanged)

    @Slot()
    def refreshFingerprints(self):
        if not has("fprintd-list"):
            self._acc_fp_ok = False
            self.fingerprintChanged.emit()
            return

        def got(ok, out):
            self._acc_fp_ok = ok and "No devices" not in out and bool(out.strip())
            self._acc_fp_fingers = (re.findall(r"#\d+:\s*([a-z][a-z-]*)", out)
                                    if self._acc_fp_ok else [])
            self.fingerprintChanged.emit()
        self._async(["fprintd-list", self._acc_login], got, 8000)

    @Slot()
    def enrollFingerprint(self):
        if self._acc_fp_busy or not self._acc_fp_ok:
            return
        free = [f for f in ACC_FINGERS if f not in self._acc_fp_fingers]
        if not free:
            self._acc_fp_msg = "All ten fingers are already added."
            self.fingerprintChanged.emit()
            return
        finger = free[0]
        p = QProcess(self)
        self._acc_fp_proc = p
        self._acc_fp_busy, self._acc_fp_stage = True, 0
        self._acc_fp_msg = "Touch the fingerprint reader repeatedly until it's done."
        self.fingerprintChanged.emit()

        def read():
            text = bytes(p.readAllStandardOutput()).decode(errors="replace")
            n = text.count("enroll-stage-passed")
            if n:
                self._acc_fp_stage += n
                self.fingerprintChanged.emit()

        def finished(code, _st):
            read()
            self._acc_fp_busy = False
            self._acc_fp_proc = None
            self._acc_fp_msg = "Fingerprint added." if code == 0 else "Couldn't add the fingerprint."
            self.fingerprintChanged.emit()
            p.deleteLater()
            self.refreshFingerprints()
        p.readyReadStandardOutput.connect(read)
        p.finished.connect(finished)
        p.start("fprintd-enroll", ["-f", finger, self._acc_login])

    @Slot()
    def cancelFingerprintEnroll(self):
        if self._acc_fp_proc is not None:
            self._acc_fp_proc.terminate()

    @Slot()
    def removeFingerprints(self):
        def done(ok, _out):
            self._acc_fp_msg = "Fingerprints removed." if ok else "Couldn't remove the fingerprints."
            self.fingerprintChanged.emit()
            self.refreshFingerprints()
        self._async(["fprintd-delete", self._acc_login], done, POLKIT_MS)

    # ---------------------------------------------------- Other users
    @Slot(str, str, str, int)
    def addUserAccount(self, username: str, full_name: str, password: str, acct_type: int):
        username = username.strip()
        if not ACC_NAME_RE.match(username) or not password:
            self.accOpFinished.emit(False, "Enter a user name (lowercase letters, digits, - and _) and a password.")
            return

        def created(ok, out):
            path = (_acc_parse_json(out) or [""])[0] if ok else ""
            if not path:
                self.accOpFinished.emit(False, "Couldn't add the account.")
                return

            def pw_done(ok2):
                self.refreshAccounts()
                self.accOpFinished.emit(ok2, "The account was added." if ok2
                                        else "The account was added, but its password couldn't be set.")
            self._acc_set_password(path, password, "", pw_done)
        self._acc_busctl(["call", ACCT, ACCT_PATH, ACCT, "CreateUser", "ssi",
                          username, full_name.strip() or username, str(int(acct_type))], created)

    @Slot(str, int)
    def setOtherUserType(self, path: str, acct_type: int):
        self._acc_write(path, "SetAccountType", "i", [int(acct_type)],
                        "The account type was changed.", "Couldn't change the account type.")

    @Slot(int, bool)
    def removeUserAccount(self, uid: int, remove_files: bool):
        self._acc_write(ACCT_PATH, "DeleteUser", "xb", [uid, "true" if remove_files else "false"],
                        "The account was removed.", "Couldn't remove the account.")

    # ---------------------------------------------------- Plasma Wallet (extra)
    walletEnabled = prop("acc_wallet_on", bool, walletChanged)
    walletCloseWhenIdle = prop("acc_wallet_idle", bool, walletChanged)
    walletIdleMinutes = prop("acc_wallet_min", int, walletChanged)

    @Slot()
    def refreshWallet(self):
        self._acc_wallet_on = kread("kwalletrc", "Wallet", "Enabled", "true") == "true"
        self._acc_wallet_idle = kread("kwalletrc", "Wallet", "Close When Idle", "false") == "true"
        try:
            self._acc_wallet_min = int(kread("kwalletrc", "Wallet", "Idle Timeout", "10"))
        except ValueError:
            self._acc_wallet_min = 10
        self.walletChanged.emit()

    @Slot(bool)
    def setWalletEnabled(self, on: bool):
        self._acc_wallet_on = on
        self.walletChanged.emit()
        kwrite("kwalletrc", "Wallet", "Enabled", "true" if on else "false", "bool")

    @Slot(bool)
    def setWalletCloseWhenIdle(self, on: bool):
        self._acc_wallet_idle = on
        self.walletChanged.emit()
        kwrite("kwalletrc", "Wallet", "Close When Idle", "true" if on else "false", "bool")

    @Slot(int)
    def setWalletIdleMinutes(self, m: int):
        m = max(1, min(240, int(m)))
        self._acc_wallet_min = m
        self.walletChanged.emit()
        kwrite("kwalletrc", "Wallet", "Idle Timeout", str(m), "int")
