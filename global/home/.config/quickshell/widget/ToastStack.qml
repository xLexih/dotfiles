pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../asset" as Asset

// Short-lived popups in the top-right corner of the focused monitor. The
// notification center keeps the tracked copy; a toast only shows and expires.
PanelWindow {
    id: root

    required property var shellScreen

    readonly property bool focused: Hyprland.focusedMonitor?.name === root.shellScreen.name
    readonly property var toasts: Asset.Notifications.toasts

    screen: root.shellScreen
    visible: root.focused && root.toasts.length > 0
    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    implicitWidth: 360
    implicitHeight: Math.min(column.implicitHeight, root.shellScreen.height * 0.6)

    anchors {
        top: true
        right: true
    }

    margins {
        top: Asset.Theme.outlineThickness + 22
        right: Asset.Theme.outlineThickness + 8
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: column }

    Column {
        id: column

        width: parent.width
        spacing: 8

        Repeater {
            model: root.toasts

            delegate: Rectangle {
                id: toast

                required property var modelData

                readonly property var n: toast.modelData
                readonly property int timeoutMs: {
                    if (toast.n.resident || toast.n.urgency === NotificationUrgency.Critical)
                        return 0;
                    const timeout = toast.n.expireTimeout;
                    return (timeout > 0 ? timeout : 6) * 1000;
                }
                readonly property string iconSource: {
                    const icon = toast.n.appIcon ?? "";
                    if (!icon)
                        return "";
                    if (icon.startsWith("/"))
                        return "file://" + icon;
                    return Quickshell.iconPath(icon, true);
                }

                width: column.width
                implicitHeight: toastContent.implicitHeight + 20
                radius: 10
                color: Asset.Theme.backgroundDark

                HoverHandler {
                    id: hover
                }

                Timer {
                    interval: toast.timeoutMs
                    running: toast.timeoutMs > 0 && !hover.hovered
                    onTriggered: Asset.Notifications.expireToast(toast.n)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Asset.Notifications.invoke(toast.n);
                        Asset.Notifications.expireToast(toast.n);
                    }
                }

                Column {
                    id: toastContent

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 4

                    Item {
                        width: parent.width
                        height: 18

                        IconImage {
                            id: toastIcon

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            implicitSize: 16
                            source: toast.iconSource
                            visible: toast.iconSource !== "" && status === Image.Ready
                        }

                        Text {
                            anchors.left: toastIcon.visible ? toastIcon.right : parent.left
                            anchors.leftMargin: toastIcon.visible ? 6 : 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: toast.n.appName || "Notification"
                            color: Asset.Theme.muted
                            font.pixelSize: 10
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "close"
                            color: toastCloseHover.hovered ? Asset.Theme.danger : Asset.Theme.muted
                            font.family: Asset.Theme.iconFont
                            font.pixelSize: 13

                            HoverHandler {
                                id: toastCloseHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                onClicked: Asset.Notifications.expireToast(toast.n)
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: toast.n.summary || toast.n.appName || "Notification"
                        color: Asset.Theme.text
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: Asset.Notifications.safeBody(toast.n.body)
                        textFormat: Text.StyledText
                        color: Asset.Theme.text
                        font.pixelSize: 10
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
