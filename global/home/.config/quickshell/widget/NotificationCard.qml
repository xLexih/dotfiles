pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import "../asset" as Asset

// One tracked notification in the center: a flat row on the panel background,
// not a card. Hover tints; urgency shows as a small marker next to the app.
Rectangle {
    id: root

    required property var notification
    property double now: Date.now() / 1000

    readonly property var n: root.notification
    readonly property bool critical: root.n.urgency === NotificationUrgency.Critical
    readonly property bool unread: Asset.Notifications.unread.indexOf(root.n) >= 0
    readonly property string iconSource: {
        const icon = root.n.appIcon ?? "";
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        return Quickshell.iconPath(icon, true);
    }
    readonly property double postedAt: root.n.arrivedAt ?? 0
    readonly property string timeText: root.formatAge(root.postedAt, root.now)

    function formatAge(posted, now) {
        if (posted <= 0)
            return "";
        const age = Math.max(0, Math.floor(now - posted));
        if (age < 60)
            return "now";
        if (age < 3600)
            return Math.floor(age / 60) + "m";
        if (age < 86400)
            return Math.floor(age / 3600) + "h";
        return Math.floor(age / 86400) + "d";
    }

    implicitHeight: content.implicitHeight + 16
    radius: 8
    color: hover.hovered ? Asset.Theme.hover : "transparent"

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Asset.Notifications.invoke(root.n)
    }

    Column {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 3

        Item {
            width: parent.width
            height: 18

            Rectangle {
                id: urgencyDot

                readonly property bool show: root.critical || root.unread

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: root.critical ? Asset.Theme.danger : Asset.Theme.attention
                visible: show
            }

            IconImage {
                id: appIcon

                anchors.left: urgencyDot.visible ? urgencyDot.right : parent.left
                anchors.leftMargin: urgencyDot.visible ? 5 : 0
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                implicitSize: 14
                source: root.iconSource
                visible: root.iconSource !== "" && status === Image.Ready
            }

            Text {
                id: appName

                anchors.left: appIcon.visible ? appIcon.right : (urgencyDot.visible ? urgencyDot.right : parent.left)
                anchors.leftMargin: appIcon.visible ? 5 : (urgencyDot.visible ? 5 : 0)
                anchors.verticalCenter: parent.verticalCenter
                text: root.n.appName || "Notification"
                color: Asset.Theme.muted
                font.pixelSize: 10
            }

            Text {
                id: timeLabel

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeText
                color: Asset.Theme.muted
                font.pixelSize: 10
            }

            Text {
                id: dismissButton

                anchors.right: timeLabel.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: hover.hovered
                text: "close"
                color: dismissHover.hovered ? Asset.Theme.danger : Asset.Theme.muted
                font.family: Asset.Theme.iconFont
                font.pixelSize: 13

                ToolTip.visible: dismissHover.hovered
                ToolTip.text: "Dismiss notification"

                HoverHandler {
                    id: dismissHover
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: Asset.Notifications.dismiss(root.n)
                }
            }
        }

        Text {
            width: parent.width
            text: root.n.summary || root.n.appName || "Notification"
            color: Asset.Theme.text
            font.pixelSize: 12
            font.weight: root.unread ? Font.DemiBold : Font.Medium
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: Asset.Notifications.safeBody(root.n.body)
            textFormat: Text.StyledText
            color: Asset.Theme.muted
            linkColor: Asset.Theme.accent
            font.pixelSize: 11
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            onLinkActivated: link => {
                if (link.startsWith("http://") || link.startsWith("https://"))
                    Qt.openUrlExternally(link);
            }
        }

        Row {
            width: parent.width
            spacing: 6
            visible: actions.count > 0

            topPadding: 2

            Repeater {
                id: actions

                model: root.n.actions ?? []

                delegate: Rectangle {
                    required property var modelData

                    implicitWidth: actionLabel.implicitWidth + 14
                    implicitHeight: 22
                    radius: 11
                    color: actionHover.hovered ? Asset.Theme.surface : Asset.Theme.hover

                    Text {
                        id: actionLabel

                        anchors.centerIn: parent
                        text: modelData.text
                        color: Asset.Theme.text
                        font.pixelSize: 10
                    }

                    HoverHandler {
                        id: actionHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
