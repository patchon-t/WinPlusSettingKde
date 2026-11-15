import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// ACC.X.1 (Plasma extra): kwalletrc [Wallet] Enabled / Close When Idle / Idle Timeout
SettingsPage {
    id: page
    crumbs: ["Accounts", "Plasma Wallet"]

    Component.onCompleted: Backend.refreshWallet()

    SettingsCard {
        icon: "fl:wallet_20_regular"
        title: "Use Plasma Wallet"
        description: "Store passwords and secrets for apps, protected by your wallet password"
        FluentToggle {
            checked: Backend.walletEnabled
            onToggled: (c) => Backend.setWalletEnabled(c)
        }
    }
    SettingsCard {
        icon: "fl:clock_20_regular"
        title: "Close the wallet when idle"
        description: "Lock it again after nobody has used it for a while"
        enabled: Backend.walletEnabled
        FluentToggle {
            checked: Backend.walletCloseWhenIdle
            onToggled: (c) => Backend.setWalletCloseWhenIdle(c)
        }
    }
    SettingsCard {
        icon: "fl:clock_20_regular"
        title: "Idle time before closing"
        enabled: Backend.walletEnabled && Backend.walletCloseWhenIdle
        FluentCombo {
            property var mins: [1, 5, 10, 15, 30, 60]
            property var labels: ["1 minute", "5 minutes", "10 minutes", "15 minutes", "30 minutes", "1 hour"]
            minWidth: 160
            model: {
                const m = Backend.walletIdleMinutes
                return mins.indexOf(m) >= 0 ? labels : labels.concat([m + " minutes"])
            }
            currentIndex: {
                const i = mins.indexOf(Backend.walletIdleMinutes)
                return i >= 0 ? i : mins.length
            }
            onActivated: (i) => { if (i < mins.length) Backend.setWalletIdleMinutes(mins[i]) }
        }
    }
}
