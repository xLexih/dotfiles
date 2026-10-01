pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import "../asset" as Asset

// System tray. Left click activates, middle click is the secondary action,
// right click (or any click on menu-only items) opens the item's menu.
Column {
    id: root

    required property var tooltip

    width: Asset.Theme.sidebarWidth
    spacing: 8

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: entry

            required property SystemTrayItem modelData
            readonly property string tooltipText: modelData.tooltipTitle || modelData.title || modelData.id

            anchors.horizontalCenter: parent.horizontalCenter
            width: 18
            height: 18

            IconImage {
                anchors.fill: parent
                source: entry.modelData.icon
                asynchronous: true
            }

            QsMenuAnchor {
                id: menu
                menu: entry.modelData.menu
                anchor.item: entry
                anchor.edges: Edges.Right
                anchor.gravity: Edges.Right
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                onContainsMouseChanged: containsMouse ? root.tooltip.show(entry) : root.tooltip.hide(entry)
                onWheel: event => entry.modelData.scroll(event.angleDelta.y, false)
                onClicked: event => {
                    root.tooltip.hide(entry);
                    if (event.button === Qt.MiddleButton)
                        entry.modelData.secondaryActivate();
                    else if (event.button === Qt.LeftButton && !entry.modelData.onlyMenu)
                        entry.modelData.activate();
                    else if (entry.modelData.hasMenu)
                        menu.open();
                }
            }
        }
    }
}
