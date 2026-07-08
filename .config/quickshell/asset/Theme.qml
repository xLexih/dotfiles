pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: theme

    readonly property color background_: "{{ui_bg}}"
    readonly property color backgroundDark_: "{{ui_bg_dark}}"
    readonly property color backgroundDarker_: "{{ui_bg_darker}}"
    readonly property color surface_: "{{ui_surface}}"
    readonly property color border_: "{{role_border}}"
    readonly property color text_: "{{ui_fg}}"
    readonly property color muted_: "{{ui_fg_muted}}"
    readonly property color accent_: "{{ui_accent}}"
    readonly property color accentAlt_: "{{ui_accent_alt}}"
    readonly property color accentBright_: "{{ui_accent_bright}}"
    readonly property color selection_: "{{role_selection_bg}}"
    readonly property color selectionText_: "{{role_selection_fg}}"
    readonly property color primary_: surface_
    readonly property color secondary_: accent_
    readonly property color secondaryBright_: accentBright_
    readonly property int innerCornerRadius_: 14
    readonly property int outlineThickness_: 5
    readonly property int sidebarWidth_: 25
    readonly property int logoSize_: 25
    readonly property color collisionColor_: "transparent"

    property color primary: primary_
    property color secondary: secondary_
    property color background: background_
    property color backgroundDark: backgroundDark_
    property color backgroundDarker: backgroundDarker_
    property color surface: surface_
    property color border: border_
    property color text: text_
    property color muted: muted_
    property color accent: accent_
    property color accentAlt: accentAlt_
    property color accentBright: accentBright_
    property color selection: selection_
    property color selectionText: selectionText_
    property int innerCornerRadius: innerCornerRadius_
    property int outlineThickness: outlineThickness_
    property int sidebarWidth: sidebarWidth_
    property int logoSize: logoSize_
    property color collisionColor: collisionColor_
}
