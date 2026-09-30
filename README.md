# Agent Radial Quick Selector

A radial (pie) menu for coding agents and desktop AI apps on your Omarchy
machine. One keybinding, one flick of the mouse, and your chosen tool opens.

**ID:** `xavier.agent-radial`  
**Author:** Xavier Castro  
**License:** MIT  
**Version:** 1.0.0

- **Press `SUPER + SHIFT + CTRL + A`** to open the radial menu.
- **Press it twice quickly** to skip the menu and open your default agent.

## What it does

- **Fifteen choices in one wheel:** Pi, omp, OpenCode, Claude, Codex, Grok,
  Gemini, OpenClaw, Hermes, Copilot, Crush, Cursor, Muse, plus the Grok Bot
  and ChatGPT desktop apps. The 13 terminal agents match
  `omarchy default agent`.
- **Installs what's missing.** Agents that aren't installed are dimmed with a
  download badge. Pick one and it installs, then starts, in the same tab.
- **A fresh tab per pick.** Agents run inside [herdr](https://herdr.dev), so
  they survive closing the window. Picking an agent that's already running
  starts another instance instead of focusing the old one. A dot marks agents
  that are running.
- **Shift to focus.** Shift+click (or Shift+Enter) focuses the agent's existing
  tab when one exists, instead of opening another.
- **Double press = default agent.** Reads `omarchy default agent` live and
  opens it in herdr the same way. If no default is set, Omarchy's picker opens.
- **Leaves your default alone.** Picking from the wheel never changes
  `omarchy default agent`.
- **Desktop apps too.** Grok Bot and ChatGPT launch outside herdr via their
  desktop entries. They must already be installed; this plugin doesn't install
  desktop apps. If one is missing, its wedge is dimmed and picking it shows a
  notification. Grok Build (`grok`) and Codex remain separate terminal-agent
  entries in herdr.
- **Themed.** Uses your Omarchy menu colors and font.

Terminal agents start with the same unattended flags `omarchy-agent` uses (for example
`claude --permission-mode auto`, `codex --approve-for-me`). Grok Bot and ChatGPT
open as ordinary desktop applications and do not run in herdr.

## Requirements

- Omarchy with the shell plugin system (`omarchy plugin`)
- [`herdr`](https://herdr.dev) and `jq` on `PATH`
- `mise`, which Omarchy uses to install terminal agents
- For the desktop entries, installed `grok-bot` and `chatgpt` desktop apps

## Install

```sh
omarchy plugin add https://github.com/xavier-castro/agent-radial-quick-selector.git --enable
~/.config/omarchy/plugins/xavier.agent-radial/bin/install-binding
```

The second command adds the key binding to `~/.config/hypr/bindings.lua`. It
makes a backup first and unbinds Omarchy's stock `SUPER + SHIFT + CTRL + A`
("Agent", which ran `omarchy-agent --pick`). To do it by hand, add:

```lua
hl.unbind("SUPER + SHIFT + CTRL + A")
o.bind("SUPER + SHIFT + CTRL + A", "Agent radial menu",
  os.getenv("HOME") .. "/.config/omarchy/plugins/xavier.agent-radial/bin/agent-radial")
```

Then run `hyprctl reload` followed by `hyprctl configerrors`.

## Controls

| Control | Action |
|---|---|
| `SUPER + SHIFT + CTRL + A` | Open or close the wheel |
| Press twice within 400 ms | Open the default agent |
| Hover | Select an agent |
| Click / Enter / Space | Open a terminal agent in herdr (install if missing), or launch a desktop app |
| Shift + click / Shift + Enter | Focus the agent's existing tab |
| Arrows, Tab, `h` `j` `k` `l` | Rotate the selection |
| A letter | Jump to the next agent starting with it |
| Right-click / Esc | Close |

## How it works

- `Radial.qml` is an overlay plugin. It draws the wheel on a fullscreen layer
  surface and runs `bin/agents state` when it opens to learn which agents are
  installed and running.
- `bin/agents` holds the per-agent launch commands and install logic, mirroring
  `omarchy-default-agent` and `omarchy-agent`, and drives herdr
  (`herdr tab create`, `tab focus`, `pane run`). Each tab `exec`s the agent, so
  the tab closes when the agent exits.
- `bin/agent-radial` is the key binding entry point. Hyprland has no
  double-tap, so it timestamps each press in `$XDG_RUNTIME_DIR` and treats a
  second press within `AGENT_RADIAL_DOUBLE_MS` (default `400`) as a double
  press. A double press briefly flashes the wheel before the default agent
  opens.

## Configuration

- **Double-press window:** set `AGENT_RADIAL_DOUBLE_MS` in the environment
  Hyprland launches with.
- **Terminal-agent list, order and flags:** edit the `AGENTS` array and
  `command_for` in `bin/agents`, and the `agents` array in `Radial.qml`. Keep
  both lists in the same order. Desktop app launch behavior is in
  `launch_desktop()` in `bin/agents`.
- **Herdr window:** the plugin opens its own herdr window with app-id
  `org.omarchy.herdr`. It attaches to the same herdr session as
  `SUPER + CTRL + RETURN`.

## Remove

```sh
omarchy plugin remove xavier.agent-radial
```

Then delete the "agent-radial quick selector" block from
`~/.config/hypr/bindings.lua`, or restore the backup made by
`install-binding`, to bring back the stock binding.

Unofficial. Not affiliated with Omarchy or herdr.
