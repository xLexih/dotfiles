pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../asset" as Asset

// Checklist section of the notification center.
Column {
    id: root

    spacing: 6

    Item {
        width: parent.width
        height: 18

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Reminders"
            color: Asset.Theme.muted
            font.pixelSize: 10
            font.weight: Font.Medium
            font.letterSpacing: 0.8
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Asset.Reminders.pending === 0 ? "" : Asset.Reminders.pending + " pending"
            color: Asset.Theme.muted
            font.pixelSize: 10
            opacity: 0.7
        }
    }

    Repeater {
        model: Asset.Reminders.items

        delegate: Item {
            required property var modelData

            width: root.width
            height: 24

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: rowHover.hovered ? Asset.Theme.hover : "transparent"
            }

            HoverHandler {
                id: rowHover
            }

            Text {
                id: checkbox

                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.done ? "check_box" : "check_box_outline_blank"
                color: modelData.done ? Asset.Theme.muted : Asset.Theme.secondary
                font.family: Asset.Theme.iconFont
                font.pixelSize: 15

                ToolTip.visible: checkHover.hovered
                ToolTip.text: modelData.done ? "Mark as pending" : "Mark as done"

                HoverHandler {
                    id: checkHover
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: Asset.Reminders.toggle(modelData.id)
                }
            }

            Text {
                anchors.left: checkbox.right
                anchors.leftMargin: 8
                anchors.right: removeButton.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.text
                color: modelData.done ? Asset.Theme.muted : Asset.Theme.text
                font.pixelSize: 11
                font.strikeout: modelData.done
                elide: Text.ElideRight
            }

            Text {
                id: removeButton

                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: "close"
                color: removeHover.hovered ? Asset.Theme.danger : "transparent"
                font.family: Asset.Theme.iconFont
                font.pixelSize: 13

                ToolTip.visible: removeHover.hovered
                ToolTip.text: "Remove reminder"

                HoverHandler {
                    id: removeHover
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: Asset.Reminders.remove(modelData.id)
                }
            }
        }
    }

    TextField {
        id: reminderInput

        width: parent.width
        placeholderText: "Add a reminder"
        color: Asset.Theme.text
        font.pixelSize: 11
        leftPadding: 8
        rightPadding: 8
        topPadding: 4
        bottomPadding: 4
        selectByMouse: true

        background: Rectangle {
            implicitHeight: 26
            radius: 6
            color: Asset.Theme.backgroundDarker
            border.width: 1
            border.color: reminderInput.activeFocus ? Asset.Theme.accent : Asset.Theme.border
        }

        onAccepted: {
            Asset.Reminders.add(reminderInput.text);
            reminderInput.text = "";
        }
    }
}
