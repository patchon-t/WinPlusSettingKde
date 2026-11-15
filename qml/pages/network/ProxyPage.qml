import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Network & internet", "Proxy"]

    Component.onCompleted: Backend.refreshProxy()

    FText {
        text: Backend.proxyType === 4
              ? "Proxy settings currently come from environment variables. Turning on an option below replaces that."
              : "Only one proxy mode can be active at a time. Applies to KDE apps and apps that follow the system proxy."
        font.pixelSize: Theme.fontCaption
        color: Theme.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.bottomMargin: 4
    }

    SectionHeader { text: "Automatic proxy setup"; Layout.topMargin: 12 }

    SettingsCard {
        icon: "fl:search_20_regular"
        title: "Automatically detect settings"
        description: "Find a proxy configuration on your network (WPAD)"
        FluentToggle {
            checked: Backend.proxyType === 3
            onToggled: (v) => Backend.setProxyAuto(v)
        }
    }

    SettingsCard {
        icon: "fl:document_20_regular"
        title: "Use setup script"
        description: Backend.proxyScript.length ? Backend.proxyScript : "Script address"
        FluentButton { text: "Edit"; onClicked: scriptDlg.openFor() }
        FluentToggle {
            checked: Backend.proxyType === 2
            onToggled: (v) => {
                if (v && Backend.proxyScript.length === 0) scriptDlg.openFor()
                else Backend.setProxyScriptEnabled(v)
            }
        }
    }

    SectionHeader { text: "Manual proxy setup"; Layout.topMargin: 12 }

    SettingsCard {
        icon: "fl:globe_20_regular"
        title: "Use a proxy server"
        description: Backend.proxyHost.length ? Backend.proxyHost + (Backend.proxyPort.length ? ":" + Backend.proxyPort : "")
                                              : "Set up a proxy address and port"
        FluentButton { text: "Edit"; onClicked: manualDlg.openFor() }
        FluentToggle {
            checked: Backend.proxyType === 1
            onToggled: (v) => {
                if (v && Backend.proxyHost.length === 0) manualDlg.openFor()
                else Backend.setProxyManualEnabled(v)
            }
        }
    }

    NetInfoCard {
        visible: Backend.proxyType === 1 && Backend.proxyExceptions.length > 0
        rows: [{ label: "Don't use the proxy server for", value: Backend.proxyExceptions }]
    }

    NetFormDialog {
        id: scriptDlg
        title: "Use setup script"
        acceptText: "Save"
        function openFor() { scriptField.text = Backend.proxyScript; error = ""; open() }
        onConfirmed: {
            const err = Backend.netValidateProxyScript(scriptField.text)
            if (err.length) { error = err; return }
            Backend.applyProxyScript(scriptField.text)
            close()
        }
        NetField { id: scriptField; label: "Script address"; placeholder: "http://example.com/proxy.pac" }
    }

    NetFormDialog {
        id: manualDlg
        title: "Edit proxy server"
        message: "Used for HTTP, HTTPS and FTP."
        acceptText: "Save"
        function openFor() {
            hostField.text = Backend.proxyHost
            portField.text = Backend.proxyPort
            excField.text = Backend.proxyExceptions
            revToggle.checked = Backend.proxyReversed
            error = ""
            open()
        }
        onConfirmed: {
            const err = Backend.netValidateProxyManual(hostField.text, portField.text)
            if (err.length) { error = err; return }
            Backend.applyProxyManual(hostField.text, portField.text, excField.text, revToggle.checked)
            close()
        }
        NetField { id: hostField; label: "Proxy IP address or name"; placeholder: "proxy.example.com" }
        NetField { id: portField; label: "Port"; placeholder: "8080" }
        NetField {
            id: excField
            label: "Don't use the proxy server for entries that begin with (separate with commas)"
            placeholder: "localhost, 192.168.0.0/16"
        }
        RowLayout {
            Layout.fillWidth: true
            FText {
                text: "Use the proxy only for the addresses above"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            FluentToggle { id: revToggle; enabled: excField.text.length > 0; onToggled: (v) => checked = v }
        }
    }
}
