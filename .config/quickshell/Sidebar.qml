// qmllint disable uncreatable-type
import Quickshell
import QtQuick
import QtQuick.Effects
import "widget" as Widget
import "asset" as Asset

Scope {
    id: root

    readonly property int sidebarWidth: Asset.Theme.sidebarWidth
    readonly property int outlineThickness: Asset.Theme.outlineThickness

    // Invisible per-screen panel that reserves space on one screen edge, so
    // tiled windows don't draw under the frame. Layer-shell reserves one edge
    // per surface, hence one instance per edge below.
    component EdgeReservation: Variants {
        id: reservation
        model: Quickshell.screens

        property string edge
        property int thickness

            PanelWindow {
                required property var modelData
                readonly property bool horizontal: reservation.edge === "top" || reservation.edge === "bottom"

                screen: modelData
                implicitWidth: horizontal ? screen.width : reservation.thickness
                implicitHeight: horizontal ? reservation.thickness : screen.height
                color: "transparent"
                exclusiveZone: reservation.thickness
                mask: Region {}
                focusable: false

            anchors {
                left: reservation.edge !== "right"
                right: reservation.edge !== "left"
                top: reservation.edge !== "bottom"
                bottom: reservation.edge !== "top"
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: visualPanel
            required property var modelData

            readonly property int radius: Asset.Theme.innerCornerRadius
            readonly property int contentX: root.sidebarWidth
            readonly property int contentY: root.outlineThickness
            readonly property int contentWidth: Math.max(0, width - root.sidebarWidth - root.outlineThickness)
            readonly property int contentHeight: Math.max(0, height - 2 * root.outlineThickness)

            screen: modelData
            implicitWidth: screen.width
            implicitHeight: screen.height
            color: "transparent"
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            margins {
                left: -root.sidebarWidth
                right: -root.outlineThickness
                top: -root.outlineThickness
                bottom: -root.outlineThickness
            }

            mask: Region {
                Region {
                    x: 0
                    y: 0
                    width: root.sidebarWidth
                    height: visualPanel.height
                }

                Region {
                    x: visualPanel.contentX
                    y: 0
                    width: Math.max(0, visualPanel.width - visualPanel.contentX)
                    height: root.outlineThickness + visualPanel.radius
                }

                Region {
                    x: Math.max(0, visualPanel.width - root.outlineThickness - visualPanel.radius)
                    y: 0
                    width: root.outlineThickness + visualPanel.radius
                    height: visualPanel.height
                }

                Region {
                    x: visualPanel.contentX
                    y: Math.max(0, visualPanel.height - root.outlineThickness - visualPanel.radius)
                    width: Math.max(0, visualPanel.width - visualPanel.contentX)
                    height: root.outlineThickness + visualPanel.radius
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Asset.Theme.primary

                layer.enabled: true
                layer.smooth: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskInverted: true
                    maskSource: holeMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
            }

            Item {
                id: holeMask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                layer.smooth: true

                Rectangle {
                    x: visualPanel.contentX
                    y: visualPanel.contentY
                    width: visualPanel.contentWidth
                    height: visualPanel.contentHeight
                    radius: Math.min(visualPanel.radius, width / 2, height / 2)
                    color: "white"
                    antialiasing: true
                }
            }

            Item {
                x: 0
                y: 0
                width: root.sidebarWidth
                height: 56

                SystemClock {
                    id: clock
                    precision: SystemClock.Seconds
                }

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(clock.date, "hh\nmm")
                    color: Asset.Theme.secondary
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 0.86
                }
            }

            Rectangle {
                id: gearCollision
                x: 0
                y: visualPanel.height - root.sidebarWidth
                width: root.sidebarWidth
                height: root.sidebarWidth
                clip: true
                color: Asset.Theme.collisionColor

                Widget.Gear {
                    anchors.centerIn: parent
                    from_color: Qt.lighter(Asset.Theme.primary_, 1.2)
                    to_color: Asset.Theme.secondaryBright_
                }
            }

            Rectangle {
                x: visualPanel.width - root.outlineThickness * 4
                y: visualPanel.height - root.outlineThickness * 4
                width: root.outlineThickness * 4
                height: root.outlineThickness * 4
                color: Asset.Theme.collisionColor

                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 2
                    anchors.bottomMargin: 2
                    width: 8
                    height: 8
                    radius: 5
                    color: Asset.Theme.secondary
                }

                TapHandler {
                    id: noteTap
                    onTapped: notePopup.toggle()
                }
            }
        }
    }

    Widget.NotePopup {
        id: notePopup
    }

    // Reserve space for each side of the frame.
    EdgeReservation { edge: "left"; thickness: root.sidebarWidth }
    EdgeReservation { edge: "top"; thickness: root.outlineThickness }
    EdgeReservation { edge: "right"; thickness: root.outlineThickness }
    EdgeReservation { edge: "bottom"; thickness: root.outlineThickness }
}