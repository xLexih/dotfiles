import Quickshell
import QtQuick
import "../asset" as Asset

// Label shown to the right of the hovered sidebar item. The item needs a
// `tooltipText` property; the label follows it while the pointer stays.
PopupWindow {
    id: root

    property var target: null

    function show(item) {
        root.target = item;
        root.anchor.updateAnchor();
    }

    function hide(item) {
        if (root.target === item)
            root.target = null;
    }

    visible: target !== null && target.tooltipText !== ""
    anchor.item: target
    anchor.edges: Edges.Right
    anchor.gravity: Edges.Right
    color: "transparent"
    implicitWidth: label.implicitWidth + 28
    implicitHeight: label.implicitHeight + 12

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 8
        radius: 7
        color: Asset.Theme.backgroundDark
        border.color: Asset.Theme.border
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: root.target ? root.target.tooltipText : ""
            color: Asset.Theme.text
            font.pixelSize: 12
        }
    }
}
