import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui
import "Languages.js" as Languages

Ui.Panel {
  id: root
  moduleName: "io.github.tcballard.bartranslate"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  property string sourceLanguage: "auto"
  property string targetLanguage: String(setting("targetLanguage", "en"))
  property string result: ""
  property string detectedLanguage: ""
  property string errorText: ""
  property bool busy: false
  property bool demo: false
  property bool cancelled: false
  property string requestText: ""
  property string requestSource: ""
  property string requestTarget: ""
  property string requestJson: ""
  property string responseJson: ""
  property string copyLabel: "Copy"
  property bool clipboardCancelled: false
  readonly property color fg: Color.popups.text
  readonly property color muted: Qt.alpha(fg, 0.55)
  readonly property bool stale: result !== "" && (input.text !== requestText || sourceLanguage !== requestSource || targetLanguage !== requestTarget)

  function open() { controller.show(); Qt.callLater(function() { input.forceActiveFocus() }) }
  function close() {
    sourcePicker.close(); targetPicker.close()
    clipboardCancelled = true
    if (clipboard.running) clipboard.running = false
    cancel(); controller.hide()
  }
  function cancel() {
    deadline.stop()
    cancelled = true
    if (request.running) request.running = false
    busy = false
  }
  function translate() {
    if (request.running || !input.text.trim()) return
    if (input.text.length > 5000) { errorText = "Use up to 5,000 characters."; return }
    demo = false; cancelled = false; errorText = ""; result = ""; responseJson = ""; detectedLanguage = ""
    requestText = input.text; requestSource = sourceLanguage; requestTarget = targetLanguage
    requestJson = JSON.stringify({text: requestText, source: requestSource, target: requestTarget})
    busy = true; request.running = true; deadline.restart()
  }
  function pasteClipboard() {
    if (clipboard.running) return
    clipboardCancelled = false
    clipboard.running = true
  }
  function swapLanguages() {
    if (busy) return
    var source = sourceLanguage === "auto" ? detectedLanguage : sourceLanguage
    if (!source || source === targetLanguage) return
    var oldTarget = targetLanguage
    var oldInput = input.text
    sourceLanguage = oldTarget; targetLanguage = source
    input.text = result || oldInput; result = ""; detectedLanguage = ""; errorText = ""; demo = false
  }
  function copyResult() {
    if (!result || copy.running) return
    copy.running = true
  }
  function showDemo() {
    cancel(); sourceLanguage = "fr"; targetLanguage = "en"
    input.text = "Bonjour, comment allez-vous ?"
    requestText = input.text; requestSource = "fr"; requestTarget = "en"
    result = "Hello, how are you?"; detectedLanguage = "fr"; errorText = ""; demo = true
    open()
  }
  function handleKey(event) {
    if (event.key === Qt.Key_Escape) { close(); event.accepted = true }
    else if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      translate(); event.accepted = true
    }
  }

  Process {
    id: request
    command: ["/usr/bin/python3", "-E", "-s", decodeURIComponent(Qt.resolvedUrl("translate.py").toString().replace(/^file:\/\//, ""))]
    stdinEnabled: true
    onStarted: { write(root.requestJson + "\n"); stdinEnabled = false }
    stdout: StdioCollector { onStreamFinished: root.responseJson = text }
    onExited: function(exitCode) {
      deadline.stop(); request.stdinEnabled = true
      if (root.cancelled) return
      root.busy = false
      try {
        var response = JSON.parse(root.responseJson)
        if (!response.ok) { root.errorText = response.error || "Translation failed. Try again."; return }
        root.result = response.text
        root.detectedLanguage = response.detected || ""
      } catch (error) { root.errorText = "Could not translate. Try again." }
    }
  }
  Timer {
    id: deadline
    interval: 18000
    onTriggered: { root.cancel(); root.errorText = "The request timed out. Try again." }
  }
  Process {
    id: clipboard
    command: ["/usr/bin/python3", "-E", "-s", decodeURIComponent(Qt.resolvedUrl("translate.py").toString().replace(/^file:\/\//, "")), "--clipboard"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.opened || root.clipboardCancelled) return
        try {
          var data = JSON.parse(text)
          if (data.ok) { input.text = data.text; root.errorText = ""; input.forceActiveFocus() }
          else root.errorText = data.error
        } catch (error) { root.errorText = "Could not read clipboard text." }
      }
    }
  }
  Process {
    id: copy
    command: ["wl-copy", "--type", "text/plain;charset=utf-8"]
    stdinEnabled: true
    onStarted: { write(root.result); stdinEnabled = false }
    onExited: function(exitCode) { stdinEnabled = true; root.copyLabel = exitCode === 0 ? "Copied" : "Try again"; copyReset.restart() }
  }
  Timer { id: copyReset; interval: 1600; onTriggered: root.copyLabel = "Copy" }

  Ui.KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: input
    contentWidth: fittedContentWidth(Style.space(520))
    contentHeight: fittedContentHeight(Style.space(540))
    padding: Style.spacing.panelPadding

    FocusScope {
      anchors.fill: parent
      Keys.onPressed: function(event) { root.handleKey(event) }
      ColumnLayout {
        anchors.fill: parent
        spacing: Style.space(16)
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(12)
          Text { text: "\uf1ab"; color: Color.accent; font.family: Style.font.family; font.pixelSize: Style.font.display }
          ColumnLayout {
            spacing: Style.space(2)
            Text { text: "Translate"; color: root.fg; font.family: Style.font.family; font.pixelSize: Style.font.heading; font.bold: true }
            Text { text: root.demo ? "Preview" : "A little less lost in translation."; color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
          }
          Item { Layout.fillWidth: true }
          Ui.PanelActionButton { iconText: "\uf00d"; tooltipText: "Close · Esc"; focusable: true; foreground: root.fg; onClicked: root.close() }
        }
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(10)
          Ui.SearchableDropdown {
            id: sourcePicker
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "FROM"; value: root.sourceLanguage
            options: [{value: "auto", label: "Detect language"}].concat(Languages.options)
            enabled: !root.busy
            onChanged: function(value) { root.sourceLanguage = value }
          }
          Ui.PanelActionButton {
            Layout.alignment: Qt.AlignBottom
            iconText: "\uf0ec"; tooltipText: "Swap languages"; foreground: root.fg; focusable: true
            enabled: !root.busy && (root.sourceLanguage !== "auto" || root.detectedLanguage !== "")
            onClicked: root.swapLanguages()
          }
          Ui.SearchableDropdown {
            id: targetPicker
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "TO"; value: root.targetLanguage; options: Languages.options
            enabled: !root.busy
            onChanged: function(value) { root.targetLanguage = value }
          }
        }
        Ui.BorderSurface {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.minimumHeight: Style.space(110)
          color: Style.controlFill(input.activeFocus, false, root.fg, Color.accent)
          borderSpec: Border.controlSpec(input.activeFocus ? "focus" : "normal", root.fg, Color.accent)
          radius: Style.cornerRadius
          QQC.ScrollView {
            anchors.fill: parent
            anchors.margins: Style.space(12)
            clip: true
            QQC.TextArea {
              id: input
              placeholderText: "Type or paste something…"
              color: root.fg; placeholderTextColor: root.muted
              selectionColor: Style.selectionFillFor(root.fg, Color.accent)
              selectedTextColor: root.fg
              font.family: Style.font.family; font.pixelSize: Style.font.title
              wrapMode: TextEdit.Wrap; textFormat: TextEdit.PlainText
              background: null; selectByMouse: true
              Keys.onPressed: function(event) { root.handleKey(event) }
            }
          }
        }
        RowLayout {
          Layout.fillWidth: true
          Text { text: input.text.length + " / 5,000"; color: input.text.length > 5000 ? Color.urgent : root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
          Item { Layout.fillWidth: true }
          Ui.Button { text: "Paste"; iconText: "\uf0ea"; focusable: true; foreground: root.fg; onClicked: root.pasteClipboard() }
          Ui.Button {
            text: root.busy ? "Translating…" : "Translate"
            iconText: root.busy ? "\uf110" : "\uf061"
            iconSpinning: root.busy; focusable: true; bordered: true
            foreground: Color.accent
            enabled: !root.busy && input.text.trim() !== "" && input.text.length <= 5000
            onClicked: root.translate()
          }
        }
        Ui.PanelSeparator { Layout.fillWidth: true }
        RowLayout {
          Layout.fillWidth: true
          Text { text: root.stale ? "TRANSLATION · TEXT CHANGED" : "TRANSLATION"; color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
          Item { Layout.fillWidth: true }
          Ui.Button { text: root.copyLabel; iconText: "\uf0c5"; focusable: true; enabled: root.result !== ""; foreground: root.fg; onClicked: root.copyResult() }
        }
        QQC.ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.minimumHeight: Style.space(85)
          clip: true
          QQC.TextArea {
            readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap; textFormat: TextEdit.PlainText
            text: root.errorText || root.result || (root.busy ? "Finding the words…" : "Your translation will appear here.")
            color: root.errorText ? Color.urgent : root.result ? root.fg : root.muted
            font.family: Style.font.family; font.pixelSize: Style.font.title
            selectionColor: Style.selectionFillFor(root.fg, Color.accent); selectedTextColor: root.fg
            background: null
            Keys.onPressed: function(event) { root.handleKey(event) }
          }
        }
        RowLayout {
          Layout.fillWidth: true
          Text { text: root.demo ? "Offline preview" : "Translated by Google"; color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
          Item { Layout.fillWidth: true }
          Text { text: "Ctrl + Enter to translate"; color: root.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
        }
      }
    }
  }
}
