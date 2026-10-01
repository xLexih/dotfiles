pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../asset" as Asset

// Workspaces on this screen's monitor as pills; the active one is stretched.
// Click to switch, scroll to step through them.
Column {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var workspaces: Hyprland.workspaces.values.filter(workspace => workspace.id > 0 && workspace.monitor === root.monitor).sort((a, b) => a.id - b.id)
    property real wheelDelta: 0

    width: Asset.Theme.sidebarWidth
    spacing: 6

    Repeater {
        model: root.workspaces

        delegate: Rectangle {
            id: pill

            required property HyprlandWorkspace modelData
            readonly property bool active: modelData === root.monitor?.activeWorkspace

            anchors.horizontalCenter: parent.horizontalCenter
            width: 8
            height: active ? 24 : 8
            radius: 4
            color: modelData.urgent ? Asset.Theme.danger : active ? Asset.Theme.secondary : hover.hovered ? Asset.Theme.secondaryBright : Asset.Theme.muted
            opacity: active || hover.hovered || modelData.urgent ? 1 : 0.55

            Behavior on height {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            // Larger hit area than the 8px pill.
            Item {
                anchors.centerIn: parent
                width: Asset.Theme.sidebarWidth
                height: parent.height + root.spacing

                HoverHandler {
                    id: hover
                }

                TapHandler {
                    onTapped: pill.modelData.activate()
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => {
            root.wheelDelta += event.angleDelta.y;
            const steps = Math.trunc(root.wheelDelta / 120);
            if (steps === 0)
                return;
            root.wheelDelta -= steps * 120;
            const current = root.workspaces.indexOf(root.monitor?.activeWorkspace);
            const next = root.workspaces[Math.max(0, Math.min(root.workspaces.length - 1, current - steps))];
            if (next)
                next.activate();
        }
    }
}
