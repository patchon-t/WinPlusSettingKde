import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Accounts", "Your info"]

    Component.onCompleted: Backend.refreshAccounts()

    AccUserHeader { pictureSize: 96; Layout.topMargin: 0 }
    AccResult { Layout.bottomMargin: 8 }

    // ---------------------------------------------------------- name
    SettingsCard {
        icon: "fl:person_20_regular"
        title: "Display name"
        description: Backend.userName
        enabled: Backend.accountsAvailable
        FluentButton { text: "Edit name"; onClicked: nameDialog.open() }
    }

    // ---------------------------------------------------------- picture
    SectionHeader { text: "Adjust your photo" }
    SettingsCard {
        icon: "fl:image_20_regular"
        title: "Choose a file"
        description: "Pick a picture from your computer. It's cropped to a square."
        enabled: Backend.accountsAvailable
        FluentButton { text: "Browse files"; onClicked: picDialog.open() }
    }
    SettingsCard {
        icon: "fl:delete_20_regular"
        title: "Remove your picture"
        description: "Go back to the default picture"
        enabled: Backend.accountsAvailable
        FluentButton { text: "Remove"; onClicked: Backend.removeUserPicture() }
    }

    // ---------------------------------------------------------- account
    SectionHeader { text: "Account settings" }
    SettingsCard {
        icon: "fl:lock_closed_20_regular"
        title: "Sign-in options"
        description: "Password, fingerprint"
        clickable: true
        onClicked: Router.open("pages/accounts/AccSignInPage.qml", {})
    }

    InputDialog {
        id: nameDialog
        title: "Change your name"
        message: "This is the name shown on the sign-in screen and in Settings."
        placeholder: Backend.userName
        acceptText: "Save"
        onSubmitted: (v) => Backend.setUserRealName(v)
    }

    FileDialog {
        id: picDialog
        title: "Choose a picture"
        currentFolder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
        nameFilters: ["Pictures (*.png *.jpg *.jpeg *.webp *.bmp *.gif)"]
        onAccepted: Backend.setUserPicture(selectedFile.toString())
    }
}
