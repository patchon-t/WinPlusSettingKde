"""Accounts: the signed-in user (name, login, picture)."""
from __future__ import annotations

import os
import pwd
from pathlib import Path

from PySide6.QtCore import Property

from .util import HOME, file_url


class AccountsMixin:
    def _init_accounts(self):
        pass

    @Property(str, constant=True)
    def userLogin(self):
        return pwd.getpwuid(os.getuid()).pw_name

    @Property(str, constant=True)
    def userName(self):
        pw = pwd.getpwuid(os.getuid())
        return (pw.pw_gecos.split(",")[0] or pw.pw_name).strip()

    @Property(str, constant=True)
    def avatar(self):
        login = pwd.getpwuid(os.getuid()).pw_name
        for p in (HOME / ".face.icon", HOME / ".face",
                  Path("/var/lib/AccountsService/icons") / login):
            if p.is_file():
                return file_url(str(p))
        return ""
