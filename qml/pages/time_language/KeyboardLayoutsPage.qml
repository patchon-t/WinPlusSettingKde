import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

// Keyboards: kxkbrc [Layout] LayoutList / VariantList
SettingsPage {
    id: page
    crumbs: ["Time & language", "Typing", "Keyboards"]

    property string pendingLayout: ""

    Component.onCompleted: Backend.refreshTyping()

    TlPickerDialog {
        id: layoutDialog
        title: "Add a keyboard"
        message: "Choose a keyboard layout"
        model: Backend.keyboardCatalogue
        onPicked: (code) => {
            page.pendingLayout = code
            Backend.loadKeyboardVariants(code)
            variantDialog.open()
        }
    }
    TlPickerDialog {
        id: variantDialog
        title: "Choose a variant"
        message: page.pendingLayout
        model: Backend.keyboardVariantChoices
        onPicked: (code) => Backend.addKeyboardLayout(page.pendingLayout, code)
    }

    ExpanderCard {
        icon: "fl:keyboard_20_regular"
        title: "Installed keyboards"
        description: Backend.keyboardLayouts.length + " keyboard layout(s)"
        expanded: true
        headerControls: [
            FluentButton {
                text: "Add a keyboard"
                accent: true
                enabled: Backend.keyboardCatalogue.length > 0
                onClicked: layoutDialog.open()
            }
        ]
        Repeater {
            model: Backend.keyboardLayouts
            delegate: ExpanderRow {
                id: kbRow
                required property var modelData
                required property int index
                title: modelData.name
                description: modelData.layout + (modelData.variant.length ? " (" + modelData.variant + ")" : "")
                IconButton {
                    icon: "fl:arrow_up_20_regular"
                    enabled: kbRow.index > 0
                    onClicked: Backend.moveKeyboardLayout(kbRow.index, -1)
                }
                IconButton {
                    icon: "fl:arrow_down_20_regular"
                    enabled: kbRow.index < Backend.keyboardLayouts.length - 1
                    onClicked: Backend.moveKeyboardLayout(kbRow.index, 1)
                }
                IconButton {
                    icon: "fl:delete_20_regular"
                    enabled: Backend.keyboardLayouts.length > 1
                    onClicked: Backend.removeKeyboardLayout(kbRow.index)
                }
            }
        }
        ExpanderRow {
            visible: Backend.keyboardLayouts.length === 0
            title: "No keyboard layouts found"
            description: "Add a keyboard to get started"
        }
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:settings_20_regular"
        title: "Advanced keyboard settings"
        description: "Input method switching, hot keys, key repeat"
        clickable: true
        onClicked: Router.open("pages/time_language/AdvancedKeyboardPage.qml", {})
    }
}
