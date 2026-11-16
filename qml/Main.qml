import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import WinSettings
import "."
import "Data.js" as Data

ApplicationWindow {
    id: win
    width: 1120
    height: 780
    minimumWidth: 760
    minimumHeight: 520
    visible: true
    title: "Settings"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    property int navIndex: 0
    readonly property bool maximized: visibility === Window.Maximized || visibility === Window.FullScreen
    readonly property int cornerRadius: maximized ? 0 : 8

    // Nav section switch = Win11 "entrance" (replace the whole stack).
    // Opening a sub page = "drill in" (push); Back = reverse drill (pop).
    function goTo(i) {
        if (i === navIndex && stack.depth === 1)
            return
        navIndex = i
        Router.motion = "nav"
        const n = Data.nav[i]
        if (stack.depth === 0)
            stack.push(Qt.resolvedUrl(n.page), n.props || {}, StackView.Immediate)
        else
            stack.replace(null, Qt.resolvedUrl(n.page), n.props || {})
    }

    Component.onCompleted: goTo(0)

    Connections {
        target: Router
        function onOpen(page, props) { Router.motion = "push"; stack.push(Qt.resolvedUrl(page), props || {}) }
        function onBack() { if (stack.depth > 1) { Router.motion = "pop"; stack.pop() } }
        function onOpenNav(index) { win.goTo(index) }
    }

    Shortcut { sequences: [StandardKey.Back, "Alt+Left"]; onActivated: Router.back() }
    Shortcut { sequence: "Ctrl+F"; onActivated: nav.focusSearch() }

    // Window surface: rounded 8px like Win11, square when maximized
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: win.cornerRadius
        color: Theme.windowBg
        // Fake Mica: warm tint fading in from the right
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Theme.micaTint }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            Layout.fillWidth: true
            window: win
            canGoBack: stack.depth > 1
            onBackClicked: Router.back()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            NavPane {
                id: nav
                Layout.preferredWidth: win.width < 960 ? 260 : 300
                Layout.fillHeight: true
                currentIndex: win.navIndex
                onNavigate: (i) => win.goTo(i)
            }

            StackView {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                // Win11 (measured from a screen recording): the header switches instantly;
                // only the content moves. The new page animates its own content (see
                // SettingsPage.playEntrance); here the old page just leaves.
                // ---- nav section switch: old content drops out almost at once
                replaceEnter: Transition {}
                replaceExit: Transition {
                    PropertyAction { property: "headerVisible"; value: false }   // title switches instantly
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFaster }
                }
                // ---- open sub page: old content slides a little left and fades
                pushEnter: Transition {}
                pushExit: Transition {
                    PropertyAction { property: "headerVisible"; value: false }   // title switches instantly
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFast
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.accelerate }
                    NumberAnimation { property: "x"; from: 0; to: -Theme.drillOffset; duration: Theme.durFast
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.accelerate }
                }
                // ---- back: mirror of drill-in
                popEnter: Transition {}
                popExit: Transition {
                    PropertyAction { property: "headerVisible"; value: false }   // title switches instantly
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durFast
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.accelerate }
                    NumberAnimation { property: "x"; from: 0; to: Theme.drillOffset; duration: Theme.durFast
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.accelerate }
                }
            }
        }
    }

    // 1px window outline (follows the rounded corners)
    Rectangle {
        anchors.fill: parent
        radius: win.cornerRadius
        color: "transparent"
        border.color: Theme.windowBorder
        visible: !win.maximized
        z: 100
    }

    // Resize handles (frameless window)
    Item {
        anchors.fill: parent
        visible: !win.maximized
        z: 101
        readonly property int m: 6
        MouseArea { x: 0; y: parent.m; width: parent.m; height: parent.height - 2 * parent.m
            cursorShape: Qt.SizeHorCursor; onPressed: win.startSystemResize(Qt.LeftEdge) }
        MouseArea { x: parent.width - parent.m; y: parent.m; width: parent.m; height: parent.height - 2 * parent.m
            cursorShape: Qt.SizeHorCursor; onPressed: win.startSystemResize(Qt.RightEdge) }
        MouseArea { x: parent.m; y: 0; width: parent.width - 2 * parent.m; height: 4
            cursorShape: Qt.SizeVerCursor; onPressed: win.startSystemResize(Qt.TopEdge) }
        MouseArea { x: parent.m; y: parent.height - parent.m; width: parent.width - 2 * parent.m; height: parent.m
            cursorShape: Qt.SizeVerCursor; onPressed: win.startSystemResize(Qt.BottomEdge) }
        MouseArea { x: 0; y: 0; width: parent.m; height: parent.m
            cursorShape: Qt.SizeFDiagCursor; onPressed: win.startSystemResize(Qt.LeftEdge | Qt.TopEdge) }
        MouseArea { x: parent.width - parent.m; y: 0; width: parent.m; height: parent.m
            cursorShape: Qt.SizeBDiagCursor; onPressed: win.startSystemResize(Qt.RightEdge | Qt.TopEdge) }
        MouseArea { x: 0; y: parent.height - parent.m; width: parent.m; height: parent.m
            cursorShape: Qt.SizeBDiagCursor; onPressed: win.startSystemResize(Qt.LeftEdge | Qt.BottomEdge) }
        MouseArea { x: parent.width - parent.m; y: parent.height - parent.m; width: parent.m; height: parent.m
            cursorShape: Qt.SizeFDiagCursor; onPressed: win.startSystemResize(Qt.RightEdge | Qt.BottomEdge) }
    }
}
