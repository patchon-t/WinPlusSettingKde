.pragma library
.import "helpers.js" as H

// Accounts section. Owned by the Accounts agent.
var P = "pages/accounts/"

var entry = H.list("Accounts", "fl:person_20_color", [
    { icon: "fl:person_20_regular", title: "Your info", desc: "Name, picture, password", kcm: "kcm_users" },
    { icon: "fl:wallet_20_regular", title: "Wallet", desc: "Saved passwords and secrets", kcm: "kcm_kwallet5" },
    { icon: "fl:people_20_regular", title: "Online accounts", desc: "Google, Nextcloud, and other accounts", kcm: "kcm_kaccounts" }
])

var settings = []
