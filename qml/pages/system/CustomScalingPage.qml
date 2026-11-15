import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["System", "Display", "Scale", "Custom scaling"]

    Component.onCompleted: { Backend.reloadOutputs(); Backend.sysCfgReload() }

    SysDisplayPicker { id: picker }
    readonly property var cur: picker.current
    property string error: ""

    function apply() {
        const v = parseInt(field.text)
        if (!page.cur || isNaN(v) || v < 100 || v > 500) {
            page.error = "Enter a scale between 100 and 500"
            return
        }
        page.error = ""
        Backend.setScale(page.cur.name, v / 100)
    }

    FText {
        text: "Scaling the display makes text and apps bigger or smaller. Some apps may not be ready for large scale factors and can look blurry."
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        Layout.fillWidth: true
        Layout.bottomMargin: 8
    }

    SettingsCard {
        icon: "fl:zoom_in_20_regular"
        title: "Custom scaling"
        description: page.error.length ? page.error : "Enter a custom scaling size between 100% and 500%"
        enabled: !!page.cur
        SysTextBox {
            id: field
            implicitWidth: 100
            inputMethodHints: Qt.ImhDigitsOnly
            placeholderText: page.cur ? String(page.cur.scalePercent) : "100"
            validator: IntValidator { bottom: 100; top: 500 }
            onAccepted: page.apply()
        }
        FText { text: "%" }
        FluentButton { text: "Apply"; accent: true; onClicked: page.apply() }
    }

    SettingsCard {
        icon: "fl:window_20_regular"
        title: "Let legacy X11 apps apply scaling themselves"
        description: "Sharper text in X11 apps. Takes effect the next time you sign in"
        SysCfgToggle {
            cfgFile: "kdeglobals"; cfgGroup: "KScreen"; cfgKey: "XwaylandClientsScale"; cfgDefault: true
        }
    }
}
