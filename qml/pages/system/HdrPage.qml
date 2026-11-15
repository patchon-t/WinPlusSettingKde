import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Display", "HDR"]

    Component.onCompleted: Backend.reloadOutputs()

    SysDisplayPicker { id: picker }
    readonly property var cur: picker.current

    SettingsCard {
        icon: "fl:hdr_20_regular"
        title: "Use HDR"
        description: page.cur && page.cur.hdrSupported ? "Get a brighter, more vivid picture on supported displays and content"
                                                       : "This display doesn't support HDR"
        enabled: !!(page.cur && page.cur.hdrSupported)
        FluentToggle {
            checked: !!(page.cur && page.cur.hdr)
            onToggled: (c) => Backend.setHdr(page.cur.name, c)
        }
    }
    SettingsCard {
        visible: !!(page.cur && page.cur.sdrSupported)
        enabled: !!(page.cur && page.cur.hdr)
        icon: "fl:brightness_high_20_regular"
        title: "SDR content brightness"
        description: "Adjust the brightness of non-HDR content while HDR is on"
        FluentSlider {
            id: sdr
            from: 50; to: 1000; stepSize: 10
            value: page.cur ? Math.min(1000, page.cur.sdrBrightness) : 200
            onPressedChanged: if (!pressed) Backend.sysSetSdrBrightness(page.cur.name, Math.round(value))
        }
        FText { text: Math.round(sdr.value) + " nits"; Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight }
    }
    SettingsCard {
        visible: !!(page.cur && page.cur.wcgSupported)
        icon: "fl:color_20_regular"
        title: "Wide color gamut"
        description: "Show a wider range of colors on this display"
        FluentToggle {
            checked: !!(page.cur && page.cur.wcg)
            onToggled: (c) => Backend.sysSetWcg(page.cur.name, c)
        }
    }
}
