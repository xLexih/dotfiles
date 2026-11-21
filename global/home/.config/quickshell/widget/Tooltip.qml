import Quickshell
import QtQuick
import "../asset" as Asset

// Label shown next to the hovered sidebar item. The item needs a
// `tooltipText` property; the label follows it while the pointer stays. An
// item can set `tooltipEdge` to Edges.Left when it sits on the right edge.
PopupWindow {
    id: root

    property var target: null
    readonly property int edge: root.target?.tooltipEdge ?? Edges.Right

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
    anchor.edges: root.edge
    anchor.gravity: root.edge
    color: "transparent"
    implicitWidth: label.implicitWidth + 28
    implicitHeight: label.implicitHeight + 12

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: root.edge === Edges.Right ? 8 : 0
        anchors.rightMargin: root.edge === Edges.Left ? 8 : 0
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
