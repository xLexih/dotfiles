import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../asset" as Asset

Item {
    id: root

    readonly property string filePath: "/tmp/note.md"
    property bool active: false

    function toggle() {
        if (root.active) {
            windowLoader.item.save()
        } else {
            root.active = true
        }
    }

    Loader {
        id: windowLoader
        active: root.active
        sourceComponent: noteWindowComponent
    }

    Component {
        id: noteWindowComponent

        FloatingWindow {
            id: popup

            title: "Notes"
            implicitWidth: 320
            implicitHeight: 400
            color: Asset.Theme.primary
            visible: true

            onVisibleChanged: {
                if (!visible) {
                    popup.save()
                }
            }

            function save() {
                saveProc.command = ["sh", "-c", "printf '%s' \"$1\" > " + root.filePath, "sh", noteArea.text]
                saveProc.running = true
            }

            FileView {
                id: fileView
                path: root.filePath
                preload: true
                blockLoading: true
                blockAllReads: true
            }

            Component.onCompleted: {
                noteArea.text = fileView.text()
                noteArea.cursorPosition = noteArea.length
                noteArea.forceActiveFocus()
            }

            property int fontSize: 12
            property bool markdownMode: false

            Process {
                id: saveProc
                onExited: {
                    if (!popup.visible) root.active = false
                }
            }

            Shortcut {
                sequence: "Ctrl+S"
                onActivated: popup.save()
            }

            Shortcut {
                sequence: "Ctrl+="
                onActivated: popup.fontSize = Math.min(popup.fontSize + 2, 128)
            }

            Shortcut {
                sequence: "Ctrl+-"
                onActivated: popup.fontSize = Math.max(popup.fontSize - 2, 8)
            }

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Item {
                    width: parent.width
                    height: 16

                    Text {
                        text: "Notes"
                        color: Asset.Theme.secondary
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Text {
                        anchors.right: parent.right
                        text: popup.markdownMode ? "md" : "txt"
                        color: Asset.Theme.secondary
                        font.pixelSize: 11
                        opacity: 0.7

                        TapHandler {
                            onTapped: popup.markdownMode = !popup.markdownMode
                        }
                    }
                }

                Flickable {
                    width: parent.width
                    height: parent.height - 26
                    contentHeight: noteArea.implicitHeight
                    clip: true
                    flickableDirection: Flickable.VerticalFlick

                    ScrollBar.vertical: ScrollBar {}

                    TextEdit {
                        id: noteArea
                        width: parent.width
                        color: Asset.Theme.secondary
                        font.pixelSize: popup.fontSize
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        focus: true
                        textFormat: popup.markdownMode ? TextEdit.MarkdownText : TextEdit.PlainText
                    }
                }
            }
        }
    }
}
