pragma Singleton

import Quickshell
import QtQuick

// Colors are filled in from the active NixOS theme.
Singleton {
    readonly property color background: "{{theme.bg}}"
    readonly property color backgroundDark: "{{theme.bgDark}}"
    readonly property color backgroundDarker: "{{theme.bgDarker}}"
    readonly property color surface: "{{theme.surface}}"
    readonly property color border: "{{theme.border}}"
    readonly property color text: "{{theme.fg}}"
    readonly property color muted: "{{theme.fgMuted}}"
    readonly property color accent: "{{theme.accent}}"
    readonly property color accentAlt: "{{theme.accentAlt}}"
    readonly property color accentBright: "{{theme.accentBright}}"
    readonly property color selection: "{{theme.selectionBg}}"
    readonly property color selectionText: "{{theme.selectionFg}}"
    readonly property color danger: "{{theme.red}}"
    readonly property color warning: "{{theme.yellow}}"

    readonly property string iconFont: "Material Symbols Rounded"

    // Screen frame
    readonly property color primary: surface
    readonly property color secondary: accent
    readonly property color secondaryBright: accentBright
    readonly property color collisionColor: "transparent"
    readonly property int innerCornerRadius: 14
    readonly property int outlineThickness: 5
    readonly property int sidebarWidth: 28
}
