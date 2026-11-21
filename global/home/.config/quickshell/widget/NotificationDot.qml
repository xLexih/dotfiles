import Quickshell
import QtQuick
import "../asset" as Asset

// Orange dot in the top-right corner. It pulses while notifications are
// unread and opens the center for the screen it sits on.
Item {
    id: root

    required property string screenName
    required property var tooltip

    readonly property bool unread: Asset.Notifications.hasUnread
    readonly property bool any: Asset.Notifications.count > 0
    readonly property bool openHere: Asset.Notifications.open && Asset.Notifications.openScreen === root.screenName
    readonly property int tooltipEdge: Edges.Left
    readonly property string tooltipText: {
        if (Asset.Notifications.dnd)
            return "Do not disturb";
        if (Asset.Notifications.count === 0)
            return "Notifications";
        const unread = Asset.Notifications.unreadCount;
        return Asset.Notifications.count + (Asset.Notifications.count === 1 ? " notification" : " notifications") + (unread > 0 ? ", " + unread + " unread" : "");
    }

    property bool pulse: false

    implicitWidth: 20
    implicitHeight: 20

    Timer {
        interval: 600
        repeat: true
        running: root.unread
        onTriggered: root.pulse = !root.pulse
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 2
        width: 8
        height: 8
        radius: 4
        color: Asset.Notifications.dnd ? Asset.Theme.muted : root.unread ? (root.pulse ? Asset.Theme.attentionBright : Asset.Theme.attention) : root.any || root.openHere ? Asset.Theme.attention : Asset.Theme.muted
        opacity: root.any || root.openHere || root.unread ? 1 : 0.35

        Behavior on color {
            ColorAnimation { duration: 140 }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Asset.Notifications.toggleOn(root.screenName)
        onContainsMouseChanged: containsMouse ? root.tooltip.show(root) : root.tooltip.hide(root)
    }
}
