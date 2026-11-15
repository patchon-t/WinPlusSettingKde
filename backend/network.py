"""Network & internet: status, Wi-Fi, Ethernet, VPN, hotspot, airplane mode, proxy,
adapters (NetworkManager via nmcli; KDE proxy via kioslaverc)."""
from __future__ import annotations

import getpass
import ipaddress
import os
import random
import re
import string

from PySide6.QtCore import QTimer, Signal, Slot

from .util import has, kread, kwrite, prop, spawn

_NET_HOTSPOT_CON = "Hotspot"          # connection id used for the mobile hotspot
_NET_PROXY_FILE = "kioslaverc"
_NET_PROXY_GROUP = "Proxy Settings"

_NET_DEV_LABELS = [
    ("GENERAL.VENDOR", "Manufacturer"),
    ("GENERAL.PRODUCT", "Description"),
    ("GENERAL.DRIVER", "Driver"),
    ("GENERAL.DRIVER-VERSION", "Driver version"),
    ("GENERAL.FIRMWARE-VERSION", "Firmware version"),
    ("GENERAL.HWADDR", "Physical address (MAC)"),
    ("GENERAL.MTU", "MTU"),
    ("GENERAL.STATE", "State"),
    ("GENERAL.CONNECTION", "Connection"),
    ("WIRED-PROPERTIES.CARRIER", "Cable"),
    ("IP4.ADDRESS", "IPv4 address"),
    ("IP4.GATEWAY", "IPv4 default gateway"),
    ("IP4.DNS", "IPv4 DNS servers"),
    ("IP4.DOMAIN", "DNS domain"),
    ("IP6.ADDRESS", "IPv6 address"),
    ("IP6.GATEWAY", "IPv6 default gateway"),
    ("IP6.DNS", "IPv6 DNS servers"),
]


def _net_unescape(v: str) -> str:
    return re.sub(r"\\(.)", r"\1", v)


def _net_kv(out: str) -> dict:
    """Parse `nmcli -t` key:value output (first occurrence of a key wins)."""
    d = {}
    for line in out.splitlines():
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        v = _net_unescape(v).strip()
        d.setdefault(k.strip(), "" if v == "--" else v)
    return d


def _net_multi(d: dict, base: str) -> list:
    """Values of indexed keys such as IP4.DNS[1], IP4.DNS[2]."""
    items = []
    for k, v in d.items():
        if k == base or k.startswith(base + "["):
            if v:
                items.append(v)
    return items


def _net_prefix_from_mask(mask: str) -> int:
    m = mask.strip().lstrip("/")
    if m.isdigit():
        n = int(m)
        if 0 <= n <= 32:
            return n
        raise ValueError
    return ipaddress.IPv4Network("0.0.0.0/" + m).prefixlen


def _net_mask_from_prefix(p: str) -> str:
    try:
        return str(ipaddress.IPv4Network("0.0.0.0/" + str(int(p))).netmask)
    except ValueError:
        return ""


def _net_is_ip(s: str, ver: int) -> bool:
    try:
        return ipaddress.ip_address(s.strip()).version == ver
    except ValueError:
        return False


class NetworkMixin:
    networkChanged = Signal()
    wifiChanged = Signal()
    wifiResult = Signal(bool, str)      # ok, message (shown to the user)
    netChanged = Signal()               # adapters / connection lists
    netResult = Signal(bool, str)       # ok, message for a toast on the current page
    netConnChanged = Signal()
    netConnLoaded = Signal(str)         # connection name whose details just loaded
    netKeyRevealed = Signal(str)        # Wi-Fi security key (empty if unavailable)
    netDeviceInfoChanged = Signal()
    hotspotChanged = Signal()
    airplaneChanged = Signal()
    proxyChanged = Signal()

    def _init_network(self):
        self._net_type, self._net_name, self._net_iface = "", "", ""
        self._wifi_on, self._wifi_list, self._wifi_iface, self._wifi_known = False, [], "", set()
        self._wifi_busy = False
        self._net_devs, self._net_conns = [], []
        self._net_known_list, self._net_vpn_list, self._net_eth_list = [], [], []
        self._net_active = []
        self._net_busy = False
        self._net_conn = {}
        self._net_devinfo = []
        # hotspot
        self._net_hotspot_on = False
        self._net_hotspot_name = ""
        self._net_hotspot_pwd = ""
        self._net_hotspot_band = int(self._settings.value("network/hotspotBand", 0) or 0)
        # airplane mode
        self._net_air = False
        self._net_bt_on, self._net_bt_avail = False, False
        # proxy
        self._net_px_type = 0
        self._net_px_script = ""
        self._net_px_host, self._net_px_port = "", ""
        self._net_px_exc = ""
        self._net_px_rev = False
        self._pollers.append(self._poll_network)

    networkType = prop("net_type", str, networkChanged)
    networkName = prop("net_name", str, networkChanged)
    networkInterface = prop("net_iface", str, networkChanged)
    wifiEnabled = prop("wifi_on", bool, wifiChanged)
    wifiNetworks = prop("wifi_list", "QVariantList", wifiChanged)
    wifiBusy = prop("wifi_busy", bool, wifiChanged)
    netBusy = prop("net_busy", bool, netChanged)
    netDevices = prop("net_devs", "QVariantList", netChanged)
    netKnownWifi = prop("net_known_list", "QVariantList", netChanged)
    netVpnList = prop("net_vpn_list", "QVariantList", netChanged)
    netEthernetList = prop("net_eth_list", "QVariantList", netChanged)
    netConn = prop("net_conn", "QVariantMap", netConnChanged)
    netDeviceInfo = prop("net_devinfo", "QVariantList", netDeviceInfoChanged)
    hotspotOn = prop("net_hotspot_on", bool, hotspotChanged)
    hotspotName = prop("net_hotspot_name", str, hotspotChanged)
    hotspotPassword = prop("net_hotspot_pwd", str, hotspotChanged)
    hotspotBand = prop("net_hotspot_band", int, hotspotChanged)
    airplaneMode = prop("net_air", bool, airplaneChanged)
    netBluetoothOn = prop("net_bt_on", bool, airplaneChanged)
    netBluetoothAvailable = prop("net_bt_avail", bool, airplaneChanged)
    proxyType = prop("net_px_type", int, proxyChanged)
    proxyScript = prop("net_px_script", str, proxyChanged)
    proxyHost = prop("net_px_host", str, proxyChanged)
    proxyPort = prop("net_px_port", str, proxyChanged)
    proxyExceptions = prop("net_px_exc", str, proxyChanged)
    proxyReversed = prop("net_px_rev", bool, proxyChanged)

    # ---------------------------------------------------- status
    def _poll_network(self):
        self._async(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"], self._on_net, timeout_ms=3000)
        self._async(["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"],
                    self._net_on_active, timeout_ms=3000)
        self._async(["kreadconfig6", "--file", "plasma-nm", "--group", "General", "--key",
                     "AirplaneModeEnabled", "--default", "false"], self._net_on_air_flag, timeout_ms=3000)

    def _on_net(self, ok: bool, out: str):
        typ, name, iface = "", "", ""
        devs = []
        for line in out.splitlines():
            f = self._nm_fields(line)
            if len(f) < 4:
                continue
            dev, dtype, state, con = f[0], f[1], f[2], f[3]
            if dtype in ("loopback", "wifi-p2p", "bridge", "tun", "veth", "dummy") or dev.startswith(("docker", "veth", "virbr")):
                continue
            devs.append({"ifname": dev, "type": dtype, "state": state, "connection": con,
                         "connected": state == "connected"})
            if not typ and state == "connected" and dtype in ("ethernet", "wifi") and con != _NET_HOTSPOT_CON:
                typ, name, iface = dtype, con, dev
        if devs != self._net_devs:
            self._net_devs = devs
            self.netChanged.emit()
        for d in devs:
            if d["type"] == "wifi" and not self._wifi_iface:
                self._wifi_iface = d["ifname"]
        if (typ, name, iface) != (self._net_type, self._net_name, self._net_iface):
            self._net_type, self._net_name, self._net_iface = typ, name, iface
            self.networkChanged.emit()

    def _net_on_active(self, ok: bool, out: str):
        active = []
        for line in out.splitlines():
            f = self._nm_fields(line)
            if len(f) >= 3:
                active.append({"name": f[0], "type": f[1], "device": f[2]})
        hot = any(a["name"] == _NET_HOTSPOT_CON for a in active)
        self._net_active = active
        if hot != self._net_hotspot_on:
            self._net_hotspot_on = hot
            self.hotspotChanged.emit()

    def _net_on_air_flag(self, ok: bool, out: str):
        on = ok and out.strip() == "true"
        if on != self._net_air:
            self._net_air = on
            self.airplaneChanged.emit()

    # ---------------------------------------------------- shared helpers
    def _net_run(self, args, ok_msg: str = "", fail_msg: str = "", timeout_ms: int = 30000, after=None):
        """Run an nmcli command asynchronously, toast the result, then call after()."""
        self._net_busy = True
        self.netChanged.emit()

        def done(ok, out):
            self._net_busy = False
            self.netChanged.emit()
            if (ok and ok_msg) or (not ok and fail_msg):
                self.netResult.emit(ok, ok_msg if ok else fail_msg)
            if after:
                after(ok, out)
            self._poll_network()

        self._async(args, done, timeout_ms)

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
                       "security": f[3] if f[3] != "--" else "", "active": f[0] == "*",
                       "known": ssid in self._wifi_known}
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
        self._wifi_connect_run(args, ssid)

    @Slot(str, str)
    def wifiConnectHidden(self, ssid: str, password: str):
        """Connect to a network that doesn't broadcast its name."""
        ssid = ssid.strip()
        if not ssid:
            self.wifiResult.emit(False, "Enter the network name.")
            return
        args = ["nmcli", "device", "wifi", "connect", ssid, "hidden", "yes"]
        if password:
            args += ["password", password]
        self._wifi_connect_run(args, ssid)

    def _wifi_connect_run(self, args, ssid: str):
        self._wifi_busy = True
        self.wifiChanged.emit()

        def done(ok, out):
            self._wifi_busy = False
            self.wifiChanged.emit()
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
        self._async(["nmcli", "connection", "delete", "id", ssid],
                    lambda *_: (self.refreshWifi(), self.refreshNetConnections()))

    # ---------------------------------------------------- connection lists (known Wi-Fi, VPN, Ethernet)
    @Slot()
    def refreshNetConnections(self):
        def got(_ok, out):
            known, vpn, eth = [], [], []
            for line in out.splitlines():
                f = self._nm_fields(line)
                if len(f) < 6:
                    continue
                c = {"name": f[0], "uuid": f[1], "type": f[2], "autoconnect": f[3] == "yes",
                     "active": f[4] == "yes", "device": f[5]}
                if c["type"] == "802-11-wireless" and c["name"] != _NET_HOTSPOT_CON:
                    known.append(c)
                elif c["type"] in ("vpn", "wireguard"):
                    vpn.append(c)
                elif c["type"] == "802-3-ethernet":
                    eth.append(c)
            self._net_known_list, self._net_vpn_list, self._net_eth_list = known, vpn, eth
            self.netChanged.emit()

        self._async(["nmcli", "-t", "-f", "NAME,UUID,TYPE,AUTOCONNECT,ACTIVE,DEVICE", "connection", "show"], got, 5000)

    # ---------------------------------------------------- per-connection properties
    @Slot(str)
    def loadNetConn(self, name: str):
        def got(ok, out):
            if not ok:
                self._net_conn = {"name": name, "loaded": False}
                self.netConnChanged.emit()
                self.netConnLoaded.emit(name)
                return
            d = _net_kv(out)
            ctype = d.get("connection.type", "")
            mac_key = "802-11-wireless.cloned-mac-address" if ctype == "802-11-wireless" \
                else "802-3-ethernet.cloned-mac-address"
            mac = d.get(mac_key, "")

            def first_addr(key):
                v = d.get(key, "").split(",")[0].strip()
                return v.split("/", 1) if v else ["", ""]

            a4 = first_addr("ipv4.addresses")
            a6 = first_addr("ipv6.addresses")
            dns4 = [x for x in re.split(r"[,\s]+", d.get("ipv4.dns", "")) if x]
            dns6 = [x for x in re.split(r"[,\s]+", d.get("ipv6.dns", "")) if x]
            self._net_conn = {
                "name": name, "loaded": True, "type": ctype,
                "ssid": d.get("802-11-wireless.ssid", ""),
                "keyMgmt": d.get("802-11-wireless-security.key-mgmt", ""),
                "autoconnect": d.get("connection.autoconnect", "") == "yes",
                "metered": d.get("connection.metered", "unknown"),
                "macMode": {"random": 1, "stable": 2}.get(mac, 0),
                "active": "activated" in d.get("GENERAL.STATE", ""),
                "device": d.get("GENERAL.DEVICES", ""),
                "v4method": d.get("ipv4.method", "auto"), "v4addr": a4[0],
                "v4mask": _net_mask_from_prefix(a4[1]) if a4[1] else "",
                "v4gw": d.get("ipv4.gateway", ""), "v4dns": dns4,
                "v4ignoreAuto": d.get("ipv4.ignore-auto-dns", "") == "yes",
                "v6method": d.get("ipv6.method", "auto"), "v6addr": a6[0],
                "v6prefix": a6[1] if a6[1:] else "",
                "v6gw": d.get("ipv6.gateway", ""), "v6dns": dns6,
                "v6ignoreAuto": d.get("ipv6.ignore-auto-dns", "") == "yes",
                "ip4": (_net_multi(d, "IP4.ADDRESS") or [""])[0].split("/")[0],
                "gw4": d.get("IP4.GATEWAY", ""),
                "dns4": ", ".join(_net_multi(d, "IP4.DNS")),
                "ip6": ", ".join(x.split("/")[0] for x in _net_multi(d, "IP6.ADDRESS")),
                "dns6": ", ".join(_net_multi(d, "IP6.DNS")),
            }
            self.netConnChanged.emit()
            self.netConnLoaded.emit(name)

        self._async(["nmcli", "-t", "connection", "show", "id", name], got, 5000)

    def _net_modify(self, name: str, pairs: list, ok_msg: str = "", reactivate: bool = False):
        args = ["nmcli", "connection", "modify", "id", name]
        for k, v in pairs:
            args += [k, v]

        def after(ok, _out):
            if ok and reactivate and self._net_conn.get("active"):
                self._net_run(["nmcli", "connection", "up", "id", name], "", "Couldn't reconnect with the new settings.",
                              60000, lambda *_: self.loadNetConn(name))
            else:
                self.loadNetConn(name)

        self._net_run(args, ok_msg, "Couldn't save the change. You may need to approve the authorization prompt.",
                      20000, after)

    @Slot(str, bool)
    def netSetAutoconnect(self, name: str, on: bool):
        self._net_conn = {**self._net_conn, "autoconnect": on}
        self.netConnChanged.emit()
        self._net_modify(name, [("connection.autoconnect", "yes" if on else "no")])

    @Slot(str, bool)
    def netSetMetered(self, name: str, on: bool):
        self._net_conn = {**self._net_conn, "metered": "yes" if on else "unknown"}
        self.netConnChanged.emit()
        self._net_modify(name, [("connection.metered", "yes" if on else "unknown")])

    @Slot(str, int)
    def netSetMacMode(self, name: str, idx: int):
        """0 = Off (permanent hardware address), 1 = On (random each connection), 2 = fixed random per network."""
        self._net_conn = {**self._net_conn, "macMode": idx}
        self.netConnChanged.emit()
        mode = ["permanent", "random", "stable"][max(0, min(2, idx))]
        self._net_modify(name, [("802-11-wireless.cloned-mac-address", mode)],
                         "Applies the next time you connect to this network.")

    @Slot(str)
    def netForget(self, name: str):
        self._net_run(["nmcli", "connection", "delete", "id", name], f"Forgot {name}", f"Couldn't remove {name}.",
                      15000, lambda *_: (self.refreshNetConnections(), self.refreshWifi()))

    @Slot(str)
    def netRevealKey(self, name: str):
        def got(ok, out):
            self.netKeyRevealed.emit(out.strip() if ok else "")

        self._async(["nmcli", "--show-secrets", "-g", "802-11-wireless-security.psk",
                     "connection", "show", "id", name], got, 8000)

    @Slot(str)
    def netConnect(self, name: str):
        self._net_run(["nmcli", "connection", "up", "id", name], f"Connected to {name}",
                      f"Couldn't connect to {name}.", 60000,
                      lambda *_: (self.refreshNetConnections(), self.loadNetConn(name)))

    @Slot(str)
    def netDisconnect(self, name: str):
        self._net_run(["nmcli", "connection", "down", "id", name], f"Disconnected from {name}", "",
                      20000, lambda *_: (self.refreshNetConnections(), self.loadNetConn(name)))

    # ---------------------------------------------------- IP / DNS editing (validated before nmcli)
    @Slot(bool, str, str, str, bool, str, str, str, result=str)
    def netValidateManualIp(self, v4on, v4addr, v4mask, v4gw, v6on, v6addr, v6prefix, v6gw):
        if not v4on and not v6on:
            return "Turn on IPv4 or IPv6."
        if v4on:
            if not _net_is_ip(v4addr, 4):
                return "Enter a valid IPv4 address, like 192.168.1.50."
            try:
                _net_prefix_from_mask(v4mask)
            except ValueError:
                return "Enter a valid subnet mask, like 255.255.255.0 (or a prefix length, like 24)."
            if v4gw.strip() and not _net_is_ip(v4gw, 4):
                return "Enter a valid IPv4 gateway address."
        if v6on:
            if not _net_is_ip(v6addr, 6):
                return "Enter a valid IPv6 address."
            p = v6prefix.strip()
            if not p.isdigit() or not 1 <= int(p) <= 128:
                return "The IPv6 subnet prefix length must be between 1 and 128."
            if v6gw.strip() and not _net_is_ip(v6gw, 6):
                return "Enter a valid IPv6 gateway address."
        return ""

    @Slot(str, bool, str, str, str, bool, str, str, str)
    def netApplyManualIp(self, name, v4on, v4addr, v4mask, v4gw, v6on, v6addr, v6prefix, v6gw):
        if self.netValidateManualIp(v4on, v4addr, v4mask, v4gw, v6on, v6addr, v6prefix, v6gw):
            return
        pairs = []
        if v4on:
            pairs += [("ipv4.method", "manual"),
                      ("ipv4.addresses", f"{v4addr.strip()}/{_net_prefix_from_mask(v4mask)}"),
                      ("ipv4.gateway", v4gw.strip())]
        else:
            pairs += [("ipv4.method", "disabled"), ("ipv4.addresses", ""), ("ipv4.gateway", "")]
        if v6on:
            pairs += [("ipv6.method", "manual"),
                      ("ipv6.addresses", f"{v6addr.strip()}/{int(v6prefix)}"),
                      ("ipv6.gateway", v6gw.strip())]
        else:
            pairs += [("ipv6.method", "disabled"), ("ipv6.addresses", ""), ("ipv6.gateway", "")]
        self._net_modify(name, pairs, "IP settings saved.", reactivate=True)

    @Slot(str)
    def netApplyAutoIp(self, name: str):
        self._net_modify(name, [("ipv4.method", "auto"), ("ipv4.addresses", ""), ("ipv4.gateway", ""),
                                ("ipv6.method", "auto"), ("ipv6.addresses", ""), ("ipv6.gateway", "")],
                         "IP settings saved.", reactivate=True)

    @Slot(str, str, str, str, result=str)
    def netValidateDns(self, v4a, v4b, v6a, v6b):
        if not any(s.strip() for s in (v4a, v4b, v6a, v6b)):
            return "Enter at least one DNS server."
        for s in (v4a, v4b):
            if s.strip() and not _net_is_ip(s, 4):
                return "Enter valid IPv4 addresses for the DNS servers."
        for s in (v6a, v6b):
            if s.strip() and not _net_is_ip(s, 6):
                return "Enter valid IPv6 addresses for the DNS servers."
        if v4b.strip() and not v4a.strip():
            return "Fill in the preferred IPv4 DNS server first."
        if v6b.strip() and not v6a.strip():
            return "Fill in the preferred IPv6 DNS server first."
        return ""

    @Slot(str, str, str, str, str)
    def netApplyManualDns(self, name, v4a, v4b, v6a, v6b):
        if self.netValidateDns(v4a, v4b, v6a, v6b):
            return
        v4 = " ".join(s.strip() for s in (v4a, v4b) if s.strip())
        v6 = " ".join(s.strip() for s in (v6a, v6b) if s.strip())
        self._net_modify(name, [("ipv4.dns", v4), ("ipv4.ignore-auto-dns", "yes" if v4 else "no"),
                                ("ipv6.dns", v6), ("ipv6.ignore-auto-dns", "yes" if v6 else "no")],
                         "DNS settings saved.", reactivate=True)

    @Slot(str)
    def netApplyAutoDns(self, name: str):
        self._net_modify(name, [("ipv4.dns", ""), ("ipv4.ignore-auto-dns", "no"),
                                ("ipv6.dns", ""), ("ipv6.ignore-auto-dns", "no")],
                         "DNS settings saved.", reactivate=True)

    # ---------------------------------------------------- adapters & hardware properties
    @Slot()
    def refreshNetDevices(self):
        self._poll_network()

    @Slot(str, bool)
    def netSetDeviceEnabled(self, ifname: str, on: bool):
        if on:
            def step2(*_):
                self._net_run(["nmcli", "device", "connect", ifname], "", "", 45000, lambda *_: self._poll_network())
            self._net_run(["nmcli", "device", "set", ifname, "autoconnect", "yes"], "", "", 10000, step2)
        else:
            def step2(*_):
                self._net_run(["nmcli", "device", "disconnect", ifname], "", "", 20000, lambda *_: self._poll_network())
            self._net_run(["nmcli", "device", "set", ifname, "autoconnect", "no"], "", "", 10000, step2)

    @Slot(str)
    def loadNetDeviceInfo(self, ifname: str):
        """Hardware & connection properties. ifname '' = every adapter."""
        def got(ok, out):
            blocks, cur = [], {}
            for line in out.splitlines() + [""]:
                if not line.strip():
                    if cur:
                        blocks.append(cur)
                        cur = {}
                    continue
                if ":" in line:
                    k, v = line.split(":", 1)
                    v = _net_unescape(v).strip()
                    cur[k.strip()] = "" if v == "--" else v
            devices = []
            for b in blocks:
                typ = b.get("GENERAL.TYPE", "")
                if typ in ("loopback", "wifi-p2p", "bridge", "tun", "veth", "dummy"):
                    continue
                rows = []
                for base, label in _NET_DEV_LABELS:
                    vals = _net_multi(b, base)
                    if vals:
                        rows.append({"label": label, "value": ", ".join(vals)})
                devices.append({"ifname": b.get("GENERAL.DEVICE", ""), "type": typ, "rows": rows})
            self._net_devinfo = devices
            self.netDeviceInfoChanged.emit()
            for d in devices:
                if d["type"] == "wifi":
                    self._net_load_wifi_link(d["ifname"])

        args = ["nmcli", "-t", "device", "show"] + ([ifname] if ifname else [])
        self._async(args, got, 6000)

    def _net_load_wifi_link(self, ifname: str):
        def got(ok, out):
            for line in out.splitlines():
                f = self._nm_fields(line)
                if len(f) >= 7 and f[0] == "*":
                    try:
                        mhz = int(f[3].split()[0])
                    except (ValueError, IndexError):
                        mhz = 0
                    band = "" if not mhz else "2.4 GHz" if mhz < 3000 else "5 GHz" if mhz < 5900 else "6 GHz"
                    extra = [("Network name (SSID)", f[1]), ("Network band", band), ("Network channel", f[2]),
                             ("Link speed", f[4]), ("Signal strength", f[5] + "%" if f[5] else ""),
                             ("Security type", f[6])]
                    new = []
                    for d in self._net_devinfo:
                        if d["ifname"] == ifname:
                            d = {**d, "rows": [{"label": a, "value": b} for a, b in extra if b] + d["rows"]}
                        new.append(d)
                    self._net_devinfo = new
                    self.netDeviceInfoChanged.emit()
                    break

        self._async(["nmcli", "-t", "-f", "IN-USE,SSID,CHAN,FREQ,RATE,SIGNAL,SECURITY", "device", "wifi", "list",
                     "ifname", ifname, "--rescan", "no"], got, 8000)

    # ---------------------------------------------------- VPN
    @Slot(str)
    def vpnConnect(self, name: str):
        self.netConnect(name)

    @Slot(str)
    def vpnDisconnect(self, name: str):
        self.netDisconnect(name)

    @Slot(str)
    def vpnRemove(self, name: str):
        self.netForget(name)

    @Slot(str, result=str)
    def netValidateVpnFile(self, path: str):
        p = os.path.expanduser(path.strip())
        if not p:
            return "Enter the path to a VPN configuration file."
        if not os.path.isfile(p):
            return "That file doesn't exist."
        if not p.lower().endswith((".ovpn", ".conf")):
            return "Use an OpenVPN (.ovpn) or WireGuard (.conf) file."
        return ""

    @Slot(str)
    def vpnImport(self, path: str):
        err = self.netValidateVpnFile(path)
        if err:
            self.netResult.emit(False, err)
            return
        p = os.path.expanduser(path.strip())
        vtype = "openvpn" if p.lower().endswith(".ovpn") else "wireguard"
        self._net_run(["nmcli", "connection", "import", "type", vtype, "file", p], "VPN added.",
                      "Couldn't import the VPN. For OpenVPN, the NetworkManager OpenVPN plugin must be installed.",
                      30000, lambda *_: self.refreshNetConnections())

    # ---------------------------------------------------- mobile hotspot
    @Slot()
    def refreshHotspot(self):
        name = kread("plasma-nm", "General", "HotspotName", "") or f"{getpass.getuser()}-hotspot"
        pwd = kread("plasma-nm", "General", "HotspotPassword", "")
        if not pwd:
            pwd = "".join(random.choice(string.ascii_letters + string.digits) for _ in range(12))
            if has("kwriteconfig6"):
                kwrite("plasma-nm", "General", "HotspotPassword", pwd)
        self._net_hotspot_name, self._net_hotspot_pwd = name, pwd
        self.hotspotChanged.emit()
        self._poll_network()

    @Slot(str, str, result=str)
    def netValidateHotspot(self, name: str, pwd: str):
        if not name.strip():
            return "Enter a network name."
        if len(name.encode()) > 32:
            return "The network name can be at most 32 characters."
        if not 8 <= len(pwd) <= 63:
            return "The network password must be 8 to 63 characters."
        return ""

    def _net_hotspot_start(self):
        iface = self._wifi_iface
        if not iface:
            self.netResult.emit(False, "No Wi-Fi adapter found.")
            self._net_hotspot_on = False
            self.hotspotChanged.emit()
            return
        args = ["nmcli", "device", "wifi", "hotspot", "ifname", iface, "con-name", _NET_HOTSPOT_CON,
                "ssid", self._net_hotspot_name, "password", self._net_hotspot_pwd]
        if self._net_hotspot_band in (1, 2):
            args += ["band", "a" if self._net_hotspot_band == 1 else "bg"]

        def after(ok, _out):
            self._net_hotspot_on = ok
            self.hotspotChanged.emit()

        self._net_run(args, "Mobile hotspot is on.", "Couldn't turn on the mobile hotspot.", 45000, after)

    @Slot(bool)
    def setHotspot(self, on: bool):
        self._net_hotspot_on = on
        self.hotspotChanged.emit()
        if on:
            if self.netValidateHotspot(self._net_hotspot_name, self._net_hotspot_pwd):
                self._net_hotspot_on = False
                self.hotspotChanged.emit()
                self.netResult.emit(False, "Check the hotspot name and password in Properties.")
                return
            self._net_hotspot_start()
        else:
            self._net_run(["nmcli", "connection", "down", "id", _NET_HOTSPOT_CON], "", "", 20000,
                          lambda *_: self.refreshNetConnections())

    @Slot(str, str, int)
    def applyHotspotProperties(self, name: str, pwd: str, band: int):
        if self.netValidateHotspot(name, pwd):
            return
        self._net_hotspot_name, self._net_hotspot_pwd, self._net_hotspot_band = name.strip(), pwd, band
        kwrite("plasma-nm", "General", "HotspotName", self._net_hotspot_name)
        kwrite("plasma-nm", "General", "HotspotPassword", pwd)
        self._settings.setValue("network/hotspotBand", band)
        self.hotspotChanged.emit()
        if self._net_hotspot_on:
            self._net_run(["nmcli", "connection", "down", "id", _NET_HOTSPOT_CON], "", "", 20000,
                          lambda *_: self._net_hotspot_start())

    # ---------------------------------------------------- airplane mode
    @Slot()
    def refreshAirplane(self):
        def got_bt(ok, out):
            avail = ok and "Powered:" in out
            on = avail and re.search(r"Powered:\s*yes", out) is not None
            if (avail, on) != (self._net_bt_avail, self._net_bt_on):
                self._net_bt_avail, self._net_bt_on = avail, on
                self.airplaneChanged.emit()

        self._async(["bluetoothctl", "show"], got_bt, 3000)
        self.refreshWifi()
        self._poll_network()

    @Slot(bool)
    def setAirplaneMode(self, on: bool):
        """Same procedure as plasma-nm's Handler::enableAirplaneMode (SRC libs/handler.cpp)."""
        self._net_air = on
        self.airplaneChanged.emit()
        kwrite("plasma-nm", "General", "AirplaneModeEnabled", "true" if on else "false", "bool")
        if on:
            self._settings.setValue("network/airplaneWifi", self._wifi_on)
            self._settings.setValue("network/airplaneBt", self._net_bt_on)
            self._wifi_on = False
            self._net_bt_on = False
            self.wifiChanged.emit()
            self.airplaneChanged.emit()
            self._async(["nmcli", "radio", "wifi", "off"], None, 8000)
            self._async(["nmcli", "radio", "wwan", "off"], None, 8000)
            self._async(["bluetoothctl", "power", "off"], None, 8000)
        else:
            wifi_was = str(self._settings.value("network/airplaneWifi", True)).lower() in ("true", "1")
            self._async(["bluetoothctl", "power", "on"], None, 8000)
            if wifi_was:
                self._wifi_on = True
                self.wifiChanged.emit()
                self._async(["nmcli", "radio", "wifi", "on"], None, 8000)
            self._async(["nmcli", "radio", "wwan", "on"], None, 8000)
        QTimer.singleShot(1800, self.refreshAirplane)

    @Slot(bool)
    def netSetBluetooth(self, on: bool):
        self._net_bt_on = on
        self.airplaneChanged.emit()
        self._async(["bluetoothctl", "power", "on" if on else "off"], lambda *_: self.refreshAirplane(), 8000)

    # ---------------------------------------------------- proxy (kioslaverc)
    @Slot()
    def refreshProxy(self):
        g = _NET_PROXY_GROUP

        def rd(key, default=""):
            return kread(_NET_PROXY_FILE, g, key, default)

        try:
            self._net_px_type = int(rd("ProxyType", "0") or 0)
        except ValueError:
            self._net_px_type = 0
        self._net_px_script = rd("Proxy Config Script")
        raw = rd("httpProxy") or rd("httpsProxy")
        raw = re.sub(r"^\w+://", "", raw.strip())
        host, port = raw, ""
        if " " in raw:
            host, port = raw.split(None, 1)
        elif raw.count(":") == 1:
            h, p = raw.split(":")
            if p.isdigit():
                host, port = h, p
        self._net_px_host, self._net_px_port = host, port.strip()
        self._net_px_exc = rd("NoProxyFor")
        self._net_px_rev = rd("ReversedException", "false").lower() == "true"
        self.proxyChanged.emit()

    def _net_px_write(self, **kv):
        for key, (val, kind) in kv.items():
            kwrite(_NET_PROXY_FILE, _NET_PROXY_GROUP, key.replace("_", " "), val, kind)
        # tell running KIO workers to re-read kioslaverc (SRC kio-extras kcms/proxy/ksaveioconfig.cpp)
        spawn(["dbus-send", "--session", "--type=signal", "/KIO/Scheduler",
               "org.kde.KIO.Scheduler.reparseSlaveConfiguration", "string:"])
        self.refreshProxy()

    @Slot(bool)
    def setProxyAuto(self, on: bool):
        """Automatically detect settings (WPAD) -> ProxyType 3."""
        self._net_px_type = 3 if on else (0 if self._net_px_type == 3 else self._net_px_type)
        self.proxyChanged.emit()
        self._net_px_write(ProxyType=(str(self._net_px_type), "int"))

    @Slot(bool)
    def setProxyScriptEnabled(self, on: bool):
        self._net_px_type = 2 if on else (0 if self._net_px_type == 2 else self._net_px_type)
        self.proxyChanged.emit()
        self._net_px_write(ProxyType=(str(self._net_px_type), "int"))

    @Slot(bool)
    def setProxyManualEnabled(self, on: bool):
        self._net_px_type = 1 if on else (0 if self._net_px_type == 1 else self._net_px_type)
        self.proxyChanged.emit()
        self._net_px_write(ProxyType=(str(self._net_px_type), "int"))

    @Slot(str, result=str)
    def netValidateProxyScript(self, url: str):
        u = url.strip()
        if not re.match(r"^(https?|file|ftp)://\S+$", u):
            return "Enter a script address like http://example.com/proxy.pac"
        return ""

    @Slot(str)
    def applyProxyScript(self, url: str):
        if self.netValidateProxyScript(url):
            return
        self._net_px_write(Proxy_Config_Script=(url.strip(), None), ProxyType=("2", "int"))

    @Slot(str, str, result=str)
    def netValidateProxyManual(self, host: str, port: str):
        h = host.strip()
        if not h or not re.match(r"^[A-Za-z0-9._\-\[\]:]+$", h):
            return "Enter a valid proxy address, like proxy.example.com."
        if not port.strip().isdigit() or not 1 <= int(port) <= 65535:
            return "The port must be a number from 1 to 65535."
        return ""

    @Slot(str, str, str, bool)
    def applyProxyManual(self, host: str, port: str, exceptions: str, reversed_: bool):
        if self.netValidateProxyManual(host, port):
            return
        val = f"{host.strip()} {int(port)}"
        exc = ",".join(x.strip() for x in re.split(r"[;,]", exceptions) if x.strip())
        self._net_px_write(httpProxy=(val, None), httpsProxy=(val, None), ftpProxy=(val, None),
                           NoProxyFor=(exc, None),
                           ReversedException=("true" if reversed_ and exc else "false", "bool"),
                           ProxyType=("1", "int"))

    # ---------------------------------------------------- network reset
    @Slot()
    def netReset(self):
        """Turn networking off and on again (restarts every connection)."""
        def off_done(ok, _out):
            self._async(["nmcli", "networking", "on"],
                        lambda ok2, _o: (self.netResult.emit(ok2, "Network reset." if ok2 else "Couldn't turn networking back on."),
                                         self._poll_network(), self.refreshWifi()), 20000)

        self._async(["nmcli", "networking", "off"], off_done, 20000)
