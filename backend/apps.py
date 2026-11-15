"""Apps (installed apps, default apps, startup, ...).

Owned by the Apps section. Add Signals / Properties / Slots here and
initialise state in _init_apps(). See backend/core.py for _async/_later.
"""
from __future__ import annotations


class AppsMixin:
    def _init_apps(self):
        pass
