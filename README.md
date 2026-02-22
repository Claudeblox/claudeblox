<p align="center">
  <img src="https://pbs.twimg.com/profile_banners/1925925498498424832/1748013842/1500x500" alt="ClaudeBlox Banner" width="100%"/>
</p>

<h1 align="center">ClaudeBlox</h1>

<p align="center">
  <strong>AI that builds Roblox games autonomously.</strong>
</p>

<p align="center">
  <a href="https://www.claude-blox.com/">Website</a> •
  <a href="https://x.com/claudebl0x">Twitter</a> •
  <a href="https://dexscreener.com/solana/DSyAs4y6siDcC3qYaz4yhhXZSu6ShMgjYvrn7xD1pump">Dexscreener</a> •
  <a href="https://pump.fun/coin/DSyAs4y6siDcC3qYaz4yhhXZSu6ShMgjYvrn7xD1pump">Pump.fun</a>
</p>

<p align="center">
  Write a prompt. Watch it build. Play your game.
</p>

---

## What is this?

ClaudeBlox is an autonomous game development system powered by Claude Code. You describe what game you want, and AI builds it — scripts, world, lighting, everything.

```
You: "Build a horror escape game with 3 floors, locked doors, and a monster that chases the player"

ClaudeBlox: *creates 400+ parts, 12 scripts, UI, lighting, enemy AI, and a playable game*
```

No coding required. No 3D modeling. Just describe and watch.

---

## How it works

```
                                    ┌─────────────────────────────────────┐
                                    │              YOU                    │
                                    │    "Build a horror game with..."    │
                                    └──────────────────┬──────────────────┘
                                                       ▼
                                    ┌─────────────────────────────────────┐
                                    │      CLAUDE CODE (Game Master)      │
                                    │   Understands vision, delegates     │
                                    └──────────────────┬──────────────────┘
                                                       ▼
    ┌──────────────────────────────────────────────────────────────────────────────────────────┐
    │                              16 SPECIALIZED AI AGENTS                                    │
    │                                                                                          │
    │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
    │  │  🏗️ ARCHITECTURE & PLANNING                                                         │ │
    │  │  ├── roblox-architect    → designs complete game structure & blueprint              │ │
    │  │  ├── ai-developer        → creates & maintains agent prompts                        │ │
    │  │  └── story-teller        → writes narrative & environmental storytelling            │ │
    │  └─────────────────────────────────────────────────────────────────────────────────────┘ │
    │                                                                                          │
    │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
    │  │  💻 CODE & SCRIPTS                                                                  │ │
    │  │  ├── luau-scripter       → writes production-quality Luau code                      │ │
    │  │  ├── luau-reviewer       → security review, finds bugs & exploits                   │ │
    │  │  └── luau-notes          → best practices reference                                 │ │
    │  └─────────────────────────────────────────────────────────────────────────────────────┘ │
    │                                                                                          │
    │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
    │  │  🌍 WORLD BUILDING                                                                  │ │
    │  │  ├── world-builder       → constructs 3D environments via MCP                       │ │
    │  │  ├── set-dresser         → adds props, furniture, atmosphere                        │ │
    │  │  └── enemy-designer      → creates NPCs with AI behavior                            │ │
    │  └─────────────────────────────────────────────────────────────────────────────────────┘ │
    │                                                                                          │
    │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
    │  │  🎨 VISUAL & AUDIO                                                                  │ │
    │  │  ├── ui-designer         → polishes interface, mobile-safe                          │ │
    │  │  ├── vfx-designer        → particles, dust, fog, sparks                             │ │
    │  │  ├── sound-designer      → immersive layered audio                                  │ │
    │  │  └── showcase-photographer → promotional screenshots                                │ │
    │  └─────────────────────────────────────────────────────────────────────────────────────┘ │
    │                                                                                          │
    │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
    │  │  🧪 TESTING & PUBLISHING                                                            │ │
    │  │  ├── roblox-playtester   → structural QA via MCP                                    │ │
    │  │  ├── computer-player     → plays game autonomously, finds bugs                      │ │
    │  │  └── roblox-publisher    → publishes to Roblox platform                             │ │
    │  └─────────────────────────────────────────────────────────────────────────────────────┘ │
    │                                                                                          │
    └──────────────────────────────────────────────────────────────────────────────────────────┘
                                                       ▼
                                    ┌─────────────────────────────────────┐
                                    │      ROBLOX STUDIO (via MCP)        │
                                    │  Creates parts, scripts, lighting   │
                                    └──────────────────┬──────────────────┘
                                                       ▼
                                    ┌─────────────────────────────────────┐
                                    │           YOUR GAME                 │
                                    │    Playable. Publishable. Yours.    │
                                    └─────────────────────────────────────┘
```

---

## Requirements

| What | Why |
|------|-----|
| **Claude Code subscription** | AI that builds your game ([claude.ai/code](https://claude.ai/code)) |
| **Anthropic account** | Required for Claude Code |
| **Roblox Studio** | Where your game gets built ([download](https://create.roblox.com/)) |
| **Roblox account** | To publish your game |
| **Windows or Mac** | Roblox Studio runs on Windows 10+ and macOS 10.14+ |

### Models

| Model | Best for |
|-------|----------|
| **Opus** | Game architecture, complex scripts, debugging |
| **Sonnet** | World building, simple fixes, fast iterations |

---

## Quick Start

### 1. Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

### 2. Install Roblox MCP Server

- Download from [Roblox Studio MCP releases](https://github.com/Roblox/studio-rust-mcp-server/releases)
- Place the `.exe` somewhere (e.g., `C:\tools\rbx-studio-mcp.exe`)

### 3. Configure Claude Code

Add to `~/.claude.json`:

```json
{
  "mcpServers": {
    "roblox-studio": {
      "command": "C:\\tools\\rbx-studio-mcp.exe",
      "args": ["--stdio"]
    }
  }
}
```

### 4. Clone & Run

```bash
git clone https://github.com/Claudeblox/claudeblox.git
cd claudeblox
claude
```

### 5. Start Building

```
Build a horror escape game. 3 floors underground.
Player starts in a lab, needs to find keycards to unlock doors.
There's a monster that patrols and chases if it sees the player.
Dark atmosphere, flickering lights, scary sounds.
```

Watch your game come to life.

---

## The 16 Agents

<details>
<summary><strong>🏗️ Architecture & Planning</strong></summary>

| Agent | Description |
|-------|-------------|
| **roblox-architect** | Senior game architect (12+ years). Designs complete game architecture — genre, core loop, services, RemoteEvents, world layout with exact dimensions, part budgets, lighting design, art direction. The blueprint that all other agents execute. |
| **ai-developer** | AI agent architect. Designs, creates, and fixes agent prompts. Builds complete agent "worlds" — full reality contexts that shape how a model thinks and works. |
| **story-teller** | Narrative designer (12+ years). Environmental storytelling — invisible trigger zones, proximity-based typewriter text, cryptic fragments that tell stories through implication. |

</details>

<details>
<summary><strong>💻 Code & Scripts</strong></summary>

| Agent | Description |
|-------|-------------|
| **luau-scripter** | Senior Roblox engineer (8+ years). Production-quality Luau with `--!strict` typing and server-authoritative architecture. Scripts, modules, RemoteEvents, deploys directly to Studio. |
| **luau-reviewer** | Security engineer (8+ years). Reviews code for vulnerabilities, memory leaks, performance issues. Every bug report includes exact file, line, and fix. The quality gate. |
| **general-purpose-luau-notes** | Best practices reference. Patterns that work, patterns that fail, MCP gotchas. |

</details>

<details>
<summary><strong>🌍 World Building</strong></summary>

| Agent | Description |
|-------|-------------|
| **world-builder** | Technical environment builder (12 years). Precision-builds 3D environments via MCP — room geometry, lighting, doors, tagged objects. Floor-scale (500+ parts) to detail-scale. |
| **set-dresser** | Theatrical set dresser (15 years). Decorative props from primitives. Every prop cluster tells a micro-story — half-empty coffee mug, papers mid-spread, chair pushed back. |
| **enemy-designer** | AI programmer & creature designer (10+ years). Creates NPCs from primitives, state machine AI with PathfindingService, raycasting detection. Complete enemy systems. |

</details>

<details>
<summary><strong>🎨 Visual & Audio</strong></summary>

| Agent | Description |
|-------|-------------|
| **ui-designer** | UI/UX designer (10+ years). Transforms programmer-default UI to genre-appropriate, mobile-safe, polished interface. UIGradients, UIStroke, TweenService animations. |
| **vfx-designer** | VFX artist (12+ years). Environmental particles — dust in light shafts, sparks from damaged fixtures, steam from pipes, fog on floors. Mobile-optimized. |
| **sound-designer** | Audio director (10+ years, 5 in horror). Layered audio — base drones, mid environmental detail, spatial sources. Silence is a sound. Audio tells stories. |
| **showcase-photographer** | Virtual camera operator. Captures promotional screenshots from CameraPoints. Beauty shots for social media. |

</details>

<details>
<summary><strong>🧪 Testing & Publishing</strong></summary>

| Agent | Description |
|-------|-------------|
| **roblox-playtester** | QA engineer (12 years, 6 in Roblox). Inspects via MCP — architecture mismatches, spatial failures, script-world disconnects. Every room reachable, every door functional. |
| **computer-player** | Playtest engineer. Plays autonomously via game_state.json and actions.txt — without a screen. Persistent route plans, adapts strategy. Reports bugs with coordinates. |
| **roblox-publisher** | Release engineer (10 years). Complete publish pipeline — saves, uploads via Open Cloud API, configures settings, verifies live. |

</details>

---

## Agent Pipeline

```
                        roblox-architect
                              │
                       (architecture doc)
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
     story-teller       luau-scripter        world-builder
          │                   │                   │
          ▼                   ▼                   ▼
     (narrative)        (game scripts)     (3D environment)
                              │                   │
                              │           ┌───────┴───────┐
                              │           ▼               ▼
                              │      set-dresser    enemy-designer
                              │           │               │
                              │           ▼               ▼
                              │      (props)          (enemies)
                              │                   │
                              └─────────┬─────────┘
                                        ▼
                         ┌──────────────┼──────────────┐
                         ▼              ▼              ▼
                    ui-designer   vfx-designer   sound-designer
                         │              │              │
                         └──────────────┴──────────────┘
                                        ▼
                                 luau-reviewer
                                        │
                                  (code review)
                                        │
                                        ▼
                               roblox-playtester
                                        │
                               (structural tests)
                                        │
                                        ▼
                                computer-player
                                        │
                                (plays the game)
                                        │
                         ┌──────────────┴──────────────┐
                         ▼                             ▼
                   Bugs found?                   All good?
                         │                             │
                         ▼                             ▼
                  Fix & repeat                 roblox-publisher
                                                       │
                                                (publish game)
```

---

## What can it build?

ClaudeBlox builds from **primitives** (Parts, Lighting, Scripts). No custom meshes needed.

**Works great for:**
- Horror games (atmosphere from lighting)
- Escape rooms (puzzles + doors + keys)
- Obbies (platforming challenges)
- Tycoons (build + earn loops)
- Simulators (click + upgrade + rebirth)

**Current limitations:**
- No custom 3D models (uses Roblox primitives)
- No imported textures (uses Roblox materials)
- No audio files (uses Roblox sound library)

---

## Example Session

```
You: Build a simple obby with 10 stages

ClaudeBlox:
  → roblox-architect designing the obby...
  → Architecture complete: 10 stages, checkpoint system, UI
  → luau-scripter creating scripts...
  → Created: CheckpointManager, StageLoader, PlayerData
  → world-builder creating stages...
  → Built: Stage1 (easy jumps), Stage2 (moving platforms)...
  → ui-designer polishing interface...
  → vfx-designer adding particles...
  → luau-reviewer checking code...
  → roblox-playtester verifying structure...
  → computer-player playtesting...
  → Completed all 10 stages, no bugs found

Your obby is ready to play!
```

---

## Roadmap

### Completed ✅

- [x] Computer-player improvements — Plays like a real player, better camera
- [x] Roblox-architect expansion — 5 new sections: Detail Architecture, Lighting, Game Feel, Art Direction, Part Budget
- [x] 16 specialized agents — Full development pipeline

### In Progress 🔨

- [ ] Diagnose scripted patterns — Remove hardcoded examples agents copy
- [ ] De-template agents — Make each output unique

### Planned 📋

- [ ] Lighting Director — Post-processing: ColorCorrection, Bloom, cinematic atmosphere
- [ ] Art Director — Visual consistency checker
- [ ] Interior Designer — Room layout planning before builders work
- [ ] Analyst — Pattern recognition across build cycles

---

## Links

<p align="center">
  <a href="https://www.claude-blox.com/"><strong>Website</strong></a> •
  <a href="https://x.com/claudebl0x"><strong>Twitter / X</strong></a> •
  <a href="https://dexscreener.com/solana/DSyAs4y6siDcC3qYaz4yhhXZSu6ShMgjYvrn7xD1pump"><strong>Dexscreener</strong></a> •
  <a href="https://pump.fun/coin/DSyAs4y6siDcC3qYaz4yhhXZSu6ShMgjYvrn7xD1pump"><strong>Pump.fun</strong></a>
</p>

---

## License

MIT License. Build whatever you want.

---

<p align="center">
  <strong>Built by the claudeblox_dev team</strong>
</p>
