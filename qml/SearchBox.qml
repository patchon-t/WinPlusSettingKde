import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."
import "Data.js" as Data

TextField {
    id: f
    property var results: []

    implicitHeight: 32
    placeholderText: "Find a setting"
    placeholderTextColor: Theme.textSecondary
    color: Theme.text
    font.pixelSize: Theme.fontBody
    leftPadding: 11
    rightPadding: 34
    selectByMouse: true
    selectionColor: Theme.accent
    selectedTextColor: Theme.onAccent

    background: Rectangle {
        radius: Theme.radius
        color: f.activeFocus ? Theme.controlBgFocus : f.hovered ? Theme.controlBgHover : Theme.controlBg
        border.color: Theme.controlBorder
        clip: true
        Rectangle {  // bottom line, accent when focused
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: f.activeFocus ? 2 : 1
            color: f.activeFocus ? Theme.accent : Theme.controlBorderBottom
        }
        Icon {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            name: "fl:search_20_regular"
            size: 14
            opacity: 0.8
        }
    }

    function choose(r) {
        pop.close()
        f.text = ""
        f.focus = false
        Router.openNav(r.nav)
        if (r.entry)
            Router.activate(r.entry)
    }

    onTextChanged: {
        results = text.trim().length ? Data.search(text) : []
        list.currentIndex = 0
        if (results.length) pop.open()
        else pop.close()
    }
    Keys.onDownPressed: list.incrementCurrentIndex()
    Keys.onUpPressed: list.decrementCurrentIndex()
    Keys.onReturnPressed: if (results.length) choose(results[Math.max(0, list.currentIndex)])
    Keys.onEscapePressed: { text = ""; focus = false }

    Popup {
        id: pop
        y: f.height + 4
        width: Math.max(f.width, 320)
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        background: FlyoutBackground {}
        contentItem: ListView {
            id: list
            implicitHeight: Math.min(contentHeight, 360)
            model: f.results
            clip: true
            delegate: Rectangle {
                id: res
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 40
                radius: Theme.radius
                color: rma.containsMouse || ListView.isCurrentItem ? Theme.subtleHover : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12
                    Icon { name: res.modelData.icon || ""; size: 16 }
                    FText { text: res.modelData.title; Layout.fillWidth: true; elide: Text.ElideRight }
                    FText {
                        text: res.modelData.path
                        font.pixelSize: Theme.fontCaption
                        color: Theme.textSecondary
                    }
                }
                MouseArea {
                    id: rma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: f.choose(res.modelData)
                }
            }
        }
    }
}
