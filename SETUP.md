# ClaudeBlox Setup Guide

Complete setup instructions for first-time users. If the README Quick Start is enough for you, use that. This guide covers every step in detail, including what you should see at each stage and how to fix it if something goes wrong.

---

## Prerequisites

- **Windows** (the Roblox MCP server ships as a Windows executable)
- **Roblox Studio** installed ([download here](https://www.roblox.com/create))
- **Node.js** v18 or later ([download here](https://nodejs.org/)) — required for Claude Code
- A Roblox account

---

## Step 1: Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

`claude login` opens a browser to authenticate with your Anthropic account. After logging in, return to the terminal.

**Verify:** Run `claude --version` — should print a version number.

---

## Step 2: Install the Roblox Studio MCP Server

The Roblox Studio MCP server is a small executable that bridges Claude Code and Roblox Studio.

1. Go to [github.com/Roblox/studio-rust-mcp-server/releases](https://github.com/Roblox/studio-rust-mcp-server/releases)
2. Download the latest `rbx-studio-mcp.exe`
3. **Run it once** — double-click or run from a terminal:
   ```
   rbx-studio-mcp.exe
   ```
   Running it once auto-installs the companion plugin into Roblox Studio. You should see a brief flash or terminal output confirming plugin installation.
4. Move the exe to a permanent location, e.g., `C:\tools\rbx-studio-mcp.exe`

> **Why run it first?** The exe contains the Roblox Studio plugin embedded inside it. Running it once extracts and installs the plugin. After that, the plugin persists in Studio — you only need the exe for Claude Code to launch as a subprocess.

**Verify:** Open Roblox Studio. The **Plugins** tab should contain a new "Roblox MCP" entry.

---

## Step 3: Configure Claude Code MCP

Claude Code needs to know where to find the MCP server executable. There are three ways to do this.

### Option A: CLI (recommended)

```bash
claude mcp add --transport stdio roblox_studio -- C:\tools\rbx-studio-mcp.exe --stdio
```

Replace `C:\tools\rbx-studio-mcp.exe` with wherever you placed the exe.

**Verify:** Run `claude mcp list` — should show `roblox_studio` with status `connected`.

### Option B: Ask Claude Code

Start Claude Code (`claude` in any directory), then type:

```
Add the Roblox Studio MCP server at C:\tools\rbx-studio-mcp.exe
```

Claude Code will configure it automatically.

### Option C: Manual JSON (fallback)

Edit `~/.claude.json` (create it if it doesn't exist) and add:

```json
{
  "mcpServers": {
    "roblox_studio": {
      "command": "C:\\tools\\rbx-studio-mcp.exe",
      "args": ["--stdio"]
    }
  }
}
```

Note: use double backslashes in JSON (`\\`) and forward slashes on the `command` key won't work on Windows — use the full Windows path with `\\`.

---

## Step 4: Set Up Roblox Studio

Two settings in Roblox Studio must be configured before MCP works.

### 4a. Publish your place

MCP requires your place to be published to Roblox. An unsaved or unpublished local file won't work.

1. Open Roblox Studio
2. Create a new place or open an existing one
3. **File > Publish to Roblox As...**
4. Fill in a name and click **Create** (or **Update** if it already exists)

You only need to do this once per project. After publishing, normal Ctrl+S saves work fine.

### 4b. Enable HTTP Requests

The MCP plugin communicates with the MCP server over HTTP. This must be explicitly allowed.

1. In Roblox Studio: **File > Game Settings**
2. Go to the **Security** tab
3. Find **Allow HTTP Requests** and toggle it **On**
4. Click **Save**

> If you don't see Game Settings, your place may not be published yet — complete 4a first.

**Verify:** Restart Roblox Studio with your place open. The **Output** window (View > Output) should show:

```
The MCP Studio plugin is ready for prompts.
```

If it shows this, Studio and the MCP server can communicate.

---

## Step 5: Clone ClaudeBlox

```bash
git clone https://github.com/Claudeblox/claudeblox.git
cd claudeblox
```

The repo contains:
- `.claude/agents/` — all 20 specialist subagent prompts
- `CLAUDE.md` — the Game Master controller prompt (the autonomous build loop)
- `scripts/` — helper scripts for play-testing, OBS control, etc.
- `project/` — gets created on first run (state, logs, changelogs)

---

## Step 6: Launch

Make sure Roblox Studio is open with your place before starting Claude Code.

```bash
cd claudeblox
claude
```

Claude Code starts, reads `CLAUDE.md`, and begins the autonomous build loop. Give it an initial prompt to set the game concept:

```
Build a horror escape game. 3 floors underground.
Player starts in a lab, needs to find keycards to unlock doors.
There's a monster that patrols and chases if it sees the player.
Dark atmosphere, flickering lights, scary sounds.
```

Or just run `claude` with no prompt — the Game Master will choose a genre and start building.

---

## Verify Everything Works

Run through this checklist before the first build cycle:

- [ ] `claude --version` prints a version
- [ ] `claude mcp list` shows `roblox_studio` as connected
- [ ] Roblox Studio is open with a published place
- [ ] Studio Output shows `"The MCP Studio plugin is ready for prompts."`
- [ ] HTTP Requests is enabled in Game Settings > Security

If all five pass, you're ready. Start `claude` and watch it go.

---

## Troubleshooting

### `claude mcp list` shows roblox_studio as disconnected

The MCP server process isn't running. This usually means:
- The exe path in your config is wrong — check with `claude mcp list` for the configured path
- You haven't run the exe once to install the Studio plugin (Step 2)
- Claude Code wasn't restarted after adding the MCP server — exit and rerun `claude`

### Studio doesn't show the MCP plugin in the Plugins tab

You haven't run the exe once. Double-click `rbx-studio-mcp.exe` or run it from a terminal, then reopen Studio.

### Studio Output doesn't show "ready for prompts"

- HTTP Requests may not be enabled — check File > Game Settings > Security
- Your place may not be published — File > Publish to Roblox As
- Try closing and reopening Studio with the place

### `claude mcp add` command not found

Your Claude Code version is older than the `mcp add` command. Either upgrade (`npm install -g @anthropic-ai/claude-code`) or use Option C (manual JSON) from Step 3.

### MCP commands return errors during build

The Studio plugin connects per-session. If you restart Studio mid-cycle, the plugin reconnects automatically. If commands still fail, restart `claude` — it will re-establish the MCP connection.

### Place keeps losing HTTP Requests setting

This is a per-place setting. Each new place starts with HTTP Requests off. Set it every time you create a new place.
