pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: theme

    readonly property color primary_: "{{quickshell_primary}}"
    readonly property color secondary_: "{{quickshell_secondary}}"
    readonly property color secondaryBright_: "{{quickshell_secondary_bright}}"
    readonly property int innerCornerRadius_: 14
    readonly property int outlineThickness_: 5
    readonly property int sidebarWidth_: 25
    readonly property int logoSize_: 25
    readonly property color collisionColor_: "transparent"

    property color primary: primary_
    property color secondary: secondary_
    property int innerCornerRadius: innerCornerRadius_
    property int outlineThickness: outlineThickness_
    property int sidebarWidth: sidebarWidth_
    property int logoSize: logoSize_
    property color collisionColor: collisionColor_
}
