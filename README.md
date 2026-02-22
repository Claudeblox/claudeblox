<h1 align="center">ClaudeBlox</h1>

<p align="center">
  <strong>AI that builds Roblox games autonomously.</strong>
</p>

<p align="center">
  <a href="https://www.claude-blox.com/">
    <img src="https://img.shields.io/badge/Website-claude--blox.com-blue?style=for-the-badge&logo=google-chrome&logoColor=white" alt="Website"/>
  </a>
  <a href="https://x.com/claudebl0x">
    <img src="https://img.shields.io/badge/Twitter-@claudebl0x-1DA1F2?style=for-the-badge&logo=x&logoColor=white" alt="Twitter"/>
  </a>
</p>

<p align="center">
  <a href="https://dexscreener.com/solana/DSyAs4y6siDcC3qYaz4yhhXZSu6ShMgjYvrn7xD1pump">
    <img src="https://img.shields.io/badge/Dexscreener-Chart-green?style=for-the-badge&logo=bitcoin&logoColor=white" alt="Dexscreener"/>
  </a>
  <a href="https://pump.fun/coin/DSyAs4y6siDcC3qYaz4yhhXZSu6ShMgjYvrn7xD1pump">
    <img src="https://img.shields.io/badge/Pump.fun-Token-orange?style=for-the-badge&logo=solana&logoColor=white" alt="Pump.fun"/>
  </a>
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
    │                              17 SPECIALIZED AI AGENTS                                    │
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
    │  │  ├── detail-architect    → adds baseboards, pipes, door frames, vents               │ │
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

## Project Structure

```
claudeblox/
├── .claude/
│   └── agents/                    # 17 Specialized AI agents
│       │
│       │  # Architecture & Planning
│       ├── roblox-architect.md        # Designs game architecture, services, world layout
│       ├── ai-developer.md            # High-level development orchestration
│       ├── story-teller.md            # Creates narrative, lore, environmental storytelling
│       │
│       │  # Code & Scripts
│       ├── luau-scripter.md           # Writes production-ready Luau code
│       ├── luau-reviewer.md           # Code review, finds bugs before runtime
│       ├── general-purpose-luau-notes.md  # Luau best practices reference
│       │
│       │  # World Building
│       ├── world-builder.md           # Builds 3D environments from primitives
│       ├── detail-architect.md        # Adds architectural details — pipes, vents, baseboards
│       ├── set-dresser.md             # Adds props, furniture, details
│       ├── enemy-designer.md          # Creates enemy AI and behavior
│       │
│       │  # Visual & Audio
│       ├── ui-designer.md             # Creates user interface elements
│       ├── vfx-designer.md            # Adds visual effects and particles
│       ├── sound-designer.md          # Designs audio landscape
│       ├── showcase-photographer.md   # Takes promotional screenshots
│       │
│       │  # Testing & Publishing
│       ├── roblox-playtester.md       # Structural QA testing
│       ├── computer-player.md         # Plays the game, finds gameplay bugs
│       └── roblox-publisher.md        # Publishes game to Roblox
│
├── scripts/              # Utilities and game integration
│   │
│   │  # Python - Player Control System
│   ├── execute_actions.py         # Parses commands (FORWARD, TURN, INTERACT) and executes them
│   ├── action.py                  # Low-level keyboard simulation via pyautogui
│   ├── action_watcher.py          # Monitors actions.txt, auto-executes when file changes
│   │
│   │  # Python - Game Communication
│   ├── game_bridge.py             # HTTP server (port 8585) receives game state from Roblox
│   ├── screenshot_game.py         # Captures Roblox viewport for AI analysis
│   │
│   │
│   │  # Lua - Roblox Scripts (copy these into your game)
│   ├── AgentControl.lua           # Receives commands, moves player precisely (GO_TO, INTERACT_WITH)
│   ├── GameStateBridge.lua        # Sends player position, nearby objects to AI every second
│   ├── FirstPersonCamera.lua      # Locks camera to horizontal first-person view
│   └── EditorLighting.lua         # Quick lighting presets for horror/bright modes
│
├── gamemaster/           # Game state and documents
│   ├── state.json                 # Current progress
│   ├── architecture.md            # Game design doc
│   └── buglist.md                 # Known issues
│
├── CLAUDE.md             # Main instructions for AI
└── README.md             # You are here
```

---

## The 17 Agents

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
| **detail-architect** | Architectural detail specialist. Fills the gap between bare geometry and props — baseboards, pipe runs, door frames, vent grates, cable conduits. Works holistically across the entire map because infrastructure flows between rooms. |
| **set-dresser** | Theatrical set dresser (15 years). Decorative props from primitives. Every prop cluster tells a micro-story — half-empty coffee mug, papers mid-spread, chair pushed back. |
| **enemy-designer** | AI programmer & creature designer (10+ years). Creates NPCs from primitives, state machine AI with PathfindingService, raycasting detection. Complete enemy systems. |

</details>

<details>
<summary><strong>🎨 Visual & Audio</strong></summary>

| Agent | Description |
|-------|-------------|
| **ui-designer** | UI/UX designer (10+ years). Transforms programmer-default UI to genre-appropriate, mobile-safe, polished interface. UIGradients, UIStroke, TweenService animations. |
| **vfx-designer** | VFX artist (12+ years). Environmental particles — dust in light shafts, sparks from damaged fixtures, steam from pipes, fog on floors. Mobile-optimized. |
| **sound-designer** | Audio director (10+ years). Layered audio — base drones, mid environmental detail, spatial sources. Adapts to any genre: tension for horror, energy for tycoon, wonder for adventure. |
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
                              │                   ▼
                              │           detail-architect
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
- [x] 17 specialized agents — Full development pipeline

### In Progress 🔨

- [ ] Diagnose scripted patterns — Remove hardcoded examples agents copy
- [ ] De-template agents — Make each output unique

### Planned 📋

- [ ] Lighting Director — Post-processing: ColorCorrection, Bloom, cinematic atmosphere
- [ ] Art Director — Visual consistency checker
- [ ] Interior Designer — Room layout planning before builders work
- [ ] Analyst — Pattern recognition across build cycles

---

## License

MIT License. Build whatever you want.

---

<p align="center">
  <img src="https://pbs.twimg.com/profile_banners/2012465914944376832/1771666655/1500x500" alt="ClaudeBlox Banner" width="100%"/>
</p>

<p align="center">
  <a href="https://www.claude-blox.com/">
    <img src="https://img.shields.io/badge/🌐_Website-claude--blox.com-blue?style=for-the-badge" alt="Website"/>
  </a>
  <a href="https://x.com/claudebl0x">
    <img src="https://img.shields.io/badge/𝕏_Twitter-@claudebl0x-000000?style=for-the-badge" alt="Twitter"/>
  </a>
  <a href="https://dexscreener.com/solana/DSyAs4y6siDcC3qYaz4yhhXZSu6ShMgjYvrn7xD1pump">
    <img src="https://img.shields.io/badge/📊_Dexscreener-Chart-00C853?style=for-the-badge" alt="Dexscreener"/>
  </a>
  <a href="https://pump.fun/coin/DSyAs4y6siDcC3qYaz4yhhXZSu6ShMgjYvrn7xD1pump">
    <img src="https://img.shields.io/badge/🚀_Pump.fun-Token-FF6D00?style=for-the-badge" alt="Pump.fun"/>
  </a>
</p>

<p align="center">
  <strong>Built by the claudeblox_dev team</strong>
</p>
