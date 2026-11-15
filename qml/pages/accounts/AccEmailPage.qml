import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// ACC.EML.1: KAccounts has no CLI or D-Bus listing API we could verify, so
// adding and managing accounts is the one justified hand-off (kcm_kaccounts).
SettingsPage {
    id: page
    crumbs: ["Accounts", "Email & accounts"]

    SectionHeader { text: "Accounts used by email, calendar, and contacts"; Layout.topMargin: 0 }
    SettingsCard {
        icon: "fl:add_20_regular"
        title: "Add an account"
        description: "Google, Nextcloud, and other online accounts. Opens KDE's Online Accounts settings."
        clickable: true
        onClicked: Backend.openKcm("kcm_kaccounts")
    }
}
