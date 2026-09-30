import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons

// Radial (pie) menu of coding agents. Missing agents are dimmed with a
// download badge; picking one installs it in a floating terminal, then runs it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property int selectedIndex: 0
  property string defaultAgent: ""
  property var installedMap: ({})
  property var runningMap: ({})

  readonly property string pluginDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/xavier.agent-radial"
  readonly property string agentsBin: pluginDir + "/bin/agents"

  function cp(n) { return String.fromCodePoint(n) }

  // id, label, glyph, glyph font ("" = menu font, i.e. Nerd Font)
  readonly property var agents: [
    { id: "pi",           label: "Pi",       glyph: cp(0xe901),  font: "omarchy" },
    { id: "omp",          label: "omp",      glyph: cp(0xe903),  font: "omarchy" },
    { id: "opencode",     label: "OpenCode", glyph: cp(0xe902),  font: "omarchy" },
    { id: "claude",       label: "Claude",   glyph: cp(0xf06c4), font: "" },
    { id: "codex",        label: "Codex",    glyph: cp(0xe905),  font: "omarchy" },
    { id: "grok",         label: "Grok",     glyph: cp(0xe904),  font: "omarchy" },
    { id: "gemini",       label: "Gemini",   glyph: cp(0xf0ae2), font: "" },
    { id: "openclaw",     label: "OpenClaw", glyph: cp(0xe90c),  font: "omarchy" },
    { id: "hermes",       label: "Hermes",   glyph: cp(0xe90a),  font: "omarchy" },
    { id: "copilot",      label: "Copilot",  glyph: cp(0xf4b8),  font: "" },
    { id: "crush",        label: "Crush",    glyph: cp(0xf02d1), font: "" },
    { id: "cursor-agent", label: "Cursor",   glyph: cp(0xe90d),  font: "omarchy" },
    { id: "muse",         label: "Muse",     glyph: cp(0xf06e4), font: "" },
    { id: "grok-bot",     label: "Grok Bot", glyph: cp(0x2726),  font: "" },
    { id: "chatgpt",      label: "ChatGPT",  glyph: cp(0xf544),  font: "" }
  ]
  readonly property int count: agents.length
  readonly property real step: 2 * Math.PI / count

  function isInstalled(id) { return installedMap[id] !== false }
  function isRunning(id) { return runningMap[id] === true }
  function isDesktop(id) { return id === "grok-bot" || id === "chatgpt" }

  function indexOfAgent(id) {
    for (var i = 0; i < agents.length; i++) if (agents[i].id === id) return i
    return 0
  }

  function open(payloadJson) {
    root.opened = true
    stateProc.running = false
    stateProc.running = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() { root.opened = false }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "xavier.agent-radial")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  // focus = focus the agent's existing herdr tab instead of opening a fresh one
  function launch(index, focus) {
    if (index < 0 || index >= count) return
    var id = agents[index].id
    root.dismiss()
    var cmd = [root.agentsBin, "run", id]
    if (focus) cmd.push("--focus")
    Quickshell.execDetached(cmd)
  }

  function move(delta) {
    root.selectedIndex = (root.selectedIndex + delta + count) % count
  }

  Process {
    id: stateProc
    command: [root.agentsBin, "state"]
    stdout: StdioCollector {
      onStreamFinished: {
        var map = ({})
        var run = ({})
        var def = ""
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
          var l = lines[i].trim()
          if (!l) continue
          if (l.indexOf("default=") === 0) { def = l.substring(8); continue }
          var p = l.split(" ")
          map[p[0]] = p[1] === "1"
          run[p[0]] = p[2] === "1"
        }
        root.installedMap = map
        root.runningMap = run
        root.defaultAgent = def
        root.selectedIndex = root.indexOfAgent(def)
        canvas.requestPaint()
      }
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "xavier-agent-radial"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    readonly property real outerR: Math.min(width, height) * 0.36 > Style.space(260) ? Style.space(260) : Math.min(width, height) * 0.36
    readonly property real innerR: outerR * 0.40

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
    }

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true
      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) root.dismiss()
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || event.key === Qt.Key_H || event.key === Qt.Key_K) root.move(-1)
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.key === Qt.Key_L || event.key === Qt.Key_J) root.move(1)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.launch(root.selectedIndex, (event.modifiers & Qt.ShiftModifier) !== 0)
        else {
          // type the first letters to jump (e.g. "c" cycles claude/codex/copilot/crush/cursor)
          var t = (event.text || "").toLowerCase()
          if (t.length === 1 && t >= "a" && t <= "z") {
            for (var k = 1; k <= root.count; k++) {
              var i = (root.selectedIndex + k) % root.count
              if (root.agents[i].label.toLowerCase().indexOf(t) === 0) { root.selectedIndex = i; break }
            }
          } else return
        }
        event.accepted = true
      }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton

      function sectorAt(x, y) {
        var dx = x - width / 2
        var dy = y - height / 2
        var dist = Math.sqrt(dx * dx + dy * dy)
        if (dist < panel.innerR || dist > panel.outerR * 1.05) return -1
        var a = Math.atan2(dy, dx) + Math.PI / 2   // 0 = top, clockwise
        if (a < 0) a += 2 * Math.PI
        return Math.round(a / root.step) % root.count
      }

      onPositionChanged: function(m) {
        var s = sectorAt(m.x, m.y)
        if (s >= 0) root.selectedIndex = s
      }
      onClicked: function(m) {
        if (m.button === Qt.RightButton) { root.dismiss(); return }
        var s = sectorAt(m.x, m.y)
        var dx = m.x - width / 2, dy = m.y - height / 2
        var dist = Math.sqrt(dx * dx + dy * dy)
        var focus = (m.modifiers & Qt.ShiftModifier) !== 0
        if (s >= 0) root.launch(s, focus)
        else if (dist < panel.innerR) root.launch(root.selectedIndex, focus)
        else root.dismiss()
      }
    }

    Canvas {
      id: canvas
      anchors.fill: parent
      antialiasing: true

      Connections {
        target: root
        function onSelectedIndexChanged() { canvas.requestPaint() }
        function onInstalledMapChanged() { canvas.requestPaint() }
        function onOpenedChanged() { canvas.requestPaint() }
      }
      Connections {
        target: Color
        function onForegroundChanged() { canvas.requestPaint() }
        function onBackgroundChanged() { canvas.requestPaint() }
      }
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()

      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var cx = width / 2, cy = height / 2
        var R = panel.outerR, r = panel.innerR
        var gap = 0.018
        var lw = Math.max(1, Style.space(2))

        for (var i = 0; i < root.count; i++) {
          var mid = -Math.PI / 2 + i * root.step
          var a0 = mid - root.step / 2 + gap
          var a1 = mid + root.step / 2 - gap
          var sel = i === root.selectedIndex
          var out = R + (sel ? Style.space(10) : 0)

          ctx.beginPath()
          ctx.arc(cx, cy, out, a0, a1, false)
          ctx.arc(cx, cy, r, a1, a0, true)
          ctx.closePath()
          ctx.fillStyle = sel ? Qt.tint(Color.menu.background, Color.menu.selectedBackground)
                              : Color.menu.background
          ctx.fill()
          if (sel) {
            ctx.fillStyle = Color.menu.selectedBackground
            ctx.fill()
          }
          ctx.lineWidth = lw
          ctx.strokeStyle = sel ? Color.menu.selectedText : Color.menu.border
          ctx.stroke()
        }

        // hub
        ctx.beginPath()
        ctx.arc(cx, cy, r - Style.space(6), 0, 2 * Math.PI, false)
        ctx.fillStyle = Color.menu.background
        ctx.fill()
        ctx.lineWidth = lw
        ctx.strokeStyle = Color.menu.border
        ctx.stroke()
      }
    }

    // Glyph + label per wedge
    Repeater {
      model: root.agents
      delegate: Item {
        required property var modelData
        required property int index
        readonly property bool sel: index === root.selectedIndex
        readonly property bool present: root.isInstalled(modelData.id)
        readonly property real mid: -Math.PI / 2 + index * root.step
        readonly property real rad: (panel.innerR + panel.outerR) / 2 + (sel ? Style.space(5) : 0)
        x: panel.width / 2 + Math.cos(mid) * rad - width / 2
        y: panel.height / 2 + Math.sin(mid) * rad - height / 2
        width: Style.space(84)
        height: Style.space(60)
        opacity: present ? 1 : 0.45
        scale: sel ? 1.12 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }

        Text {
          id: glyph
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          text: modelData.glyph
          color: sel ? Color.menu.selectedText : Color.menu.text
          font.family: modelData.font !== "" ? modelData.font : Style.font.menuFamily
          font.pixelSize: Style.font.display
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: glyph.bottom
          anchors.topMargin: Style.space(2)
          text: modelData.label
          color: sel ? Color.menu.selectedText : Color.menu.text
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: modelData.id === root.defaultAgent
        }
        // running badge (has a herdr tab)
        Rectangle {
          visible: root.isRunning(modelData.id)
          anchors.right: glyph.left
          anchors.top: glyph.top
          anchors.topMargin: Style.space(3)
          anchors.rightMargin: Style.space(2)
          width: Style.space(7); height: width; radius: width / 2
          color: Color.menu.selectedText
        }
        // install badge
        Text {
          visible: !present
          anchors.left: glyph.right
          anchors.top: glyph.top
          text: "\uf019"
          color: Color.menu.text
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.caption
        }
      }
    }

    // Hub text
    Column {
      anchors.centerIn: parent
      spacing: Style.space(2)
      readonly property var cur: root.agents[root.selectedIndex]
      readonly property bool present: root.isInstalled(cur.id)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: parent.cur.label
        color: Color.menu.selectedText
        font.family: Style.font.menuFamily
        font.pixelSize: Style.font.heading
        font.bold: true
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: !parent.present ? "not installed — will install"
              : root.isRunning(parent.cur.id) ? "running — new tab  (shift: focus)"
              : root.isDesktop(parent.cur.id) ? "desktop app"
              : (parent.cur.id === root.defaultAgent ? "default agent" : "open in herdr")
        color: Color.menu.text
        opacity: 0.7
        font.family: Style.font.menuFamily
        font.pixelSize: Style.font.caption
      }
    }
  }
}
