pragma Singleton
import QtQuick
import WinSettings

// Windows 11 (Fluent) design tokens, light + dark.
QtObject {
    readonly property bool dark: Backend.dark

    // ---- accent
    readonly property color accentBase: Backend.accent
    readonly property color accent: dark ? Qt.lighter(accentBase, 1.55) : accentBase
    readonly property color accentHover: Qt.rgba(accent.r, accent.g, accent.b, 0.9)
    readonly property color accentPressed: Qt.rgba(accent.r, accent.g, accent.b, 0.8)
    readonly property color accentText: dark ? Qt.lighter(accentBase, 1.7) : Qt.darker(accentBase, 1.1)
    // Text/glyphs on accent fills. Never name a property on<Capital>: QML reads it as a signal handler and the binding never runs.
    readonly property color textOnAccent: dark ? "#000000" : "#ffffff"

    // ---- surfaces
    readonly property color windowBg: dark ? "#202020" : "#f3f3f3"
    readonly property color micaTint: dark ? "#0affffff" : "#30fde4d8"
    readonly property color windowBorder: dark ? "#50000000" : "#33000000"
    readonly property color cardBg: dark ? "#2b2b2b" : "#fbfbfb"
    readonly property color cardBgHover: dark ? "#323232" : "#f6f6f6"
    readonly property color cardBgPressed: dark ? "#272727" : "#f3f3f3"
    readonly property color cardBorder: dark ? "#1d1d1d" : "#e5e5e5"
    readonly property color divider: dark ? "#1d1d1d" : "#eaeaea"
    readonly property color flyoutBg: dark ? "#2c2c2c" : "#f9f9f9"
    readonly property color flyoutBorder: dark ? "#40000000" : "#1f000000"
    readonly property color monitorIdle: dark ? "#454545" : "#cccccc"

    // ---- subtle fills (nav items, hover backgrounds)
    readonly property color subtleHover: dark ? Qt.rgba(1, 1, 1, 0.0605) : Qt.rgba(0, 0, 0, 0.0373)
    readonly property color subtlePressed: dark ? Qt.rgba(1, 1, 1, 0.0419) : Qt.rgba(0, 0, 0, 0.0241)

    // ---- controls
    readonly property color controlBg: dark ? "#2d2d2d" : "#fdfdfd"
    readonly property color controlBgHover: dark ? "#323232" : "#f9f9f9"
    readonly property color controlBgPressed: dark ? "#272727" : "#f5f5f5"
    readonly property color controlBgFocus: dark ? "#1f1f1f" : "#ffffff"
    readonly property color controlBgDisabled: dark ? "#2a2a2a" : "#f5f5f5"
    readonly property color controlBgSolid: dark ? "#454545" : "#ffffff"
    readonly property color controlBorder: dark ? "#303030" : "#e5e5e5"
    readonly property color controlBorderBottom: dark ? "#262626" : "#cccccc"
    readonly property color strongStroke: dark ? "#9a9a9a" : "#878787"
    readonly property color toggleOffBg: dark ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(0, 0, 0, 0.024)
    readonly property color sliderTrack: dark ? "#9a9a9a" : "#8a8a8a"

    // ---- text
    readonly property color text: dark ? "#ffffff" : "#1b1b1b"
    readonly property color textSecondary: dark ? "#c8c8c8" : "#5f5f5f"
    readonly property color textDisabled: dark ? "#5d5d5d" : "#a0a0a0"

    // ---- metrics
    readonly property int radius: 4
    readonly property int radiusLarge: 8
    readonly property int fontCaption: 12
    readonly property int fontBody: 14
    readonly property int fontSubtitle: 20
    readonly property int fontTitle: 28

    // ---- motion (WinUI timings + curves)
    readonly property int durFaster: 83      // hover / pressed color fades
    readonly property int durFast: 167       // toggles, small moves, exits
    readonly property int durNormal: 250     // dialogs, flyouts
    readonly property int durSlow: 333       // drill-in, expanders
    readonly property int durPage: 400       // nav section entrance
    readonly property int entranceOffset: 100  // px the new section slides up from
    readonly property var decelerate: [0, 0, 0, 1, 1, 1]     // "fast out, slow in" (entering)
    readonly property var accelerate: [1, 0, 1, 1, 1, 1]     // exiting
    readonly property var standard: [0.8, 0, 0.2, 1, 1, 1]   // moving on screen

    // ---- vector glyphs (16x16 grid, used by Glyph.qml)
    readonly property var gChevronRight: [[[6, 3], [11, 8], [6, 13]]]
    readonly property var gChevronDown: [[[3, 6], [8, 11], [13, 6]]]
    readonly property var gBack: [[[2, 8], [14, 8]], [[7, 3], [2, 8], [7, 13]]]
    readonly property var gClose: [[[3, 3], [13, 13]], [[13, 3], [3, 13]]]
    readonly property var gMinimize: [[[3, 8], [13, 8]]]
    readonly property var gMaximize: [[[3, 3], [13, 3], [13, 13], [3, 13], [3, 3]]]
    readonly property var gRestore: [[[3, 5], [11, 5], [11, 13], [3, 13], [3, 5]],
                                     [[5, 5], [5, 3], [13, 3], [13, 11], [11, 11]]]
    readonly property var gCheck: [[[3, 8.5], [6.5, 12], [13, 4.5]]]
}
