import Quickshell
import QtQml
import QtQuick

Item {
    Connections {
        target: Quickshell

        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup()
        }

        function onReloadFailed(errorString) {
            console.error(errorString)
            Quickshell.inhibitReloadPopup()
        }
    }
}
