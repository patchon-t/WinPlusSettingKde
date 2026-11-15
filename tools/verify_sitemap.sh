#!/usr/bin/env bash
# Re-check SITEMAP.md on the real machine. READ-ONLY: it only introspects D-Bus,
# reads properties, lists things and runs --help. It never changes a setting.
#
#   ./tools/verify_sitemap.sh            run all checks, print PASS / FAIL / INFO
#   ./tools/verify_sitemap.sh | tee verify.txt     and send verify.txt back
#
# Each line starts with the SITEMAP ID(s) it covers.
set -u
PASS=0; FAIL=0
ok()   { printf 'PASS  %-14s %s\n' "$1" "$2"; PASS=$((PASS+1)); }
bad()  { printf 'FAIL  %-14s %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }
info() { printf 'INFO  %-14s %s\n' "$1" "$2"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "== environment"
info ENV "$(. /etc/os-release; echo "$PRETTY_NAME") | $(plasmashell --version 2>/dev/null) | session=${XDG_SESSION_TYPE:-?}"
have busctl || { echo "busctl missing, D-Bus checks need it"; }

# ---------------------------------------------------------------- CLI tools
echo "== command-line tools"
tool() { # id cmd [help-pattern]
    local id=$1 cmd=$2 pat=${3:-}
    if ! have "$cmd"; then bad "$id" "$cmd not installed"; return; fi
    if [ -n "$pat" ]; then
        if "$cmd" --help 2>&1 | grep -qE -- "$pat"; then ok "$id" "$cmd ($pat)"; else bad "$id" "$cmd --help lacks /$pat/"; fi
    else ok "$id" "$cmd"; fi
}
tool SHARED          kwriteconfig6 "--notify"
tool SHARED          kreadconfig6
tool SYS.DISP        kscreen-doctor
tool SYS.SND         pactl "move-sink-input"
tool SYS.PWR.5       powerprofilesctl
tool TL.DT           timedatectl "show-timesync"
tool SYS.ABT.3       hostnamectl
tool TL.LR.5         localectl "list-x11-keymap-layouts"
tool BT              bluetoothctl
tool NET             nmcli
tool PER.0           plasma-apply-lookandfeel
tool PER.COL.1       plasma-apply-colorscheme "accent-color"
tool PER.BG.3        plasma-apply-wallpaperimage "fill-mode"
tool PER.THM.8       plasma-apply-cursortheme "size"
tool PER.THM.5       plasma-apply-desktoptheme "list-themes"
tool SYS.STO.2       ktrash6 "empty"
tool SYS.STO.5       lsblk "json"
tool SYS.STO.5b      xdg-user-dirs-update
tool SYS.NBS.3       kdeconnect-cli "list-devices"
tool BT.PRN.1        lpstat
tool BT.PRN.1        lpadmin
tool BT.PRN.1        lpinfo
tool BT.PRN.3a       cancel
tool BT.PRN.3b       lp
tool BT.PRN.3c       configure-printer
tool BT.PRN.4        scanimage
tool BT.4d           bluedevil-sendfile
tool BT.CAM.2        v4l2-ctl
tool BT.USB.2        boltctl
tool ACC.SGN.2       fprintd-enroll
tool APP.INS         flatpak "permission-set"
tool APP.INS         pkcon
tool APP.DEF         xdg-mime
tool PER.FNT         fc-list
tool PER.FNT         fc-cache
tool PRV.SEC.2       ufw
tool PRV.SRW.3       balooctl6
tool UPD.1           fwupdmgr
tool GAM.CAP.1       spectacle
tool TL.TYP.6        plasma-emojier
tool GAM.MODE.1      gamemoded

# ---------------------------------------------------------------- D-Bus
echo "== D-Bus (session unless noted)"
member() { # id bus service path iface member
    local id=$1 bus=$2 svc=$3 path=$4 iface=$5 m=$6 out
    out=$(busctl "--$bus" introspect "$svc" "$path" "$iface" 2>&1)
    if [ $? -ne 0 ]; then bad "$id" "$svc $path ($iface): $(echo "$out" | head -1)"; return; fi
    if echo "$out" | awk '{print $1}' | grep -qx "\.$m"; then ok "$id" "$iface.$m"; else bad "$id" "$iface has no $m"; fi
}
member SHARED       user org.kde.KWin /KWin org.kde.KWin reconfigure
member SHARED       user org.kde.KWin /KWin org.kde.KWin supportInformation
member SYS.DISP.2   user org.kde.KWin /org/kde/KWin/Effect/OutputLocator1 org.kde.KWin.Effect.OutputLocator1 show
member SYS.DISP.4   user org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl setBrightness
member SYS.DISP.4   user org.kde.ScreenBrightness /org/kde/ScreenBrightness org.kde.ScreenBrightness DisplaysDBusNames
for d in $(busctl --user get-property org.kde.ScreenBrightness /org/kde/ScreenBrightness org.kde.ScreenBrightness DisplaysDBusNames 2>/dev/null | tr -d '"' | cut -d' ' -f3-); do
    member SYS.DISP.4 user org.kde.ScreenBrightness "/org/kde/ScreenBrightness/$d" org.kde.ScreenBrightness.Display SetBrightness
done
member SYS.DISP.6b  user org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight preview
member SYS.DISP.6e  user org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight scheduledTransitionDateTime
member SYS.PWR      user org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement refreshStatus
member SYS.PWR.1    user org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement batteryRemainingTime
member SYS.PWR.9    user org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement chargeStopThreshold
member SYS.MT.5     user org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager createDesktop
member SYS.CLP.4    user org.kde.klipper /klipper org.kde.klipper.klipper clearClipboardHistory
member SHARED       user org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript
member SHARED       user org.kde.KWin /org/kde/KWin/InputDeviceManager org.kde.KWin.InputDeviceManager ListPointers
for dev in $(busctl --user get-property org.kde.KWin /org/kde/KWin/InputDeviceManager org.kde.KWin.InputDeviceManager devicesSysNames 2>/dev/null | tr -d '"' | cut -d' ' -f3- | tr ' ' '\n' | head -3); do
    member BT.MSE      user org.kde.KWin "/org/kde/KWin/InputDevice/$dev" org.kde.KWin.InputDevice pointerAcceleration
done
member A11Y         user org.kde.KWin /Effects org.kde.kwin.Effects loadEffect
member TL.TYP.3     user org.kde.KWin /VirtualKeyboard org.kde.kwin.VirtualKeyboard active
member A11Y.MAG.1   user org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component invokeShortcut
member TL.DT.3      user org.kde.kded6 /kded org.kde.kded6 setModuleAutoloading
member PRV.ACT.3    user org.kde.ActivityManager /ActivityManager/Resources/Scoring org.kde.ActivityManager.ResourcesScoring DeleteRecentStats
member PRV.APP      user org.freedesktop.impl.portal.PermissionStore /org/freedesktop/impl/portal/PermissionStore org.freedesktop.impl.portal.PermissionStore Set
member UPD.2        user org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt promptReboot
member ACC          system org.freedesktop.Accounts /org/freedesktop/Accounts org.freedesktop.Accounts CreateUser
member ACC          system org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User SetIconFile
member TL.LR.4a     system org.kde.localegenhelper /LocaleGenHelper org.kde.localegenhelper.LocaleGenHelper enableLocales
member ACC.SGN.2    system net.reactivated.Fprint /net/reactivated/Fprint/Manager net.reactivated.Fprint.Manager GetDefaultDevice

# ---------------------------------------------------------------- UNVERIFIED items
echo "== items marked UNVERIFIED (information to confirm or correct)"
info SYS.DISP.13 "kscreen-doctor -j output keys: $(kscreen-doctor -j 2>/dev/null | python3 -c 'import json,sys; o=json.load(sys.stdin)["outputs"]; print(sorted(o[0].keys()) if o else "no outputs")' 2>&1 | head -c 600)"
info SYS.DISP.8  "ICC dirs: $(ls -d ~/.local/share/icc /usr/share/color/icc 2>/dev/null | tr '\n' ' ')"
info A11Y.MAG.1  "kwin shortcut names with 'zoom': $(busctl --user call org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component shortcutNames 2>/dev/null | tr ' ' '\n' | grep -i zoom | tr '\n' ' ')"
info BT.3        "bluetoothctl info battery line: $(for m in $(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}' | head -1); do bluetoothctl info "$m" | grep -iE 'battery|icon'; done | tr '\n' ' ')"
info BT.CAM.1    "v4l devices: $(cat /sys/class/video4linux/*/name 2>/dev/null | tr '\n' ',')"
info BT.X.1      "kcminputrc [Keyboard]: $(kreadconfig6 --file kcminputrc --group Keyboard --key NumLock 2>/dev/null)"
info NET.AIR.3   "plasma-nm config: $(tr '\n' ' ' < ~/.config/plasma-nm 2>/dev/null | head -c 300)"
info NET.PRX.3   "kioslaverc proxy: $(grep -A12 '^\[Proxy Settings\]' ~/.config/kioslaverc 2>/dev/null | tr '\n' ' ' | head -c 300)"
info PER.COL.2   "plasma styles: $(plasma-apply-desktoptheme --list-themes 2>/dev/null | tr '\n' ' ' | head -c 300)"
info A11Y.MP.1   "cursor themes: $(ls -d /usr/share/icons/*/cursors ~/.local/share/icons/*/cursors 2>/dev/null | awk -F/ '{print $(NF-1)}' | tr '\n' ' ')"
info A11Y.CT.1   "color schemes: $(plasma-apply-colorscheme --list-schemes 2>/dev/null | tr '\n' ' ' | head -c 300)"
info A11Y.TS.1   "kdeglobals font: $(kreadconfig6 --file kdeglobals --group General --key font 2>/dev/null)"
info TL.TYP.2    "Sonnet config files: $(ls ~/.config/KDE/Sonnet.conf ~/.config/sonnetrc 2>/dev/null | tr '\n' ' ')"
info TL.TYP.4a   "kxkbrc SwitchMode: $(kreadconfig6 --file kxkbrc --group Layout --key SwitchMode 2>/dev/null)"
info SYS.DEV.3   "dolphinrc General keys: $(grep -A30 '^\[General\]' ~/.config/dolphinrc 2>/dev/null | grep -oE '^[A-Za-z]+' | tr '\n' ' ')"
info ACC.SGN.10  "SDDM autologin: $(grep -rhs -A3 '^\[Autologin\]' /etc/sddm.conf /etc/sddm.conf.d/ 2>/dev/null | tr '\n' ' ')"
info UPD.4       "apt history log: $(ls -l /var/log/apt/history.log 2>/dev/null | awk '{print $5" bytes"}')"
info UPD.5c      "reboot-required flag file: $( [ -e /var/run/reboot-required ] && echo present || echo absent)"
info PRV.SRW.3   "baloo: $(balooctl6 status 2>/dev/null | head -2 | tr '\n' ' ')"
info SYS.DISP.14c "launcher entries using PrefersNonDefaultGPU: $(grep -ls PrefersNonDefaultGPU /usr/share/applications/*.desktop 2>/dev/null | wc -l)"

echo
echo "== $PASS passed, $FAIL failed"
