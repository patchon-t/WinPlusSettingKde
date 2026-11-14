import QtQuick
import QtQuick.Layouts
import "."

// "System  >  Display" breadcrumb title
RowLayout {
    id: h
    property var crumbs: []
    spacing: 12

    Repeater {
        model: h.crumbs
        delegate: RowLayout {
            id: crumb
            required property var modelData
            required property int index
            readonly property bool last: index === h.crumbs.length - 1
            spacing: 12
            FText {
                text: crumb.modelData
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
                color: crumb.last || cma.containsMouse ? Theme.text : Theme.textSecondary
                MouseArea {
                    id: cma
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !crumb.last
                    onClicked: Router.back()
                }
            }
            Glyph {
                visible: !crumb.last
                lines: Theme.gChevronRight
                width: 16
                height: 16
                stroke: 1.5
                color: Theme.textSecondary
            }
        }
    }
}
