pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../asset" as Asset

// Registered `project-cleanup` projects and their countdown. Flat rows on the
// panel background; the state is colored, the name stays quiet.
Column {
    id: root

    property double now: Date.now() / 1000

    spacing: 6

    Item {
        width: parent.width
        height: 18

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Projects"
            color: Asset.Theme.muted
            font.pixelSize: 10
            font.weight: Font.Medium
            font.letterSpacing: 0.8
        }

        Text {
            anchors.right: sortButton.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: Asset.Projects.activeCount === 0 ? "" : Asset.Projects.activeCount + " active"
            color: Asset.Theme.muted
            font.pixelSize: 10
            opacity: 0.7
        }

        Text {
            id: sortButton

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Asset.Projects.sortOrder === "latest" ? "schedule" : "history"
            color: sortHover.hovered ? Asset.Theme.secondaryBright : Asset.Theme.muted
            font.family: Asset.Theme.iconFont
            font.pixelSize: 14

            ToolTip.visible: sortHover.hovered
            ToolTip.text: Asset.Projects.sortOrder === "latest" ? "Sort by oldest activity" : "Sort by latest activity"

            HoverHandler {
                id: sortHover
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                onClicked: Asset.Projects.toggleSort()
            }
        }
    }

    Repeater {
        model: Asset.Projects.sorted

        delegate: Rectangle {
            id: project

            required property var modelData

            readonly property string stateText: {
                if (modelData.state === "in_use")
                    return "in use";
                if (modelData.state === "due_in")
                    return Asset.Projects.formatDuration(modelData.due_at - root.now) + " left";
                if (modelData.state === "due")
                    return "due";
                return modelData.state;
            }
            readonly property color stateColor: modelData.state === "failed" ? Asset.Theme.danger : modelData.state === "due" ? Asset.Theme.warning : modelData.state === "in_use" ? Asset.Theme.secondary : Asset.Theme.muted

            width: root.width
            height: 28
            radius: 6
            color: projectHover.hovered ? Asset.Theme.hover : "transparent"

            HoverHandler {
                id: projectHover
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (modelData.state !== "missing")
                        Asset.Projects.openTerminal(modelData.path);
                }
            }

            Rectangle {
                id: stateDot

                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: project.stateColor
            }

            Text {
                anchors.left: stateDot.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - stateLabel.width - cleanButton.width - 44
                text: modelData.name
                color: Asset.Theme.text
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                id: stateLabel

                anchors.right: cleanButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: project.stateText
                color: project.stateColor
                font.pixelSize: 10
            }

            Text {
                id: cleanButton

                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: "mop"
                color: cleanHover.hovered ? Asset.Theme.secondaryBright : Asset.Theme.muted
                font.family: Asset.Theme.iconFont
                font.pixelSize: 13

                ToolTip.visible: cleanHover.hovered
                ToolTip.text: "Clean now (stop containers, run cleanup)"

                HoverHandler {
                    id: cleanHover
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: Asset.Projects.cleanNow(modelData.path)
                }
            }
        }
    }

    Text {
        width: parent.width
        visible: Asset.Projects.projects.length === 0
        text: "No registered projects"
        color: Asset.Theme.muted
        font.pixelSize: 10
    }

    Text {
        width: parent.width
        visible: Asset.Projects.error !== ""
        text: Asset.Projects.error
        color: Asset.Theme.danger
        font.pixelSize: 10
    }
}
