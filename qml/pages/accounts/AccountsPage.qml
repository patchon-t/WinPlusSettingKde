import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Accounts top page: user header, then Your info / Email & accounts /
// Sign-in options / Other users, and "Related settings".
SettingsPage {
    id: page
    property string pageTitle: "Accounts"
    property var items: []
    crumbs: [pageTitle]

    readonly property string base: "pages/accounts/"

    Component.onCompleted: Backend.refreshAccounts()

    AccUserHeader { Layout.topMargin: 0 }

    FText {
        visible: !Backend.accountsAvailable && !Backend.accountsLoading
        text: "AccountsService isn't reachable, so account details can't be read or changed."
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
        Layout.bottomMargin: 8
    }

    SettingsCard {
        icon: "fl:person_20_regular"
        title: "Your info"
        description: "Name, picture"
        clickable: true
        onClicked: Router.open(page.base + "AccYourInfoPage.qml", {})
    }
    SettingsCard {
        icon: "fl:mail_20_regular"
        title: "Email & accounts"
        description: "Accounts used by email, calendar, and contacts"
        clickable: true
        onClicked: Router.open(page.base + "AccEmailPage.qml", {})
    }
    SettingsCard {
        icon: "fl:lock_closed_20_regular"
        title: "Sign-in options"
        description: "Fingerprint, password, when to sign in again"
        clickable: true
        onClicked: Router.open(page.base + "AccSignInPage.qml", {})
    }
    SettingsCard {
        icon: "fl:person_accounts_20_regular"
        title: "Other users"
        description: "Add, change, or remove other people's accounts"
        clickable: true
        onClicked: Router.open(page.base + "AccOtherUsersPage.qml", {})
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:wallet_20_regular"
        title: "Plasma Wallet"
        description: "Saved passwords and secrets"
        clickable: true
        onClicked: Router.open(page.base + "AccWalletPage.qml", {})
    }
}
