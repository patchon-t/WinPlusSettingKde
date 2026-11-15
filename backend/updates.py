"""System updates (package updates via PackageKit / Discover).

Owned by the Updates section. Add Signals / Properties / Slots here and
initialise state in _init_updates(). See backend/core.py for _async/_later.
"""
from __future__ import annotations


class UpdatesMixin:
    def _init_updates(self):
        pass
