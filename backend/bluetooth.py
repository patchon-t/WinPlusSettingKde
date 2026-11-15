"""Bluetooth & devices: adapter power, paired devices (bluetoothctl)."""
from __future__ import annotations

import re

from PySide6.QtCore import Signal, Slot

from .util import prop


class BluetoothMixin:
    bluetoothChanged = Signal()
    bluetoothDevicesChanged = Signal()

    def _init_bluetooth(self):
        self._bt_on, self._bt_avail = False, False
        self._bt_devices = []
        self._pollers.append(self._poll_bluetooth)

    bluetoothOn = prop("bt_on", bool, bluetoothChanged)
    bluetoothAvailable = prop("bt_avail", bool, bluetoothChanged)
    bluetoothDevices = prop("bt_devices", "QVariantList", bluetoothDevicesChanged)

    # ---------------------------------------------------- adapter
    def _poll_bluetooth(self):
        self._async(["bluetoothctl", "show"], self._on_bt, timeout_ms=3000)

    def _on_bt(self, ok: bool, out: str):
        avail = ok and "Controller" in out
        on = avail and re.search(r"Powered:\s*yes", out) is not None
        if (avail, on) != (self._bt_avail, self._bt_on):
            self._bt_avail, self._bt_on = avail, on
            self.bluetoothChanged.emit()

    @Slot(bool)
    def setBluetooth(self, on: bool):
        self._bt_on = on
        self.bluetoothChanged.emit()
        self._async(["bluetoothctl", "power", "on" if on else "off"], lambda *_: self._poll_bluetooth())

    # ---------------------------------------------------- devices
    @staticmethod
    def _parse_bt(out: str) -> list:
        res = []
        for line in out.splitlines():
            m = re.match(r"Device\s+([0-9A-F:]{17})\s+(.*)", line.strip())
            if m:
                res.append((m.group(1), m.group(2).strip()))
        return res

    @Slot()
    def refreshBluetoothDevices(self):
        def got_paired(_ok, out):
            paired = self._parse_bt(out)

            def got_connected(_ok2, out2):
                conn = {mac for mac, _ in self._parse_bt(out2)}
                self._bt_devices = [{"mac": m, "name": n, "connected": m in conn}
                                    for m, n in sorted(paired, key=lambda d: (d[0] not in conn, d[1].lower()))]
                self.bluetoothDevicesChanged.emit()

            self._async(["bluetoothctl", "devices", "Connected"], got_connected, 4000)

        self._async(["bluetoothctl", "devices", "Paired"], got_paired, 4000)

    def _bt_action(self, *args):
        self._async(["bluetoothctl", *args], lambda *_: self.refreshBluetoothDevices(), 20000)

    @Slot(str)
    def bluetoothConnect(self, mac: str):
        self._bt_action("connect", mac)

    @Slot(str)
    def bluetoothDisconnect(self, mac: str):
        self._bt_action("disconnect", mac)

    @Slot(str)
    def bluetoothRemove(self, mac: str):
        self._bt_action("remove", mac)
