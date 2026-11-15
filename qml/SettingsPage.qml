import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

// Page skeleton: fixed breadcrumb header + scrolling content column
Item {
    id: page
    property var crumbs: []
    property int maxContentWidth: 1000
    property int sidePadding: 28
    default property alias content: col.data

    PageHeader {
        id: pageHeader
        crumbs: page.crumbs
        x: page.sidePadding
        y: 4
    }

    Flickable {
        id: flick
        anchors.top: pageHeader.bottom
        anchors.topMargin: 20
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: col.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: FluentScrollBar {}

        ColumnLayout {
            id: col
            x: page.sidePadding
            width: Math.min(flick.width - page.sidePadding * 2, page.maxContentWidth)
            spacing: 4
        }
    }
}
