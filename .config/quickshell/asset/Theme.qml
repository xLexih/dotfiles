pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: theme

    readonly property color primary_: "{{quickshell_primary}}"
    readonly property color secondary_: "{{quickshell_secondary}}"
    readonly property color secondaryBright_: "{{quickshell_secondary_bright}}"

    property color primary: primary_
    property color secondary: secondary_
}
