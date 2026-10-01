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

    readonly property color background: colors.bg
    readonly property color backgroundDark: colors.bgDark
    readonly property color backgroundDarker: colors.bgDarker
    readonly property color surface: colors.surface
    readonly property color border: colors.border
    readonly property color text: colors.fg
    readonly property color muted: colors.fgMuted
    readonly property color accent: colors.accent
    readonly property color accentAlt: colors.accentAlt
    readonly property color accentBright: colors.accentBright
    readonly property color selection: colors.selectionBg
    readonly property color selectionText: colors.selectionFg
    readonly property color danger: colors.red
    readonly property color warning: colors.yellow

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
