pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Colors of the current theme, read from ~/.config/theme/palette.json. The
// file is watched, so the bar recolors as soon as `theme` switches.
Singleton {
    id: root

    readonly property string name: adapter.name
    readonly property var palette: adapter.palette
    readonly property var roles: adapter.roles

    readonly property color background: palette.bg ?? "#1a1024"
    readonly property color backgroundDark: palette.bgDark ?? "#130c1b"
    readonly property color backgroundDarker: palette.bgDarker ?? "#0d0812"
    readonly property color surface: palette.surface ?? "#251735"
    readonly property color border: roles.border ?? "#38274d"
    readonly property color text: palette.fg ?? "#eee6f8"
    readonly property color muted: palette.fgMuted ?? "#b0a4c8"
    readonly property color accent: palette.accent ?? "#c6a0ff"
    readonly property color accentAlt: palette.accentAlt ?? "#8bd5ca"
    readonly property color accentBright: palette.accentBright ?? "#e2c7ff"
    readonly property color selection: roles.selectionBg ?? "#c6a0ff"
    readonly property color selectionText: roles.selectionFg ?? "#0d0812"
    readonly property color danger: palette.red ?? "#f38ba8"
    readonly property color warning: palette.yellow ?? "#f9e2af"

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
        path: Quickshell.env("HOME") + "/.config/theme/palette.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property string name: ""
            property var palette: ({})
            property var roles: ({})
        }
    }
}
