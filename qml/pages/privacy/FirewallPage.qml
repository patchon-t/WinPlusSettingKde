import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Firewall & network protection, driven by ufw (changes ask for administrator permission).
SettingsPage {
    id: page
    crumbs: ["Windows Security", "Firewall & network protection"]

    readonly property var actions: ["allow", "deny", "reject", "limit"]
    readonly property var actionLabels: ["Allow", "Block", "Reject", "Limit"]
    property int actionIndex: 0
    property int dirIndex: 0
    property string result: ""
    property bool resultOk: true

    Component.onCompleted: Backend.refreshPrvFirewall()

    Connections {
        target: Backend
        function onPrvFirewallResult(ok, msg) { page.resultOk = ok; page.result = msg }
    }

    PrvInfoBar {
        visible: !Backend.prvUfwInstalled
        severity: "warning"
        title: "Firewall not available"
        message: "The ufw firewall isn't installed. Install the \"ufw\" package to manage the firewall here."
    }
    PrvInfoBar {
        visible: page.result.length > 0
        severity: page.resultOk ? "success" : "warning"
        title: page.result
    }

    SettingsCard {
        enabled: Backend.prvUfwInstalled && !Backend.prvUfwBusy
        icon: "fl:fire_20_regular"
        title: "Firewall"
        description: Backend.prvUfwBusy ? "Waiting for administrator permission..."
                     : "Block unwanted incoming connections. Changing this asks for your password."
        FluentToggle {
            checked: Backend.prvUfwEnabled
            onToggled: (v) => Backend.setPrvFirewallEnabled(v)
        }
    }

    SectionHeader { text: "Rules" }

    SettingsCard {
        enabled: Backend.prvUfwInstalled && !Backend.prvUfwBusy
        icon: "fl:add_20_regular"
        title: "Add a rule"
        description: "Open or close a port, for example 443/tcp"
        FluentCombo { minWidth: 90; model: page.actionLabels; currentIndex: page.actionIndex
            onActivated: (i) => page.actionIndex = i }
        FluentCombo { minWidth: 100; model: ["Incoming", "Outgoing"]; currentIndex: page.dirIndex
            onActivated: (i) => page.dirIndex = i }
        FluentButton { text: "Add rule"; accent: true; onClicked: ruleDlg.open() }
    }

    SettingsCard {
        enabled: Backend.prvUfwInstalled && !Backend.prvUfwBusy
        icon: "fl:arrow_clockwise_20_regular"
        title: Backend.prvUfwRulesLoaded ? "Refresh the list of rules" : "Show current rules"
        description: "Reading the rules needs administrator permission"
        FluentButton { text: Backend.prvUfwRulesLoaded ? "Refresh" : "Show rules"; onClicked: Backend.loadPrvFirewallRules() }
    }

    Repeater {
        model: Backend.prvUfwRules
        delegate: SettingsCard {
            required property var modelData
            enabled: !Backend.prvUfwBusy
            icon: modelData.action === "ALLOW" ? "fl:checkmark_circle_20_regular" : "fl:dismiss_20_regular"
            title: modelData.to
            description: modelData.action.charAt(0) + modelData.action.slice(1).toLowerCase()
                         + " " + (modelData.dir === "OUT" ? "outgoing" : "incoming")
                         + (modelData.from.length ? " from " + modelData.from : "")
            IconButton {
                icon: "fl:delete_20_regular"
                tooltip: "Delete rule"
                onClicked: Backend.removePrvFirewallRule(modelData.num)
            }
        }
    }

    FText {
        visible: Backend.prvUfwRulesLoaded && Backend.prvUfwRules.length === 0
        text: "There are no firewall rules."
        color: Theme.textSecondary
        Layout.topMargin: 8
        Layout.alignment: Qt.AlignHCenter
    }

    InputDialog {
        id: ruleDlg
        title: "Add a firewall rule"
        message: page.actionLabels[page.actionIndex] + " " + (page.dirIndex === 0 ? "incoming" : "outgoing")
                 + " traffic. Enter a port or range (443, 8000:8100/tcp) or an app profile name."
        placeholder: "Port or app"
        acceptText: "Add rule"
        onSubmitted: (v) => Backend.addPrvFirewallRule(page.actions[page.actionIndex],
                                                      page.dirIndex === 0 ? "in" : "out", v)
    }
}
