"""Network & internet: connection status, Wi-Fi (NetworkManager via nmcli)."""
from __future__ import annotations

import re

from PySide6.QtCore import QTimer, Signal, Slot

from .util import prop


class NetworkMixin:
    networkChanged = Signal()
    wifiChanged = Signal()
    wifiResult = Signal(bool, str)      # ok, message (shown to the user)

    def _init_network(self):
        self._net_type, self._net_name = "", ""
        self._wifi_on, self._wifi_list, self._wifi_iface, self._wifi_known = False, [], "", set()
        self._wifi_busy = False
        self._pollers.append(self._poll_network)

    networkType = prop("net_type", str, networkChanged)
    networkName = prop("net_name", str, networkChanged)
    wifiEnabled = prop("wifi_on", bool, wifiChanged)
    wifiNetworks = prop("wifi_list", "QVariantList", wifiChanged)
    wifiBusy = prop("wifi_busy", bool, wifiChanged)

    # ---------------------------------------------------- status
    def _poll_network(self):
        self._async(["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"], self._on_net, timeout_ms=3000)

    def _on_net(self, ok: bool, out: str):
        typ, name = "", ""
        for line in out.splitlines():
            parts = line.split(":", 2)
            if len(parts) == 3 and parts[1] == "connected" and parts[0] in ("ethernet", "wifi"):
                typ, name = parts[0], parts[2].replace("\\:", ":")
                break
        if (typ, name) != (self._net_type, self._net_name):
            self._net_type, self._net_name = typ, name
            self.networkChanged.emit()

    # ---------------------------------------------------- Wi-Fi
    @staticmethod
    def _nm_fields(line: str) -> list:
        return [f.replace("\\:", ":") for f in re.split(r"(?<!\\):", line)]

    @Slot()
    def refreshWifi(self):
        self._scan_wifi(False)

    @Slot()
    def rescanWifi(self):
        self._scan_wifi(True)

    def _scan_wifi(self, rescan: bool):
        def got_radio(_ok, out):
            self._wifi_on = out.strip() == "enabled"
            self.wifiChanged.emit()

        def got_devs(_ok, out):
            for line in out.splitlines():
                f = self._nm_fields(line)
                if len(f) >= 2 and f[1] == "wifi":
                    self._wifi_iface = f[0]
                    break

        def got_known(_ok, out):
            self._wifi_known = {f[0] for f in map(self._nm_fields, out.splitlines())
                                if len(f) >= 2 and f[1] == "802-11-wireless"}

        def got_list(_ok, out):
            best = {}
            for line in out.splitlines():
                f = self._nm_fields(line)
                if len(f) < 4 or not f[1]:
                    continue
                ssid = f[1]
                net = {"ssid": ssid, "signal": int(f[2] or 0), "secure": bool(f[3].strip()) and f[3] != "--",
                       "active": f[0] == "*", "known": ssid in self._wifi_known}
                old = best.get(ssid)
                if not old or net["active"] or (not old["active"] and net["signal"] > old["signal"]):
                    best[ssid] = net
            self._wifi_list = sorted(best.values(), key=lambda n: (not n["active"], -n["signal"]))
            self.wifiChanged.emit()

        self._async(["nmcli", "-t", "-f", "WIFI", "radio"], got_radio, 3000)
        self._async(["nmcli", "-t", "-f", "DEVICE,TYPE", "device"], got_devs, 3000)
        self._async(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"], got_known, 3000)
        self._async(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list",
                     "--rescan", "yes" if rescan else "no"], got_list, 20000)

    @Slot(bool)
    def setWifiEnabled(self, on: bool):
        self._wifi_on = on
        self.wifiChanged.emit()
        self._async(["nmcli", "radio", "wifi", "on" if on else "off"],
                    lambda *_: QTimer.singleShot(1500, self.refreshWifi))

    @Slot(str, str)
    def wifiConnect(self, ssid: str, password: str):
        if ssid in self._wifi_known and not password:
            args = ["nmcli", "connection", "up", "id", ssid]
        else:
            args = ["nmcli", "device", "wifi", "connect", ssid]
            if password:
                args += ["password", password]
        self._wifi_busy = True
        self.wifiChanged.emit()

        def done(ok, out):
            self._wifi_busy = False
            self.wifiResult.emit(ok, f"Connected to {ssid}" if ok else
                                 f"Couldn't connect to {ssid}. Check the password and try again.")
            self.refreshWifi()
            self._poll_network()

        self._async(args, done, 45000)

    @Slot()
    def wifiDisconnect(self):
        if self._wifi_iface:
            self._async(["nmcli", "device", "disconnect", self._wifi_iface],
                        lambda *_: (self.refreshWifi(), self._poll_network()))

    @Slot(str)
    def wifiForget(self, ssid: str):
        self._async(["nmcli", "connection", "delete", "id", ssid], lambda *_: self.refreshWifi())
