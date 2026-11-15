"""Backend for WinPlusSettingKde.

Talks to KDE Plasma 6 through the tools Plasma already ships:
kreadconfig6 / kwriteconfig6, plasma-apply-*, kscreen-doctor, dbus-send,
bluetoothctl, nmcli, pactl, powerprofilesctl, timedatectl.

One QObject, registered in QML as the `Backend` singleton, assembled from
one mixin per Settings section so sections can be worked on in parallel:

    core.py             async/debounce/poll plumbing, KCM hand-off   (shared)
    system.py           System
    bluetooth.py        Bluetooth & devices
    network.py          Network & internet
    personalization.py  Personalization
    apps.py             Apps
    accounts.py         Accounts
    time_language.py    Time & language
    gaming.py           Gaming
    accessibility.py    Accessibility
    privacy.py          Privacy & security
    updates.py          System updates

Every name a mixin defines (Signals, Properties, Slots, helpers, state)
shares ONE namespace. _check_unique() refuses to start if two mixins
define the same name, so a clash fails loudly instead of silently winning.
"""
from __future__ import annotations

from PySide6.QtCore import QObject

from .accessibility import AccessibilityMixin
from .accounts import AccountsMixin
from .apps import AppsMixin
from .bluetooth import BluetoothMixin
from .core import CoreMixin
from .gaming import GamingMixin
from .icons import IconProvider
from .network import NetworkMixin
from .personalization import PersonalizationMixin
from .privacy import PrivacyMixin
from .system import SystemMixin
from .time_language import TimeLanguageMixin
from .updates import UpdatesMixin

SECTIONS = [
    ("system", SystemMixin),
    ("bluetooth", BluetoothMixin),
    ("network", NetworkMixin),
    ("personalization", PersonalizationMixin),
    ("apps", AppsMixin),
    ("accounts", AccountsMixin),
    ("time_language", TimeLanguageMixin),
    ("gaming", GamingMixin),
    ("accessibility", AccessibilityMixin),
    ("privacy", PrivacyMixin),
    ("updates", UpdatesMixin),
]


def _check_unique():
    owner = {}
    for name, cls in [("core", CoreMixin), *SECTIONS]:
        for attr in vars(cls):
            if attr.startswith("__"):
                continue
            if attr in owner:
                raise RuntimeError(f"backend: '{attr}' is defined by both {owner[attr]} and {name}")
            owner[attr] = name


_check_unique()


class Backend(QObject, CoreMixin, SystemMixin, BluetoothMixin, NetworkMixin,
              PersonalizationMixin, AppsMixin, AccountsMixin, TimeLanguageMixin,
              GamingMixin, AccessibilityMixin, PrivacyMixin, UpdatesMixin):
    def __init__(self):
        QObject.__init__(self)
        self._init_core()
        for name, _cls in SECTIONS:
            getattr(self, f"_init_{name}")()
        self._start_core()


__all__ = ["Backend", "IconProvider"]
