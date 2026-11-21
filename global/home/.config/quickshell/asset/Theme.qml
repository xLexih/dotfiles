pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Colors of the current theme from ~/.config/theme/theme.json, which `theme`
// installs on every switch and rebuild. The file is watched, so the bar
// recolors as soon as the theme changes.
Singleton {
    id: root

    readonly property string name: adapter.label
    readonly property var colors: adapter.colors

    // theme.json loads after the first evaluation; without a fallback every
    // color logged "Unable to assign [undefined] to QColor" at startup.
    readonly property color background: colors.bg ?? "transparent"
    readonly property color backgroundDark: colors.bgDark ?? "transparent"
    readonly property color backgroundDarker: colors.bgDarker ?? "transparent"
    readonly property color surface: colors.surface ?? "transparent"
    readonly property color border: colors.border ?? "transparent"
    readonly property color text: colors.fg ?? "transparent"
    readonly property color muted: colors.fgMuted ?? "transparent"
    readonly property color accent: colors.accent ?? "transparent"
    readonly property color accentAlt: colors.accentAlt ?? "transparent"
    readonly property color accentBright: colors.accentBright ?? "transparent"
    readonly property color selection: colors.selectionBg ?? "transparent"
    readonly property color selectionText: colors.selectionFg ?? "transparent"
    readonly property color danger: colors.red ?? "transparent"
    readonly property color warning: colors.yellow ?? "transparent"
    // No theme has an orange role. The notification dot keeps this color so
    // it reads as "attention" on every theme, light or dark.
    readonly property color attention: "#f59e0b"
    readonly property color attentionBright: "#fbbf24"

    // Hover tint for flat list rows (the center's rows sit on the panel).
    readonly property color hover: colors.hoverBg ?? "transparent"

    readonly property string iconFont: "Material Symbols Rounded"

    // Screen frame
    readonly property color primary: surface
    readonly property color secondary: accent
    readonly property color secondaryBright: accentBright
    readonly property color collisionColor: "transparent"
    readonly property int innerCornerRadius: 14
    readonly property int outlineThickness: 5
    readonly property int sidebarWidth: 28

    FileView {
        path: Quickshell.env("HOME") + "/.config/theme/theme.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property string label: ""
            property var colors: ({})
        }
    }
}
