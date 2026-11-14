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
    color: Theme.windowBg

    property int navIndex: 0
    readonly property bool maximized: visibility === Window.Maximized

    function goTo(i) {
        navIndex = i
        const n = Data.nav[i]
        stack.clear(StackView.Immediate)
        stack.push(Qt.resolvedUrl(n.page), n.props || {})
    }

    Component.onCompleted: goTo(0)

    Connections {
        target: Router
        function onOpen(page, props) { stack.push(Qt.resolvedUrl(page), props || {}) }
        function onBack() { if (stack.depth > 1) stack.pop() }
        function onOpenNav(index) { win.goTo(index) }
    }

    Shortcut { sequences: [StandardKey.Back, "Alt+Left"]; onActivated: Router.back() }
    Shortcut { sequence: "Ctrl+F"; onActivated: nav.focusSearch() }

    // Fake Mica: warm tint fading in from the right, like the real thing
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.micaTint }
        }
    }

    property Transition enterAnim: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "y"; from: 28; to: 0; duration: 300; easing.type: Easing.OutCubic }
        }
    }
    property Transition exitAnim: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 90 }
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
                pushEnter: win.enterAnim
                pushExit: win.exitAnim
                popEnter: win.enterAnim
                popExit: win.exitAnim
                replaceEnter: win.enterAnim
                replaceExit: win.exitAnim
            }
        }
    }

    // 1px window outline
    Rectangle {
        anchors.fill: parent
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
