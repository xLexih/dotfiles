// qmllint disable uncreatable-type
import Quickshell
import QtQuick
import "widget" as Widget
import "asset" as Asset

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            implicitWidth: 32
            implicitHeight: screen.height
            color: Asset.Theme.primary

            anchors {
                left: true
                top: true
                bottom: true
            }

            Rectangle {
                anchors.fill: parent
                color: Asset.Theme.primary
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }

                implicitHeight: 48
                color: "transparent"

                SystemClock {
                    id: clock
                    precision: SystemClock.Seconds
                }

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(clock.date, "hh\nmm")
                    color: Asset.Theme.secondary
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                implicitHeight: 48
                color: "transparent"

                Widget.Gear {
                    anchors.centerIn: parent
                    from_color: Qt.lighter(Asset.Theme.primary_, 1.2)
                    to_color: Asset.Theme.secondaryBright_
                }
            }
        }
    }
}
