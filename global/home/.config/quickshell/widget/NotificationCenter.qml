pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../asset" as Asset

// Panel below the top-right dot. It holds reminders, the projects registered
// with `project-cleanup`, and the tracked notifications. One instance exists
// per screen; only the one the dot was clicked on is visible.
PanelWindow {
    id: root

    required property var shellScreen

    readonly property bool opened: Asset.Notifications.open && Asset.Notifications.openScreen === root.shellScreen.name
    readonly property int padding: 14
    readonly property int maxHeight: Math.max(240, Math.min(720, root.shellScreen.height - 120))
    property double now: Date.now() / 1000

    screen: root.shellScreen
    visible: root.opened
    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    focusable: root.opened

    // Full-screen surface: the panel draws at the top-right, and the rest of
    // the surface only exists to catch clicks outside the panel.
    anchors {
        top: true
        right: true
        left: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Catches clicks anywhere the panel doesn't cover; the panel's own items
    // sit on top and win the events inside its bounds.
    MouseArea {
        anchors.fill: parent
        enabled: root.opened
        onClicked: Asset.Notifications.close()
        onWheel: wheel => wheel.accepted = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.opened
        onTriggered: root.now = Date.now() / 1000
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.opened
        onActivated: Asset.Notifications.close()
    }

    Rectangle {
        id: panel

        readonly property int panelWidth: 360
        readonly property int panelHeight: Math.min(content.implicitHeight + root.padding * 2, root.maxHeight)

        // Frame matches the bar's outline language at half thickness, so the
        // floating panel reads lighter than the screen-edge bar frame.
        readonly property int frame: Math.max(2, Math.round(Asset.Theme.outlineThickness / 2))

        x: parent.width - panelWidth - Asset.Theme.outlineThickness - 8
        y: Asset.Theme.outlineThickness + 22
        width: panelWidth
        height: panelHeight
        radius: Asset.Theme.innerCornerRadius + frame
        color: Asset.Theme.primary

        Rectangle {
            id: contentBg

            anchors.fill: parent
            anchors.margins: parent.frame
            radius: Asset.Theme.innerCornerRadius
            color: Asset.Theme.backgroundDark
        }

        Flickable {
            id: flick

            anchors.fill: contentBg
            anchors.rightMargin: root.padding + 8
            anchors.leftMargin: root.padding
            anchors.topMargin: root.padding
            anchors.bottomMargin: root.padding
            contentHeight: content.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // Browser-style wheel scrolling: accumulate the notch delta and
            // glide there, instead of Flickable's stepped default.
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    // Retarget from wherever the glide currently is, so
                    // fast successive notches accumulate instead of restarting.
                    const from = wheelAnim.running ? wheelAnim.to : flick.contentY;
                    flick.cancelFlick();
                    wheelAnim.from = from;
                    const target = from - event.angleDelta.y * 0.5;
                    wheelAnim.to = Math.max(0, Math.min(flick.contentHeight - flick.height, target));
                    wheelAnim.restart();
                    event.accepted = true;
                }
            }

            NumberAnimation {
                id: wheelAnim

                target: flick
                property: "contentY"
                duration: 240
                easing.type: Easing.OutCubic
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                parent: contentBg
                x: contentBg.width - 9
                y: 0
                height: contentBg.height

                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: Asset.Theme.border
                }
            }

            Column {
                id: content

                width: flick.width
                spacing: 12

                Item {
                    width: parent.width
                    height: 22

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: Asset.Theme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        IconButton {
                            icon: Asset.Notifications.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                            tip: Asset.Notifications.dnd ? "Disable do not disturb" : "Do not disturb"
                            color: Asset.Notifications.dnd ? Asset.Theme.attention : Asset.Theme.muted
                            onClicked: Asset.Notifications.dnd = !Asset.Notifications.dnd
                        }

                        IconButton {
                            icon: "delete_sweep"
                            tip: "Clear all"
                            enabled: Asset.Notifications.count > 0
                            onClicked: Asset.Notifications.clearAll()
                        }

                        IconButton {
                            icon: "close"
                            tip: "Close"
                            onClicked: Asset.Notifications.close()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Asset.Theme.border
                }

                ReminderList {
                    width: parent.width
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Asset.Theme.border
                }

                Item {
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Recent"
                        color: Asset.Theme.muted
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        font.letterSpacing: 0.8
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Asset.Notifications.count === 0 ? "" : Asset.Notifications.count + ""
                        color: Asset.Theme.muted
                        font.pixelSize: 10
                        opacity: 0.7
                    }
                }

                Repeater {
                    model: Asset.Notifications.tracked.slice().reverse()

                    delegate: NotificationCard {
                        required property var modelData

                        width: content.width
                        notification: modelData
                        now: root.now
                    }
                }

                Text {
                    width: parent.width
                    visible: Asset.Notifications.count === 0
                    text: "No notifications"
                    color: Asset.Theme.muted
                    font.pixelSize: 10
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Asset.Theme.border
                }

                ProjectList {
                    width: parent.width
                    now: root.now
                }
            }
        }
    }
}
