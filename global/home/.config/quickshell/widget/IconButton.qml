import QtQuick
import QtQuick.Controls
import "../asset" as Asset

// Small material icon button used in the notification center header.
Item {
    id: root

    property string icon
    property string tip
    property color color: Asset.Theme.muted
    property bool enabled: true

    signal clicked

    implicitWidth: 24
    implicitHeight: 24
    opacity: enabled ? 1 : 0.35

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Asset.Theme.iconFont
        font.pixelSize: 16
        color: hover.hovered ? Asset.Theme.secondaryBright : root.color

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    HoverHandler {
        id: hover
        enabled: root.enabled
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.clicked()
    }

    ToolTip.visible: hover.hovered
    ToolTip.text: root.tip
}
