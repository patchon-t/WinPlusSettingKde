"""Time & language: time zone, automatic time (timedatectl)."""
from __future__ import annotations

from PySide6.QtCore import Signal, Slot

from .util import prop, run


class TimeLanguageMixin:
    timeChanged = Signal()

    def _init_time_language(self):
        self._timezone, self._ntp, self._timezones = "", False, []

    timezone = prop("timezone", str, timeChanged)
    timezones = prop("timezones", "QVariantList", timeChanged)
    autoTime = prop("ntp", bool, timeChanged)

    @Slot()
    def refreshTime(self):
        info = dict(line.split("=", 1) for line in run(["timedatectl", "show"]).splitlines() if "=" in line)
        self._timezone = info.get("Timezone", "")
        self._ntp = info.get("NTP", "no") == "yes"
        if not self._timezones:
            self._timezones = run(["timedatectl", "list-timezones"]).splitlines()
        self.timeChanged.emit()

    @Slot(str)
    def setTimezone(self, tz: str):
        self._async(["timedatectl", "set-timezone", tz], lambda *_: self.refreshTime(), 120000)

    @Slot(bool)
    def setAutoTime(self, on: bool):
        self._ntp = on
        self.timeChanged.emit()
        self._async(["timedatectl", "set-ntp", "true" if on else "false"], lambda *_: self.refreshTime(), 120000)
