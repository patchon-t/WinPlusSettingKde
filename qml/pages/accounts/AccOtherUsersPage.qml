import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accounts", "Other users"]

    property var target: ({ uid: 0, path: "", fullName: "", admin: false })

    Component.onCompleted: Backend.refreshAccounts()

    AccResult { Layout.bottomMargin: 8 }

    FText {
        visible: !Backend.accountsAvailable && !Backend.accountsLoading
        text: "AccountsService isn't reachable, so other users can't be listed or changed."
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
        Layout.bottomMargin: 8
    }

    SectionHeader { text: "Add other user"; Layout.topMargin: 0 }
    SettingsCard {
        icon: "fl:person_add_20_regular"
        title: "Add account"
        description: "Create a new account on this PC"
        enabled: Backend.accountsAvailable
        FluentButton { text: "Add account"; onClicked: addDialog.open() }
    }

    SectionHeader { text: "Other users" }
    FText {
        visible: Backend.otherUsers.length === 0
        text: Backend.accountsAvailable ? "No other accounts have signed in on this PC."
                                        : "Not available right now."
        color: Theme.textSecondary
        font.pixelSize: Theme.fontCaption
    }
    Repeater {
        model: Backend.otherUsers
        delegate: ExpanderCard {
            required property var modelData
            icon: "fl:person_20_regular"
            title: modelData.fullName
            description: (modelData.admin ? "Administrator" : "Standard user")
                         + " · " + modelData.name + (modelData.locked ? " · Locked" : "")

            ExpanderRow {
                title: "Account options"
                description: "Switch between a standard user and an administrator"
                FluentButton {
                    text: "Change account type"
                    onClicked: { page.target = modelData; typeDialog.open() }
                }
            }
            ExpanderRow {
                title: "Account and data"
                description: "Deletes this account and, if you choose, everything in its home folder"
                FluentButton {
                    text: "Remove"
                    onClicked: { page.target = modelData; removeDialog.open() }
                }
            }
        }
    }

    // ---------------------------------------------------------- add account
    AccDialog {
        id: addDialog
        title: "Add an account"
        acceptText: "Create account"
        acceptEnabled: userName.text.length > 0 && pw.text.length > 0 && pw.text === pw2.text
        onShown: {
            fullName.text = ""; userName.text = ""; pw.text = ""; pw2.text = ""
            typeBox.currentIndex = 0
            fullName.field.forceActiveFocus()
        }
        onConfirmed: Backend.addUserAccount(userName.text, fullName.text, pw.text, typeBox.currentIndex)

        AccField { id: fullName; label: "Full name" }
        AccField {
            id: userName
            label: "User name"
            placeholder: "lowercase letters, digits, - and _"
        }
        AccField { id: pw; label: "Password"; password: true }
        AccField { id: pw2; label: "Reenter password"; password: true; onAccepted: addDialog.accept() }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            FText { text: "Account type"; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary }
            FluentCombo {
                id: typeBox
                autoSelect: true
                minWidth: 200
                model: ["Standard User", "Administrator"]
            }
        }
        FText {
            visible: pw2.text.length > 0 && pw.text !== pw2.text
            text: "The passwords don't match."
            color: "#d13438"
            font.pixelSize: Theme.fontCaption
        }
    }

    // ---------------------------------------------------------- change type
    AccDialog {
        id: typeDialog
        title: "Change account type"
        message: page.target.fullName
        acceptText: "OK"
        onShown: roleBox.currentIndex = page.target.admin ? 1 : 0
        onConfirmed: Backend.setOtherUserType(page.target.path, roleBox.currentIndex)

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            FText { text: "Account type"; font.pixelSize: Theme.fontCaption; color: Theme.textSecondary }
            FluentCombo {
                id: roleBox
                autoSelect: true
                minWidth: 200
                model: ["Standard User", "Administrator"]
            }
        }
    }

    // ---------------------------------------------------------- remove
    AccDialog {
        id: removeDialog
        title: "Delete account and data?"
        message: page.target.fullName + "'s account will be removed. Their files can be kept or deleted."
        acceptText: "Delete account and data"
        onConfirmed: Backend.removeUserAccount(page.target.uid, true)

        FluentButton {
            text: "Delete account, keep files"
            Layout.fillWidth: true
            onClicked: { Backend.removeUserAccount(page.target.uid, false); removeDialog.close() }
        }
    }
}
