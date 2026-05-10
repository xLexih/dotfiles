import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  id: root

  // add a property in the root
  property string time

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData
        
        anchors {
          left: true
        }
        implicitWidth: 25
        implicitHeight: Screen.height
        
      }
    }
  }

  Process {
    id: oijasdijfad
    command: ["date"]
    running: true

    stdout: StdioCollector {
      // update the property instead of the clock directly
      onStreamFinished: root.time = this.text
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: oijasdijfad.running = true
  }
}