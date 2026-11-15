import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Win11 "Change your password": new / confirm / hint.
// (AccountsService SetPassword doesn't take the old password; polkit asks for
// administrator authentication instead.)
AccDialog {
    id: dlg
    title: "Change your password"
    message: "You'll be asked to confirm with your administrator password."
    acceptText: "Change password"
    acceptEnabled: newPw.text.length > 0 && newPw.text === confirmPw.text
    onShown: { newPw.text = ""; confirmPw.text = ""; hint.text = ""; newPw.field.forceActiveFocus() }
    onConfirmed: Backend.changeUserPassword(newPw.text, hint.text)

    AccField { id: newPw; label: "New password"; password: true }
    AccField { id: confirmPw; label: "Reenter password"; password: true; onAccepted: dlg.accept() }
    AccField { id: hint; label: "Password hint" }
    FText {
        visible: confirmPw.text.length > 0 && newPw.text !== confirmPw.text
        text: "The passwords don't match."
        color: "#d13438"
        font.pixelSize: Theme.fontCaption
    }
}
