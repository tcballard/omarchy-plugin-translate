import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root
  moduleName: "io.github.tcballard.bartranslate"
  readonly property bool opened: panel.opened
  readonly property bool popoutSwitchClosing: panel.popoutSwitchClosing
  readonly property real openPanelIndicatorWidth: button.labelWidth
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  activeFocusOnTab: true
  function open() { panel.open() }
  function close() { panel.close() }
  function closeForPopoutSwitch() { panel.closeForPopoutSwitch() }
  function toggle() { opened ? close() : open() }
  Keys.onReturnPressed: toggle()
  Keys.onSpacePressed: toggle()
  Panel {
    id: panel
    bar: root.bar
    settings: root.settings
    anchorItem: button
    hostWidget: root
  }
  IpcHandler {
    target: root.moduleName
    function demo(): void { panel.showDemo() }
    function clipboard(): void { panel.open(); panel.pasteClipboard() }
  }
  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf1ab"
    fontSize: Style.font.icon
    active: root.opened || root.activeFocus
    tooltipText: "Translate · right-click to paste clipboard"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) { panel.open(); panel.pasteClipboard() }
      else if (mouseButton === Qt.LeftButton) root.toggle()
    }
  }
}
