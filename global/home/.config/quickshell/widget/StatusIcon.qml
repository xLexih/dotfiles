import QtQuick
import "../asset" as Asset

// A Material Symbols icon in the sidebar. Reports clicks and whole wheel
// notches; touchpad scrolling is accumulated into notches.
Item {
    id: root

    required property var tooltip
    property string icon
    property string tooltipText
    property color color: Asset.Theme.secondary
    property real wheelDelta: 0

    signal clicked(int button)
    signal scrolled(int steps)

    implicitWidth: Asset.Theme.sidebarWidth
    implicitHeight: 24

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: mouse.containsMouse ? Asset.Theme.secondaryBright : root.color
        font.family: Asset.Theme.iconFont
        font.pixelSize: 18

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: event => root.clicked(event.button)
        onContainsMouseChanged: containsMouse ? root.tooltip.show(root) : root.tooltip.hide(root)
        onWheel: event => {
            root.wheelDelta += event.angleDelta.y;
            const steps = Math.trunc(root.wheelDelta / 120);
            if (steps !== 0) {
                root.wheelDelta -= steps * 120;
                root.scrolled(steps);
            }
        }
    }
}
