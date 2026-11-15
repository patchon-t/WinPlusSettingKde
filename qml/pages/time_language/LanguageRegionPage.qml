import QtQuick
import QtQuick.Layouts
import WinSettings
import "../.."

SettingsPage {
    id: page
    crumbs: ["Time & language", "Language & region"]

    function names(list) { return list.map(d => d.name) }
    function indexOfCode(list, code) {
        for (let i = 0; i < list.length; ++i)
            if (list[i].code === code) return i
        return -1
    }

    Component.onCompleted: { Backend.refreshLanguage(); Backend.loadLocaleCatalogue() }

    TlPickerDialog {
        id: addLanguageDialog
        title: "Add a language"
        message: "Pick a language to add to your list. Translations themselves come from your distribution's language packs."
        model: Backend.localeCatalogue
        onPicked: (code) => Backend.addLanguage(code)
    }
    InputDialog {
        id: systemLocaleDialog
        title: "Administrative language settings"
        message: "System locale used by the login screen and system services, for example en_US.UTF-8"
        placeholder: "en_US.UTF-8"
        acceptText: "Change"
        onSubmitted: (v) => Backend.setSystemLocale(v)
    }

    SettingsCard {
        icon: "fl:local_language_20_regular"
        title: "Windows display language"
        description: "Plasma and apps will appear in the first supported language in your list"
        FluentCombo {
            minWidth: 240
            model: page.names(Backend.preferredLanguages)
            currentIndex: Backend.preferredLanguages.length ? 0 : -1
            onActivated: (i) => Backend.setDisplayLanguage(i)
        }
    }

    ExpanderCard {
        id: langs
        icon: "fl:translate_20_regular"
        title: "Preferred languages"
        description: "Apps and websites will appear in the first language in the list that they support"
        expanded: true
        headerControls: [
            FluentButton { text: "Add a language"; accent: true; onClicked: addLanguageDialog.open() }
        ]
        Repeater {
            model: Backend.preferredLanguages
            delegate: ExpanderRow {
                id: langRow
                required property var modelData
                required property int index
                title: modelData.name
                description: index === 0 ? "Display language" : modelData.code
                IconButton {
                    icon: "fl:arrow_up_20_regular"
                    enabled: langRow.index > 0
                    onClicked: Backend.moveLanguage(langRow.index, -1)
                }
                IconButton {
                    icon: "fl:arrow_down_20_regular"
                    enabled: langRow.index < Backend.preferredLanguages.length - 1
                    onClicked: Backend.moveLanguage(langRow.index, 1)
                }
                IconButton {
                    icon: "fl:more_horizontal_20_regular"
                    onClicked: Router.open("pages/time_language/LanguageOptionsPage.qml",
                                           { code: langRow.modelData.code, name: langRow.modelData.name })
                }
                IconButton {
                    icon: "fl:delete_20_regular"
                    enabled: Backend.preferredLanguages.length > 1
                    onClicked: Backend.removeLanguage(langRow.index)
                }
            }
        }
        ExpanderRow {
            visible: Backend.preferredLanguages.length === 0
            title: "No languages configured"
            description: "Add a language to get started"
        }
    }

    SettingsCard {
        visible: Backend.localeStatus.length > 0
        icon: "fl:arrow_sync_20_regular"
        title: Backend.localeStatus
    }

    SettingsCard {
        icon: "fl:earth_20_regular"
        title: "Country or region"
        description: "Apps and services can use your country or region to give you local content"
        FluentCombo {
            minWidth: 240
            model: page.names(Backend.regionCatalogue)
            currentIndex: page.indexOfCode(Backend.regionCatalogue, Backend.homeRegion)
            onActivated: (i) => Backend.setHomeRegion(Backend.regionCatalogue[i].code)
        }
    }

    ExpanderCard {
        icon: "fl:number_symbol_20_regular"
        title: "Regional format"
        description: "Windows and some apps format dates and times based on your regional format"
        headerControls: [
            FluentCombo {
                minWidth: 240
                model: page.names(Backend.localeCatalogue)
                currentIndex: page.indexOfCode(Backend.localeCatalogue, Backend.regionalFormat)
                onActivated: (i) => Backend.setRegionalFormat(Backend.localeCatalogue[i].code)
            }
        ]
        ExpanderRow {
            title: "Change formats"
            description: "Calendar, first day of week, date and time formats"
            FluentButton { text: "Change formats"; onClicked: Router.open("pages/time_language/ChangeFormatsPage.qml", {}) }
        }
    }

    SectionHeader { text: "Related settings" }
    SettingsCard {
        icon: "fl:keyboard_20_regular"
        title: "Typing"
        description: "Keyboards, spell check, touch keyboard"
        clickable: true
        onClicked: Router.open("pages/time_language/TypingPage.qml", {})
    }
    SettingsCard {
        icon: "fl:settings_20_regular"
        title: "Administrative language settings"
        description: Backend.systemLocale.length ? "System locale: " + Backend.systemLocale : "Change the system locale"
        FluentButton { text: "Change"; onClicked: systemLocaleDialog.open() }
    }
}
