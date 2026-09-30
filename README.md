# Agent Radial Quick Selector

A radial (pie) menu for every coding agent on your Omarchy machine. One
keybinding, one flick of the mouse, and your agent is running.

**ID:** `xavier.agent-radial`  
**Author:** Xavier Castro  
**License:** MIT  
**Version:** 1.0.0

- **Press `SUPER + SHIFT + CTRL + A`** to open the radial menu.
- **Press it twice quickly** to skip the menu and open your default agent.

## What it does

- **Thirteen agents in one wheel:** Pi, omp, OpenCode, Claude, Codex, Grok,
  Gemini, OpenClaw, Hermes, Copilot, Crush, Cursor and Muse, the same set as
  `omarchy default agent`.
- **Installs what's missing.** Agents that aren't installed are dimmed with a
  download badge. Pick one and it installs, then starts, in the same tab.
- **One herdr tab per agent.** Agents run inside [herdr](https://herdr.dev), so
  they survive closing the window. Picking an agent that already has a tab
  focuses it instead of starting a second copy. A dot marks agents that are
  running.
- **Shift for a fresh tab.** Shift+click (or Shift+Enter) always opens a new
  tab, for running several of the same agent side by side.
- **Double press = default agent.** Reads `omarchy default agent` live and
  opens it in herdr the same way. If no default is set, Omarchy's picker opens.
- **Leaves your default alone.** Picking from the wheel never changes
  `omarchy default agent`.
- **Themed.** Uses your Omarchy menu colors and font.

Agents start with the same unattended flags `omarchy-agent` uses (for example
`claude --permission-mode auto`, `codex --approve-for-me`).

## Requirements

- Omarchy with the shell plugin system (`omarchy plugin`)
- [`herdr`](https://herdr.dev) and `jq` on `PATH`
- `mise`, which Omarchy uses to install agents

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
| Click / Enter / Space | Open the agent (focus its tab, or install and start it) |
| Shift + click / Shift + Enter | Open in a new tab |
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
- **Agent list, order and flags:** edit the `AGENTS` array and `command_for` in
  `bin/agents`, and the `agents` array in `Radial.qml`. Keep the two in the
  same order.
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
