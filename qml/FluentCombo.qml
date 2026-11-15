import QtQuick
import QtQuick.Controls
import "."

// Win11 ComboBox. Model = JS array of strings.
// Controlled by default: picking an item emits activated(index) only; bind
// currentIndex to your state. Set autoSelect: true for a self-managed combo.
ComboBox {
    id: cb
    property int minWidth: 120
    property bool autoSelect: false

    readonly property string longestText: {
        let l = ""
        const m = cb.model || []
        for (let i = 0; i < m.length; ++i)
            if (String(m[i]).length > l.length) l = String(m[i])
        return l
    }

    implicitHeight: 32
    implicitWidth: Math.max(minWidth, metrics.width + 56)
    font.pixelSize: Theme.fontBody
    opacity: enabled ? 1 : 0.6

    TextMetrics { id: metrics; font: cb.font; text: cb.longestText }

    background: Rectangle {
        radius: Theme.radius
        color: !cb.enabled ? Theme.controlBgDisabled : cb.pressed ? Theme.controlBgPressed
               : cb.hovered ? Theme.controlBgHover : Theme.controlBg
        Behavior on color { ColorAnimation { duration: Theme.durFaster } }
        border.color: Theme.controlBorder
        Rectangle {
            visible: !Theme.dark
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.radius
            anchors.rightMargin: Theme.radius
            height: 1
            color: Theme.controlBorderBottom
        }
    }

    contentItem: FText {
        leftPadding: 11
        rightPadding: 30
        text: cb.displayText
        color: cb.enabled ? Theme.text : Theme.textDisabled
        elide: Text.ElideRight
    }

    indicator: Glyph {
        x: cb.width - width - 12
        y: (cb.height - height) / 2
        width: 12
        height: 12
        lines: Theme.gChevronDown
        color: cb.enabled ? Theme.textSecondary : Theme.textDisabled
    }

    delegate: Item {
        id: dlg
        required property var modelData
        required property int index
        width: ListView.view ? ListView.view.width : 0
        height: 36

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            radius: Theme.radius
            color: dma.pressed ? Theme.subtlePressed
                   : (dma.containsMouse || dlg.index === cb.currentIndex) ? Theme.subtleHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durFaster } }
            Rectangle {
                visible: dlg.index === cb.currentIndex
                width: 3
                height: dma.pressed ? 10 : 16
                radius: 1.5
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        FText {
            x: 12
            width: parent.width - 20
            anchors.verticalCenter: parent.verticalCenter
            text: dlg.modelData
            elide: Text.ElideRight
        }
        MouseArea {
            id: dma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (cb.autoSelect)
                    cb.currentIndex = dlg.index
                cb.popup.close()
                cb.activated(dlg.index)
            }
        }
    }

    popup: Popup {
        id: pp
        // Win11 opens the list *over* the control, selected item aligned with it,
        // and unrolls up and down from that item.
        readonly property real anchorY: Math.max(0, cb.currentIndex) * 36 + 4 + 18
        y: -Math.max(0, cb.currentIndex) * 36 - 4
        x: -4
        width: cb.width + 8
        margins: 8
        padding: 4
        implicitHeight: Math.min(list.contentHeight + 8, 372)
        background: FlyoutBackground {
            transform: Scale { id: bgScale; origin.y: pp.anchorY }
        }
        contentItem: ListView {
            id: list
            clip: true
            implicitHeight: contentHeight
            model: cb.popup.visible ? cb.delegateModel : null
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: FluentScrollBar {}
            transform: Scale { id: listScale; origin.y: pp.anchorY - 4 }
        }
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durFaster }
            NumberAnimation {
                targets: [bgScale, listScale]
                property: "yScale"
                from: Math.min(1, 40 / Math.max(1, pp.height))
                to: 1
                duration: Theme.durNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.decelerate
            }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFaster }
        }
    }
}
