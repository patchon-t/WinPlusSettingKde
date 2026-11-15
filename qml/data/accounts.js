.pragma library
.import "helpers.js" as H

// Accounts section. Owned by the Accounts agent.
var P = "pages/accounts/"

var entry = H.custom("Accounts", "fl:person_20_color", P + "AccountsPage.qml", [
    { icon: "fl:person_20_regular", title: "Your info", desc: "Name, picture", page: P + "AccYourInfoPage.qml" },
    { icon: "fl:mail_20_regular", title: "Email & accounts", desc: "Accounts used by email, calendar, and contacts", page: P + "AccEmailPage.qml" },
    { icon: "fl:lock_closed_20_regular", title: "Sign-in options", desc: "Fingerprint, password, when to sign in again", page: P + "AccSignInPage.qml" },
    { icon: "fl:person_accounts_20_regular", title: "Other users", desc: "Add, change, or remove other people's accounts", page: P + "AccOtherUsersPage.qml" },
    { icon: "fl:wallet_20_regular", title: "Plasma Wallet", desc: "Saved passwords and secrets", page: P + "AccWalletPage.qml" }
])

var settings = [
    { title: "Change display name", kw: "name real name full name rename", icon: "fl:person_20_regular", page: P + "AccYourInfoPage.qml" },
    { title: "Adjust your photo", kw: "picture avatar photo profile image face browse files", icon: "fl:image_20_regular", page: P + "AccYourInfoPage.qml" },
    { title: "Account type", kw: "administrator standard user admin", icon: "fl:person_accounts_20_regular", page: P + "AccYourInfoPage.qml" },
    { title: "Add an online account", kw: "email google nextcloud calendar contacts kaccounts microsoft", icon: "fl:mail_20_regular", page: P + "AccEmailPage.qml" },
    { title: "Fingerprint recognition", kw: "fingerprint fprintd hello biometric reader", icon: "fl:fingerprint_20_regular", page: P + "AccSignInPage.qml" },
    { title: "Change password", kw: "password sign in login passwd hint", icon: "fl:key_20_regular", page: P + "AccSignInPage.qml" },
    { title: "Require sign-in after being away", kw: "lock screen sleep wake away require password grace never every time", icon: "fl:clock_20_regular", page: P + "AccSignInPage.qml" },
    { title: "Restart apps when I sign back in", kw: "restartable apps session restore save login", icon: "fl:arrow_sync_20_regular", page: P + "AccSignInPage.qml" },
    { title: "Add account", kw: "new user create other users family", icon: "fl:person_add_20_regular", page: P + "AccOtherUsersPage.qml" },
    { title: "Remove account", kw: "delete user other users", icon: "fl:person_delete_20_regular", page: P + "AccOtherUsersPage.qml" },
    { title: "Plasma Wallet", kw: "wallet kwallet secrets saved passwords close when idle", icon: "fl:wallet_20_regular", page: P + "AccWalletPage.qml" }
]
