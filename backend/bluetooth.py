"""Bluetooth & devices: Bluetooth (bluetoothctl), printers (CUPS), mobile devices
(KDE Connect), cameras (sysfs), mouse / touchpad / pen (KWin InputDevice D-Bus),
AutoPlay (kded device automounter) and USB4 (bolt).

Private names are prefixed `_bt_`; public names are specific to this section
because every mixin shares one QObject namespace."""
from __future__ import annotations

import json
import os
import re
from pathlib import Path
from urllib.parse import unquote

from PySide6.QtCore import QProcess, QTimer, Signal, Slot

from .util import has, kread, kwin_reconfigure, kwrite, prop, spawn

# ---------------------------------------------------------------- constants
_BT_KWIN = "org.kde.KWin"
_BT_DEV_PATH = "/org/kde/KWin/InputDevice"          # manager AND device parent path
_BT_DEV_IFACE = "org.kde.KWin.InputDevice"

# D-Bus signature of every writable InputDevice property we set (SRC kwin device.h)
_BT_PROP_TYPES = {
    "leftHanded": "b", "enabled": "b", "pointerAcceleration": "d",
    "pointerAccelerationProfileAdaptive": "b", "pointerAccelerationProfileFlat": "b",
    "scrollFactor": "d", "naturalScroll": "b", "disableEventsOnExternalMouse": "b",
    "disableWhileTyping": "b", "tapToClick": "b", "lmrTapButtonMap": "b", "tapAndDrag": "b",
    "tapDragLock": "b", "clickMethodAreas": "b", "clickMethodClickfinger": "b",
    "scrollTwoFinger": "b", "scrollEdge": "b", "middleEmulation": "b",
    "outputName": "s", "mapToWorkspace": "b", "rotation": "u",
    "pressureRangeMin": "d", "pressureRangeMax": "d", "pressureCurve": "s",
}

# touchpad property -> the read-only property holding its default (SRC kwin device.h)
_BT_TOUCHPAD_DEFAULTS = {
    "enabled": "enabledByDefault",
    "disableEventsOnExternalMouse": "disableEventsOnExternalMouseEnabledByDefault",
    "disableWhileTyping": "disableWhileTypingEnabledByDefault",
    "pointerAcceleration": "defaultPointerAcceleration",
    "pointerAccelerationProfileFlat": "defaultPointerAccelerationProfileFlat",
    "pointerAccelerationProfileAdaptive": "defaultPointerAccelerationProfileAdaptive",
    "tapToClick": "tapToClickEnabledByDefault",
    "lmrTapButtonMap": "lmrTapButtonMapEnabledByDefault",
    "tapAndDrag": "tapAndDragEnabledByDefault",
    "tapDragLock": "tapDragLockEnabledByDefault",
    "naturalScroll": "naturalScrollEnabledByDefault",
    "scrollTwoFinger": "scrollTwoFingerEnabledByDefault",
    "scrollEdge": "scrollEdgeEnabledByDefault",
    "clickMethodAreas": "defaultClickMethodAreas",
    "clickMethodClickfinger": "defaultClickMethodClickfinger",
    "middleEmulation": "middleEmulationEnabledByDefault",
}

_BT_KDE_LOCALE = ["env", "LC_ALL=C", "LANGUAGE=en_US"]   # parse English tool output


def _bt_strings(node) -> list:
    """Every string inside a busctl --json value (array replies nest in `data`)."""
    if isinstance(node, str):
        return [node]
    if isinstance(node, list):
        return [s for n in node for s in _bt_strings(n)]
    if isinstance(node, dict):
        return _bt_strings(node.get("data", []))
    return []


def _bt_json_props(out: str) -> dict:
    """busctl --json=short call ... GetAll -> {name: value}."""
    try:
        data = json.loads(out)["data"][0]
        return {k: v["data"] for k, v in data.items()}
    except (ValueError, KeyError, IndexError, TypeError, AttributeError):
        return {}


class BluetoothMixin:
    bluetoothChanged = Signal()
    bluetoothDevicesChanged = Signal()
    bluetoothScanChanged = Signal()
    bluetoothPairChanged = Signal()
    bluetoothSettingsChanged = Signal()
    inputDevicesChanged = Signal()
    inputSettingsChanged = Signal()
    printersChanged = Signal()
    printerAddChanged = Signal()
    printJobsChanged = Signal()
    mobileDevicesChanged = Signal()
    camerasChanged = Signal()
    autoplayChanged = Signal()
    thunderboltChanged = Signal()

    def _init_bluetooth(self):
        self._bt_on, self._bt_avail, self._bt_disc = False, False, False
        self._bt_devices = []
        self._bt_info_cache = {}              # mac -> {"icon": str, "battery": int}
        self._bt_launch = 0
        # add device flow
        self._bt_scan_proc = None
        self._bt_scanning = False
        self._bt_found = []
        self._bt_pair_state, self._bt_pair_name, self._bt_pair_msg = "", "", ""
        self._bt_pair_gen = 0
        self._bt_scan_timer = QTimer(self, interval=2000)
        self._bt_scan_timer.timeout.connect(self._bt_scan_tick)
        # input devices
        self._bt_mouse, self._bt_touchpad, self._bt_pen = [], [], []
        self._bt_dbl_click, self._bt_wheel_inactive = 400, False
        self._bt_input_loading = False
        # printers
        self._bt_printers, self._bt_default_printer = [], ""
        self._bt_printers_ready = False
        self._bt_prn_found, self._bt_prn_searching = [], False
        self._bt_prn_add_state, self._bt_prn_add_msg = "", ""
        self._bt_jobs = []
        # mobile devices
        self._bt_mobile, self._bt_mobile_avail, self._bt_mobile_busy = [], has("kdeconnect-cli"), False
        # cameras, autoplay, usb4
        self._bt_cams = []
        self._bt_autoplay = False
        self._bt_tb, self._bt_tb_avail = [], False
        self._pollers.append(self._poll_bluetooth)

    bluetoothOn = prop("bt_on", bool, bluetoothChanged)
    bluetoothAvailable = prop("bt_avail", bool, bluetoothChanged)
    bluetoothDiscoverable = prop("bt_disc", bool, bluetoothChanged)
    bluetoothDevices = prop("bt_devices", "QVariantList", bluetoothDevicesChanged)
    bluetoothLaunchState = prop("bt_launch", int, bluetoothSettingsChanged)
    bluetoothScanning = prop("bt_scanning", bool, bluetoothScanChanged)
    bluetoothFound = prop("bt_found", "QVariantList", bluetoothScanChanged)
    bluetoothPairState = prop("bt_pair_state", str, bluetoothPairChanged)
    bluetoothPairName = prop("bt_pair_name", str, bluetoothPairChanged)
    bluetoothPairMessage = prop("bt_pair_msg", str, bluetoothPairChanged)
    mouseDevices = prop("bt_mouse", "QVariantList", inputDevicesChanged)
    touchpadDevices = prop("bt_touchpad", "QVariantList", inputDevicesChanged)
    penDevices = prop("bt_pen", "QVariantList", inputDevicesChanged)
    inputDevicesLoading = prop("bt_input_loading", bool, inputDevicesChanged)
    mouseDoubleClickInterval = prop("bt_dbl_click", int, inputSettingsChanged)
    mouseScrollInactiveWindows = prop("bt_wheel_inactive", bool, inputSettingsChanged)
    printers = prop("bt_printers", "QVariantList", printersChanged)
    defaultPrinter = prop("bt_default_printer", str, printersChanged)
    printersLoaded = prop("bt_printers_ready", bool, printersChanged)
    printersFound = prop("bt_prn_found", "QVariantList", printerAddChanged)
    printersSearching = prop("bt_prn_searching", bool, printerAddChanged)
    printerAddState = prop("bt_prn_add_state", str, printerAddChanged)
    printerAddMessage = prop("bt_prn_add_msg", str, printerAddChanged)
    printJobs = prop("bt_jobs", "QVariantList", printJobsChanged)
    mobileDevices = prop("bt_mobile", "QVariantList", mobileDevicesChanged)
    mobileAvailable = prop("bt_mobile_avail", bool, mobileDevicesChanged)
    mobileBusy = prop("bt_mobile_busy", bool, mobileDevicesChanged)
    cameras = prop("bt_cams", "QVariantList", camerasChanged)
    autoplayEnabled = prop("bt_autoplay", bool, autoplayChanged)
    thunderboltDevices = prop("bt_tb", "QVariantList", thunderboltChanged)
    thunderboltAvailable = prop("bt_tb_avail", bool, thunderboltChanged)

    # ================================================================ adapter
    def _poll_bluetooth(self):
        self._async(["bluetoothctl", "show"], self._on_bt, timeout_ms=3000)

    def _on_bt(self, ok: bool, out: str):
        avail = ok and "Controller" in out
        on = avail and re.search(r"Powered:\s*yes", out) is not None
        disc = on and re.search(r"Discoverable:\s*yes", out) is not None
        if (avail, on, disc) != (self._bt_avail, self._bt_on, self._bt_disc):
            self._bt_avail, self._bt_on, self._bt_disc = avail, on, disc
            self.bluetoothChanged.emit()

    @Slot(bool)
    def setBluetooth(self, on: bool):
        self._bt_on = on
        if not on:
            self._bt_disc = False
            self.stopBluetoothScan()
        self.bluetoothChanged.emit()
        self._async(["bluetoothctl", "power", "on" if on else "off"], lambda *_: self._poll_bluetooth())

    @Slot(bool)
    def setBluetoothDiscoverable(self, on: bool):
        self._bt_disc = on
        self.bluetoothChanged.emit()
        self._async(["bluetoothctl", "discoverable", "on" if on else "off"], lambda *_: self._poll_bluetooth())

    @Slot()
    def refreshBluetoothSettings(self):
        """Bluetooth state at login (bluedevilglobalrc [General] launchState)."""
        state = kread("bluedevilglobalrc", "General", "launchState", "Remember")
        idx = {"Remember": 0, "Enable": 1, "Disable": 2}.get(state, 0)
        if idx != self._bt_launch:
            self._bt_launch = idx
            self.bluetoothSettingsChanged.emit()

    @Slot(int)
    def setBluetoothLaunchState(self, idx: int):
        if idx not in (0, 1, 2):
            return
        self._bt_launch = idx
        self.bluetoothSettingsChanged.emit()
        kwrite("bluedevilglobalrc", "General", "launchState", ("Remember", "Enable", "Disable")[idx])

    # ================================================================ paired devices
    @staticmethod
    def _parse_bt(out: str) -> list:
        res = []
        for line in out.splitlines():
            m = re.match(r"Device\s+([0-9A-F:]{17})\s+(.*)", line.strip())
            if m:
                res.append((m.group(1), m.group(2).strip()))
        return res

    @staticmethod
    def _bt_display_name(mac: str, name: str) -> str:
        return "Unknown device" if not name or name == mac.replace(":", "-") else name

    def _bt_decorate(self, mac: str, name: str, connected: bool) -> dict:
        info = self._bt_info_cache.get(mac, {})
        icon = info.get("icon", "")
        kind = ("input" if icon in ("input-keyboard", "input-mouse", "input-tablet")
                else "audio" if icon.startswith("audio-") else "other")
        return {"mac": mac, "name": self._bt_display_name(mac, name), "connected": connected,
                "icon": icon, "kind": kind, "battery": info.get("battery", -1)}

    @Slot()
    def refreshBluetoothDevices(self):
        def got_paired(_ok, out):
            paired = self._parse_bt(out)

            def got_connected(_ok2, out2):
                conn = {mac for mac, _ in self._parse_bt(out2)}
                ordered = sorted(paired, key=lambda d: (d[0] not in conn, d[1].lower()))
                self._bt_devices = [self._bt_decorate(m, n, m in conn) for m, n in ordered]
                self.bluetoothDevicesChanged.emit()
                for mac, _n in ordered:
                    if mac in conn or mac not in self._bt_info_cache:
                        self._bt_fetch_info(mac)

            self._async(["bluetoothctl", "devices", "Connected"], got_connected, 4000)

        self._async(["bluetoothctl", "devices", "Paired"], got_paired, 4000)

    def _bt_fetch_info(self, mac: str):
        """Icon + battery from `bluetoothctl info` (format: SRC bluez client/main.c)."""
        def got(ok, out):
            if not ok:
                self._bt_info_cache.setdefault(mac, {"icon": "", "battery": -1})
                return
            icon = re.search(r"^\s*Icon:\s*(\S+)", out, re.M)
            bat = re.search(r"Battery Percentage:\s*0x[0-9a-fA-F]+\s*\((\d+)\)", out)
            new = {"icon": icon.group(1) if icon else "", "battery": int(bat.group(1)) if bat else -1}
            if self._bt_info_cache.get(mac) == new:
                return
            self._bt_info_cache[mac] = new
            self._bt_devices = [self._bt_decorate(d["mac"], d["name"], d["connected"]) if d["mac"] == mac else d
                                for d in self._bt_devices]
            self.bluetoothDevicesChanged.emit()
            self._bt_found = [dict(d, icon=new["icon"]) if d["mac"] == mac else d for d in self._bt_found]
            self.bluetoothScanChanged.emit()

        self._async(["bluetoothctl", "info", mac], got, 4000)

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
        self._bt_devices = [d for d in self._bt_devices if d["mac"] != mac]
        self.bluetoothDevicesChanged.emit()
        self._bt_action("remove", mac)

    @Slot()
    def bluetoothSendFiles(self):
        spawn(["bluedevil-sendfile"])

    # ================================================================ add device: scan -> pair -> trust -> connect
    @Slot()
    def startBluetoothScan(self):
        if self._bt_scan_proc is not None or not has("bluetoothctl") or not self._bt_on:
            return
        p = QProcess(self)
        p.finished.connect(self._bt_scan_finished)
        p.errorOccurred.connect(lambda *_: self._bt_scan_finished())
        self._bt_scan_proc = p
        p.start("bluetoothctl", ["--timeout", "90", "scan", "on"])
        self._bt_found = []
        self._bt_scanning = True
        self.bluetoothScanChanged.emit()
        self._bt_scan_timer.start()
        self._bt_scan_tick()

    def _bt_scan_finished(self, *_):
        try:
            self._bt_scan_timer.stop()
        except RuntimeError:        # app is closing
            return
        p, self._bt_scan_proc = self._bt_scan_proc, None
        if p is not None:
            try:
                p.deleteLater()
            except RuntimeError:
                pass
        if self._bt_scanning:
            self._bt_scanning = False
            self.bluetoothScanChanged.emit()

    @Slot()
    def stopBluetoothScan(self):
        p = self._bt_scan_proc
        if p is not None:
            try:
                p.terminate()
                QTimer.singleShot(1500, lambda: p.kill() if p.state() != QProcess.ProcessState.NotRunning else None)
            except RuntimeError:
                pass
        self._bt_scan_finished()

    def _bt_scan_tick(self):
        if self._bt_scan_proc is None:
            return

        def got_all(_ok, out_all):
            def got_paired(_ok2, out_paired):
                if self._bt_scan_proc is None:
                    return
                paired = {m for m, _ in self._parse_bt(out_paired)}
                found = []
                for mac, name in self._parse_bt(out_all):
                    if mac in paired:
                        continue
                    found.append({"mac": mac, "name": self._bt_display_name(mac, name),
                                  "icon": self._bt_info_cache.get(mac, {}).get("icon", "")})
                    if mac not in self._bt_info_cache:
                        self._bt_fetch_info(mac)
                found.sort(key=lambda d: (d["name"] == "Unknown device", d["name"].lower()))
                if found != self._bt_found:
                    self._bt_found = found
                    self.bluetoothScanChanged.emit()

            self._async(["bluetoothctl", "devices", "Paired"], got_paired, 4000)

        self._async(["bluetoothctl", "devices"], got_all, 4000)

    def _bt_set_pair(self, state: str, name: str = "", msg: str = ""):
        self._bt_pair_state, self._bt_pair_name, self._bt_pair_msg = state, name, msg
        self.bluetoothPairChanged.emit()

    @Slot(str, str)
    def pairBluetoothDevice(self, mac: str, name: str):
        """pair -> trust -> connect, each step async. Confirmation prompts (PIN/passkey)
        are answered by the desktop's Bluetooth agent (bluedevil)."""
        self._bt_pair_gen += 1
        gen = self._bt_pair_gen
        self._bt_set_pair("pairing", name)

        def alive():
            return gen == self._bt_pair_gen

        def failed(msg):
            if alive():
                self._bt_set_pair("failed", name, msg)

        def connected(ok, out):
            if not alive():
                return
            if ok and "Failed" not in out:
                self._bt_set_pair("done", name, "Your device is ready to use")
            else:
                self._bt_set_pair("done", name, "Paired, but it couldn't connect yet. Turn the device on and connect it from the list.")
            self.refreshBluetoothDevices()

        def trusted(_ok, _out):
            if not alive():
                return
            self._bt_set_pair("connecting", name)
            self._async(["bluetoothctl", "connect", mac], connected, 30000)

        def paired(ok, out):
            if not alive():
                return
            if not ok or ("Failed" in out and "already" not in out):
                reason = re.search(r"Failed to pair:\s*(\S+)", out)
                failed("Couldn't pair. " + ("Pairing was cancelled." if reason and "Cancel" in reason.group(1)
                                           else "Make sure the device is in pairing mode and try again."))
                return
            self._async(["bluetoothctl", "trust", mac], trusted, 8000)

        self._async(["bluetoothctl", "pair", mac], paired, 60000)

    @Slot(str)
    def cancelBluetoothPairing(self, mac: str):
        self._bt_pair_gen += 1
        self._bt_set_pair("")
        if mac:
            self._async(["bluetoothctl", "cancel-pairing", mac], None, 5000)

    @Slot()
    def resetBluetoothPairState(self):
        self._bt_pair_gen += 1
        self._bt_set_pair("")

    # ================================================================ KWin input devices (mouse / touchpad / pen)
    @Slot()
    def refreshInputDevices(self):
        """List devices from org.kde.KWin.InputDeviceManager.devicesSysNames, then GetAll on each."""
        self._bt_input_loading = True
        self.inputDevicesChanged.emit()
        self._bt_refresh_input_settings()

        def got_names(ok, out):
            names = []
            if ok:
                try:
                    names = _bt_strings(json.loads(out).get("data", []))
                except ValueError:
                    names = []
            names = [n for n in names if re.fullmatch(r"[A-Za-z0-9_]+", n)]
            if not names:
                self._bt_set_input([])
                return
            result, pending = {}, [len(names)]

            def one(sys_name):
                def got(ok2, out2):
                    props = _bt_json_props(out2) if ok2 else {}
                    if props:
                        props["sysName"] = sys_name
                        result[sys_name] = props
                    pending[0] -= 1
                    if pending[0] == 0:
                        self._bt_set_input([result[n] for n in names if n in result])
                self._async(["busctl", "--user", "--json=short", "call", _BT_KWIN, f"{_BT_DEV_PATH}/{sys_name}",
                             "org.freedesktop.DBus.Properties", "GetAll", "s", _BT_DEV_IFACE], got, 5000)

            for n in names:
                one(n)

        self._async(["busctl", "--user", "--json=short", "get-property", _BT_KWIN, _BT_DEV_PATH,
                     "org.kde.KWin.InputDeviceManager", "devicesSysNames"], got_names, 5000)

    def _bt_set_input(self, devices: list):
        mouse, pad, pen = [], [], []
        for d in devices:
            if d.get("isVirtual"):
                continue
            if d.get("touchpad"):
                pad.append(d)
            elif d.get("tabletTool"):
                pen.append(d)
            elif d.get("pointer") and not d.get("tabletPad"):
                mouse.append(d)
        self._bt_mouse, self._bt_touchpad, self._bt_pen = mouse, pad, pen
        self._bt_input_loading = False
        self.inputDevicesChanged.emit()

    def _bt_refresh_input_settings(self):
        try:
            self._bt_dbl_click = int(kread("kdeglobals", "KDE", "DoubleClickInterval", "400"))
        except ValueError:
            self._bt_dbl_click = 400
        self._bt_wheel_inactive = kread("kwinrc", "MouseBindings", "CommandWindowWheel", "Scroll") != "Scroll"
        self.inputSettingsChanged.emit()

    def _bt_input_list(self, kind: str) -> list:
        return {"mouse": self._bt_mouse, "touchpad": self._bt_touchpad, "pen": self._bt_pen}.get(kind, [])

    @Slot(str, str, "QVariant")
    def setInputProperty(self, kind: str, name: str, value):
        """Set one org.kde.KWin.InputDevice property on every device of `kind`
        (mouse | touchpad | pen) that has it. KWin saves it to kcminputrc itself."""
        typ = _BT_PROP_TYPES.get(name)
        if typ is None:
            return
        changed = False
        for dev in self._bt_input_list(kind):
            if name not in dev:
                continue
            if typ == "b":
                v, arg = bool(value), ("true" if value else "false")
            elif typ == "d":
                v, arg = float(value), repr(float(value))
            elif typ == "u":
                v, arg = int(value), str(int(value))
            else:
                v, arg = str(value), str(value)
            dev[name] = v
            changed = True
            args = ["busctl", "--user", "set-property", _BT_KWIN, f"{_BT_DEV_PATH}/{dev['sysName']}",
                    _BT_DEV_IFACE, name, typ, arg]
            if typ == "d":
                self._later(f"bt:{dev['sysName']}:{name}", args)       # sliders: debounce
            else:
                self._async(args, None, 5000)
        if changed:
            self.inputDevicesChanged.emit()

    @Slot()
    def resetTouchpadSettings(self):
        """Write every touchpad property back to the device's own default value."""
        for dev in list(self._bt_touchpad):
            for name, default_key in _BT_TOUCHPAD_DEFAULTS.items():
                if name in dev and default_key in dev:
                    self.setInputProperty("touchpad", name, dev[default_key])

    @Slot(int)
    def setMouseDoubleClickInterval(self, ms: int):
        self._bt_dbl_click = int(ms)
        self.inputSettingsChanged.emit()
        kwrite("kdeglobals", "KDE", "DoubleClickInterval", str(int(ms)))

    @Slot(bool)
    def setMouseScrollInactiveWindows(self, on: bool):
        self._bt_wheel_inactive = on
        self.inputSettingsChanged.emit()
        kwrite("kwinrc", "MouseBindings", "CommandWindowWheel", "ActivateScroll" if on else "Scroll")
        kwin_reconfigure()

    # ================================================================ printers (CUPS)
    @Slot()
    def refreshPrinters(self):
        def got(ok, out):
            printers, default = [], ""
            for line in out.splitlines():
                m = re.match(r"printer (\S+) (.*)", line)
                if m:
                    rest = m.group(2)
                    state = ("Printing" if rest.startswith("now printing")
                             else "Offline" if "disabled" in rest else "Ready")
                    printers.append({"name": m.group(1), "state": state, "uri": ""})
                m = re.match(r"system default destination:\s*(\S+)", line)
                if m:
                    default = m.group(1)

            def got_uris(_ok, out2):
                uris = dict(re.findall(r"device for (\S+):\s*(\S+)", out2))
                for p in printers:
                    p["uri"] = uris.get(p["name"], "")
                    p["isDefault"] = p["name"] == default
                self._bt_printers, self._bt_default_printer = printers, default
                self._bt_printers_ready = True
                self.printersChanged.emit()

            self._async([*_BT_KDE_LOCALE, "lpstat", "-v"], got_uris, 6000)

        self._async([*_BT_KDE_LOCALE, "lpstat", "-p", "-d"], got, 6000)

    @Slot()
    def searchForPrinters(self):
        """lpinfo -v (lists USB and network backends; may need the lpadmin group)."""
        if self._bt_prn_searching:
            return
        self._bt_prn_searching = True
        self._bt_prn_found = []
        self._bt_prn_add_state, self._bt_prn_add_msg = "", ""
        self.printerAddChanged.emit()

        def got(ok, out):
            found, seen = [], set()
            for line in out.splitlines():
                parts = line.strip().split(None, 1)
                if len(parts) != 2 or parts[0] == "file" or "://" not in parts[1]:
                    continue
                uri = parts[1].strip()
                rest = uri.split("://", 1)[1]
                if not rest or uri in seen:
                    continue
                seen.add(uri)
                found.append({"uri": uri, "name": self._bt_printer_label(uri), "kind": parts[0]})
            self._bt_prn_found = found
            self._bt_prn_searching = False
            if not ok and not found:
                self._bt_prn_add_state = "search-failed"
                self._bt_prn_add_msg = "Couldn't search for printers. You can add one by its address instead."
            self.printerAddChanged.emit()

        self._async(["lpinfo", "-v"], got, 40000)

    @staticmethod
    def _bt_printer_label(uri: str) -> str:
        scheme, rest = uri.split("://", 1)
        host = rest.split("/", 1)[0].split("?", 1)[0]
        if scheme == "usb":
            tail = unquote(rest.split("?", 1)[0]).replace("/", " ")
            return tail.strip() or "USB printer"
        if "._" in host:
            return unquote(host.split("._", 1)[0])
        return unquote(host) or uri

    @Slot(str, str)
    def addPrinter(self, name: str, uri: str):
        """lpadmin -p NAME -E -v URI -m everywhere  (IPP Everywhere driverless queue)."""
        safe = re.sub(r"[^A-Za-z0-9_-]+", "_", name).strip("_") or "Printer"
        self._bt_prn_add_state, self._bt_prn_add_msg = "adding", ""
        self.printerAddChanged.emit()

        def done(ok, _out):
            self._bt_prn_add_state = "ok" if ok else "failed"
            self._bt_prn_add_msg = ("" if ok else "Couldn't add the printer. It may need an administrator, "
                                    "or it may not support driverless printing.")
            self.printerAddChanged.emit()
            self.refreshPrinters()

        self._async(["lpadmin", "-p", safe, "-E", "-v", uri, "-m", "everywhere"], done, 60000)

    @Slot()
    def resetPrinterAddState(self):
        self._bt_prn_add_state, self._bt_prn_add_msg = "", ""
        self.printerAddChanged.emit()

    @Slot(str)
    def setDefaultPrinter(self, name: str):
        self._bt_default_printer = name
        self._bt_printers = [dict(p, isDefault=p["name"] == name) for p in self._bt_printers]
        self.printersChanged.emit()
        self._async(["lpadmin", "-d", name], lambda *_: self.refreshPrinters(), 15000)

    @Slot(str)
    def removePrinter(self, name: str):
        self._bt_printers = [p for p in self._bt_printers if p["name"] != name]
        self.printersChanged.emit()
        self._async(["lpadmin", "-x", name], lambda *_: self.refreshPrinters(), 15000)

    @Slot(str)
    def printTestPage(self, name: str):
        datadir = os.environ.get("CUPS_DATADIR") or "/usr/share/cups"     # SRC print-manager KCupsRequest.cpp:373
        self._async(["lp", "-d", name, f"{datadir}/data/testprint"], lambda *_: self.refreshPrintJobs(name), 15000)

    @Slot(str)
    def openPrinterProperties(self, name: str):
        """The one justified hand-off: print-manager's configure-printer window."""
        spawn(["configure-printer", name])

    @Slot(str)
    def refreshPrintJobs(self, name: str):
        def got(_ok, out):
            jobs = []
            for line in out.splitlines():
                m = re.match(r"(\S+)-(\d+)\s+(\S+)\s+(\d+)\s+(.*)", line.strip())
                if m:
                    jobs.append({"id": f"{m.group(1)}-{m.group(2)}", "user": m.group(3),
                                 "size": int(m.group(4)), "when": m.group(5).strip()})
            self._bt_jobs = jobs
            self.printJobsChanged.emit()

        self._async([*_BT_KDE_LOCALE, "lpstat", "-o", name], got, 6000)

    @Slot(str, str)
    def cancelPrintJob(self, printer: str, job_id: str):
        self._bt_jobs = [j for j in self._bt_jobs if j["id"] != job_id]
        self.printJobsChanged.emit()
        self._async(["cancel", job_id], lambda *_: self.refreshPrintJobs(printer), 10000)

    @Slot(str)
    def cancelAllPrintJobs(self, printer: str):
        self._bt_jobs = []
        self.printJobsChanged.emit()
        self._async(["cancel", "-a", printer], lambda *_: self.refreshPrintJobs(printer), 10000)

    # ================================================================ mobile devices (KDE Connect)
    @Slot()
    def refreshMobileDevices(self):
        self._bt_mobile_avail = has("kdeconnect-cli")
        if not self._bt_mobile_avail:
            self._bt_mobile = []
            self.mobileDevicesChanged.emit()
            return
        self._bt_mobile_busy = True
        self.mobileDevicesChanged.emit()

        def got(_ok, out):
            devs = []
            for line in out.splitlines():
                m = re.match(r"-\s+(.*?):\s+([0-9A-Za-z_]+)\s*(?:\(([^)]*)\))?", line.strip())
                if m:
                    st = m.group(3) or ""
                    devs.append({"name": m.group(1), "id": m.group(2),
                                 "paired": "paired" in st, "reachable": "reachable" in st})
            devs.sort(key=lambda d: (not d["paired"], not d["reachable"], d["name"].lower()))
            self._bt_mobile = devs
            self._bt_mobile_busy = False
            self.mobileDevicesChanged.emit()

        self._async([*_BT_KDE_LOCALE, "kdeconnect-cli", "--list-devices"], got, 15000)

    def _bt_kdeconnect(self, dev_id: str, *args):
        self._async(["kdeconnect-cli", "-d", dev_id, *args], lambda *_: self.refreshMobileDevices(), 20000)

    @Slot(str)
    def mobilePair(self, dev_id: str):
        self._bt_kdeconnect(dev_id, "--pair")

    @Slot(str)
    def mobileUnpair(self, dev_id: str):
        self._bt_kdeconnect(dev_id, "--unpair")

    @Slot(str)
    def mobileRing(self, dev_id: str):
        self._async(["kdeconnect-cli", "-d", dev_id, "--ring"], None, 10000)

    @Slot(str)
    def mobilePing(self, dev_id: str):
        self._async(["kdeconnect-cli", "-d", dev_id, "--ping"], None, 10000)

    @Slot(str, str)
    def mobileShareFile(self, dev_id: str, path: str):
        if path:
            self._async(["kdeconnect-cli", "-d", dev_id, "--share", path], None, 30000)

    # ================================================================ cameras
    @Slot()
    def refreshCameras(self):
        cams, seen = [], set()
        base = Path("/sys/class/video4linux")
        try:
            nodes = sorted(base.glob("video*"), key=lambda p: int(re.sub(r"\D", "", p.name) or 0))
        except OSError:
            nodes = []
        for node in nodes:
            try:
                name = (node / "name").read_text().strip()
            except OSError:
                continue
            if name and name not in seen:           # the extra metadata nodes repeat the name
                seen.add(name)
                cams.append({"name": name, "device": "/dev/" + node.name})
        self._bt_cams = cams
        self.camerasChanged.emit()

    # ================================================================ AutoPlay (device automounter)
    @Slot()
    def refreshAutoplay(self):
        on = (kread("kded_device_automounterrc", "General", "AutomountEnabled", "false") == "true"
              and kread("kded_device_automounterrc", "General", "AutomountOnPlugin", "false") == "true")
        if on != self._bt_autoplay:
            self._bt_autoplay = on
            self.autoplayChanged.emit()

    @Slot(bool)
    def setAutoplay(self, on: bool):
        self._bt_autoplay = on
        self.autoplayChanged.emit()
        if on:
            kwrite("kded_device_automounterrc", "General", "AutomountEnabled", "true", "bool")
        kwrite("kded_device_automounterrc", "General", "AutomountOnPlugin", "true" if on else "false", "bool")

    # ================================================================ USB4 / Thunderbolt (bolt, system bus)
    @Slot()
    def refreshThunderbolt(self):
        bolt = ["busctl", "--system", "--json=short"]

        def got_list(ok, out):
            paths = []
            if ok:
                try:
                    paths = [p for p in _bt_strings(json.loads(out).get("data", [])) if p.startswith("/org/freedesktop/bolt/")]
                except ValueError:
                    paths = []
            self._bt_tb_avail = ok
            if not paths:
                self._bt_tb = []
                self.thunderboltChanged.emit()
                return
            result, pending = {}, [len(paths)]

            def one(path):
                def got(ok2, out2):
                    p = _bt_json_props(out2) if ok2 else {}
                    if p and p.get("Type") != "host":
                        result[path] = {"uid": p.get("Uid", ""), "name": p.get("Label") or p.get("Name", ""),
                                        "vendor": p.get("Vendor", ""), "status": p.get("Status", ""),
                                        "stored": bool(p.get("Stored", False))}
                    pending[0] -= 1
                    if pending[0] == 0:
                        self._bt_tb = [result[x] for x in paths if x in result]
                        self.thunderboltChanged.emit()
                self._async([*bolt, "call", "org.freedesktop.bolt", path, "org.freedesktop.DBus.Properties",
                             "GetAll", "s", "org.freedesktop.bolt1.Device"], got, 5000)

            for path in paths:
                one(path)

        self._async([*bolt, "call", "org.freedesktop.bolt", "/org/freedesktop/bolt",
                     "org.freedesktop.bolt1.Manager", "ListDevices"], got_list, 5000)

    @Slot(str)
    def authorizeThunderboltDevice(self, uid: str):
        """Manager.EnrollDevice(uid, policy "auto", flags "none") — SRC plasma-thunderbolt lib/manager.cpp."""
        self._async(["busctl", "--system", "call", "org.freedesktop.bolt", "/org/freedesktop/bolt",
                     "org.freedesktop.bolt1.Manager", "EnrollDevice", "sss", uid, "auto", "none"],
                    lambda *_: self.refreshThunderbolt(), 30000)

    @Slot(str)
    def forgetThunderboltDevice(self, uid: str):
        self._async(["busctl", "--system", "call", "org.freedesktop.bolt", "/org/freedesktop/bolt",
                     "org.freedesktop.bolt1.Manager", "ForgetDevice", "s", uid],
                    lambda *_: self.refreshThunderbolt(), 15000)
