import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accounts", "Sign-in options"]

    Component.onCompleted: {
        Backend.refreshSignIn()
        Backend.refreshFingerprints()
        Backend.refreshAccounts()
    }

    AccResult { Layout.bottomMargin: 8 }

    SectionHeader { text: "Ways to sign in"; Layout.topMargin: 0 }

    SettingsCard {
        icon: "fl:scan_camera_20_regular"
        title: "Facial recognition (Windows Hello)"
        description: "Not available on Linux"
        enabled: false
    }

    // ---------------------------------------------------------- fingerprint
    ExpanderCard {
        id: fp
        icon: "fl:fingerprint_20_regular"
        title: "Fingerprint recognition (Windows Hello)"
        description: !Backend.fingerprintAvailable ? "No fingerprint reader found, or fprintd isn't installed"
                     : Backend.fingerprints.length ? Backend.fingerprints.length + " fingerprint"
                       + (Backend.fingerprints.length === 1 ? "" : "s") + " added"
                     : "Sign in with your fingerprint"
        opacity: Backend.fingerprintAvailable ? 1 : 0.5
        enabled: Backend.fingerprintAvailable

        ExpanderRow {
            title: Backend.fingerprintBusy ? "Adding a fingerprint" : "Add a fingerprint"
            description: Backend.fingerprintMessage.length ? Backend.fingerprintMessage
                         : "Touch the reader to scan your finger"
            FText {
                visible: Backend.fingerprintBusy
                text: Backend.fingerprintStage + " scans"
                color: Theme.textSecondary
            }
            FluentButton {
                text: Backend.fingerprintBusy ? "Cancel" : "Set up"
                onClicked: Backend.fingerprintBusy ? Backend.cancelFingerprintEnroll()
                                                   : Backend.enrollFingerprint()
            }
        }
        ExpanderRow {
            title: "Remove all fingerprints"
            description: "Deletes every fingerprint saved for your account"
            visible: Backend.fingerprints.length > 0
            FluentButton { text: "Remove"; onClicked: Backend.removeFingerprints() }
        }
    }

    SettingsCard {
        icon: "fl:dialpad_20_regular"
        title: "PIN (Windows Hello)"
        description: "Not available on Linux"
        enabled: false
    }

    // ---------------------------------------------------------- password
    SettingsCard {
        icon: "fl:key_20_regular"
        title: "Password"
        description: Backend.passwordSupported ? "Sign in with your account password"
                                               : "Not available: the system crypt library wasn't found"
        enabled: Backend.accountsAvailable && Backend.passwordSupported
        FluentButton { text: "Change"; onClicked: pwDialog.open() }
    }

    // ---------------------------------------------------------- additional
    SectionHeader { text: "Additional settings" }

    SettingsCard {
        icon: "fl:clock_20_regular"
        title: "If you've been away, when should we require you to sign in again?"
        FluentCombo {
            minWidth: 160
            model: Backend.awayOptions
            currentIndex: Backend.awayIndex
            onActivated: (i) => Backend.setAwayIndex(i)
        }
    }
    SettingsCard {
        icon: "fl:arrow_sync_20_regular"
        title: "Automatically save my restartable apps and restart them when I sign back in"
        FluentToggle {
            checked: Backend.restoreAppsOn
            onToggled: (c) => Backend.setRestoreApps(c)
        }
    }

    AccPasswordDialog { id: pwDialog }
}
