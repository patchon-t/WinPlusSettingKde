import QtQuick
import QtQuick.Layouts
import "../.."

// One file type / link type with its current default app on the right
SettingsCard {
    id: r
    property string mime
    property string defName
    property string defIcon
    signal pick()
    icon: r.mime.indexOf("x-scheme-handler/") === 0 ? "fl:link_20_regular" : "fl:document_20_regular"
    description: r.mime

    FluentButton {
        id: btn
        text: r.defName.length ? r.defName : "Choose a default"
        implicitWidth: Math.max(140, implicitContentWidth + 24)
        leftPadding: r.defName.length ? 38 : 12
        onClicked: r.pick()
        Icon {
            visible: r.defName.length > 0
            name: r.defIcon
            size: 20
            x: 10
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
