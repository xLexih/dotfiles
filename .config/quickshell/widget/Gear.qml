pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.VectorImage
import "../asset" as Asset

Item {
    id: root

    property real spin_speed: 0
    property real current_rotation: 0
    property int hover_time: 0
    property int unhover_time: 0

    property int tick_interval: 16
    property int hover_start_ticks: 10
    property int unhover_start_ticks: 10
    property real accel_step: 0.8
    property real decel_step: 0.3
    property real max_spin_speed: 18

    property color from_color: Asset.Theme.secondary_
    property color to_color: Asset.Theme.secondaryBright_

    readonly property real spin_progress: root.clamp_01(root.spin_speed / root.max_spin_speed)
    readonly property color spin_color: root.blend_color(root.from_color, root.to_color, root.spin_progress)

    width: 32
    height: width

    function clamp_01(value) {
        return Math.max(0, Math.min(1, value));
    }

    function lerp(a, b, t) {
        return a + (b - a) * t;
    }

    function blend_color(from, to, t) {
        t = root.clamp_01(t);
        return Qt.rgba(
            root.lerp(from.r, to.r, t),
            root.lerp(from.g, to.g, t),
            root.lerp(from.b, to.b, t),
            root.lerp(from.a, to.a, t)
        );
    }

    HoverHandler {
        id: hover_handler
    }

    Timer {
        id: heartbeat
        interval: root.tick_interval
        repeat: true
        running: true

        onTriggered: {
            if (hover_handler.hovered) {
                root.hover_time = Math.min(root.hover_time + 1, root.hover_start_ticks * 2);
                root.unhover_time = 0;
            } else {
                root.unhover_time = Math.min(root.unhover_time + 1, root.unhover_start_ticks * 2);
                root.hover_time = 0;
            }

            if (root.hover_time >= root.hover_start_ticks)
                root.spin_speed = Math.min(root.spin_speed + root.accel_step, root.max_spin_speed);

            if (root.unhover_time >= root.unhover_start_ticks)
                root.spin_speed = Math.max(root.spin_speed - root.decel_step, 0);

            root.current_rotation = (root.current_rotation + root.spin_speed) % 360;
        }
    }

    VectorImage {
        anchors.fill: parent
        source: Qt.resolvedUrl("../asset/Gear_Icon.svg")
        preferredRendererType: VectorImage.CurveRenderer
        rotation: root.current_rotation

        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: root.spin_color
        }
    }
}
