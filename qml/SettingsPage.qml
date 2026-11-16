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
    property bool headerVisible: true   // Main.qml hides it at once when this page leaves

    // Win11 entrance, content only (the breadcrumb header never moves):
    //   nav  = slide up from Theme.entranceOffset + fade, decelerate, durPage
    //   push/pop = new content fades in place, durFast
    function playEntrance() {
        entrance.stop()
        headerVisible = true
        var nav = Router.motion === "nav"
        slideAnim.from = nav ? Theme.entranceOffset : 0
        slideAnim.duration = nav ? Theme.durPage : Theme.durFast
        fadeAnim.duration = nav ? Theme.durNormal : Theme.durFast
        shift.y = slideAnim.from
        flick.opacity = 0
        entrance.start()
    }
    StackView.onActivating: playEntrance()

    ParallelAnimation {
        id: entrance
        NumberAnimation { id: slideAnim; target: shift; property: "y"; to: 0
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decelerate }
        NumberAnimation { id: fadeAnim; target: flick; property: "opacity"; from: 0; to: 1
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decelerate }
    }

    PageHeader {
        id: pageHeader
        crumbs: page.crumbs
        visible: page.headerVisible
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
            transform: Translate { id: shift }
            x: page.sidePadding
            width: Math.min(flick.width - page.sidePadding * 2, page.maxContentWidth)
            spacing: 4
        }
    }
}
