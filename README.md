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
    │                              21 SPECIALIZED AI AGENTS                                    │
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
    │  │  ├── interior-designer   → plans room identity, objects & story before building     │ │
    │  │  ├── detail-architect    → adds baseboards, pipes, door frames, vents               │ │
    │  │  ├── set-dresser         → adds props, furniture, atmosphere                        │ │
    │  │  └── enemy-designer      → creates NPCs with AI behavior                            │ │
    │  └─────────────────────────────────────────────────────────────────────────────────────┘ │
    │                                                                                          │
    │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
    │  │  🎨 VISUAL & AUDIO                                                                  │ │
    │  │  ├── lighting-director   → cinematic lighting, post-processing stack                │ │
    │  │  ├── art-director        → composition review — palette, focal hierarchy, readability│ │
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
    │  │  ├── analytics           → pipeline immune system, pattern detection & fixes         │ │
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

- Download `rbx-studio-mcp.exe` from [Roblox Studio MCP releases](https://github.com/Roblox/studio-rust-mcp-server/releases)
- **Run it once** — this auto-installs the Studio plugin (it will appear in the Plugins tab next time you open Studio)
- Place the exe somewhere permanent (e.g., `C:\tools\rbx-studio-mcp.exe`)

### 3. Configure Claude Code

```bash
claude mcp add --transport stdio roblox_studio -- C:\tools\rbx-studio-mcp.exe --stdio
```

Verify: `claude mcp list` should show `roblox_studio` as connected.

> **Fallback (manual):** Add to `~/.claude.json` under `"mcpServers"` — see [SETUP.md](SETUP.md) for details.

### 4. Set Up Roblox Studio

1. Open Roblox Studio and create or open your project
2. **Publish the place:** File > Publish to Roblox As (MCP requires a published place to run)
3. **Enable HTTP Requests:** File > Game Settings > Security > Allow HTTP Requests → On
4. Verify: Studio Plugins tab shows the Roblox MCP plugin; Output window shows `"The MCP Studio plugin is ready for prompts."`

### 5. Clone & Run

```bash
git clone https://github.com/Claudeblox/claudeblox.git
cd claudeblox
claude
```

### 6. Start Building

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
│   └── agents/                    # 21 Specialized AI agents
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
│       ├── interior-designer.md       # Plans room identity, objects & story before building
│       ├── detail-architect.md        # Adds architectural details — pipes, vents, baseboards
│       ├── set-dresser.md             # Adds props, furniture, details
│       ├── enemy-designer.md          # Creates enemy AI and behavior
│       │
│       │  # Visual & Audio
│       ├── lighting-director.md       # Cinematic lighting, post-processing stack (Bloom, ColorCorrection, Atmosphere)
│       ├── art-director.md            # Composition review — palette, focal hierarchy, scale, atmosphere
│       ├── ui-designer.md             # Creates user interface elements
│       ├── vfx-designer.md            # Adds visual effects and particles
│       ├── sound-designer.md          # Designs audio landscape
│       ├── showcase-photographer.md   # Takes promotional screenshots
│       │
│       │  # Testing & Publishing
│       ├── roblox-playtester.md       # Structural QA testing
│       ├── computer-player.md         # Plays the game, finds gameplay bugs
│       ├── analytics.md               # Pipeline immune system, pattern detection & fixes
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

## The 21 Agents

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
| **interior-designer** | Production designer (18 years, film & games). Planning-only — writes complete room blueprints before any props are placed. Discovers room identity (who used it, what happened), plans spatial logic and focal hierarchy, writes an object manifest with story purpose for every prop, and outputs direct build notes to set-dresser and detail-architect. No MCP. Pure planning. |
| **detail-architect** | Architectural detail specialist. Fills the gap between bare geometry and props — baseboards, pipe runs, door frames, vent grates, cable conduits. Works holistically across the entire map because infrastructure flows between rooms. Follows interior-designer blueprints to match infrastructure character to each room's story. |
| **set-dresser** | Theatrical set dresser (15 years). Decorative props from primitives. Executes interior-designer's room blueprint — building each prop in the manifest, in the positions described, in the conditions specified. Every cluster tells a micro-story. |
| **enemy-designer** | AI programmer & creature designer (10+ years). Creates NPCs from primitives, state machine AI with PathfindingService, raycasting detection. Complete enemy systems. |

</details>

<details>
<summary><strong>🎨 Visual & Audio</strong></summary>

| Agent | Description |
|-------|-------------|
| **lighting-director** | Cinematographer turned lighting director (14 years). Transforms flat, functional scenes into cinematic environments. Owns the full post-processing stack (ColorCorrection, Bloom, DepthOfField, Atmosphere, SunRays) and local light modification. Genre-adaptive palette. Runs after vfx-designer, before art-director. |
| **art-director** | Film composition reviewer (16 years). Read-only — analyzes every finished room across 6 dimensions: palette coherence, focal hierarchy, scale accuracy, negative space, spatial readability, atmospheric consistency. Outputs structured correction notes tagged to responsible agents. Works for any genre. |
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
| **analytics** | Pipeline immune system. Reads all agent reports each cycle, separates signal from noise, diagnoses failures as TYPE 1 (prompt) / TYPE 2 (context) / TYPE 3 (architecture). Commissions 3-7 targeted fixes per cycle through ai-developer. |
| **roblox-publisher** | Release engineer (10 years). Complete publish pipeline — saves, uploads via Open Cloud API, configures settings, verifies live. |

</details>

---

## Agent Pipeline

```
                        roblox-architect
                              │
                       (architecture doc)
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
              luau-scripter        world-builder
                    │                   │
                    │                   ▼
                    │        interior-designer ×N
                    │         (parallel, 1/room)
                    │                   │
                    │           (room blueprints)
                    │                   │
                    │           ┌───────┴───────┐
                    │           ▼               ▼
                    │   detail-architect   set-dresser ×N
                    │    (infrastructure)  (1/room, parallel)
                    │           │               │
                    │           └───────┬───────┘
                    │                   ▼
                    │            sound-designer
                    │                   │
                    │             vfx-designer
                    │                   │
                    │           lighting-director
                    │                   │
                    │             art-director
                    │            (composition review)
                    │                   │
                    │            enemy-designer
                    │                   │
                    │             story-teller
                    │              (narrative)
                    │                   │
                    └─────────┬─────────┘
                              ▼
                        luau-reviewer
                           (code review)
                              │
                          ui-designer
                           (UI polish)
                              │
                      roblox-playtester
                       (structural tests)
                              │
                        computer-player
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
- [x] 20 specialized agents — Full development pipeline
- [x] Art Director — Film-composition reviewer: palette coherence, focal hierarchy, scale accuracy, spatial readability, atmospheric consistency across all genres
- [x] Interior Designer — Production designer that plans room identity, spatial logic, object manifests, and story purpose before set-dresser or detail-architect place a single part
- [x] Lighting Director — Cinematographer that transforms functional base lighting into cinematic environments. Owns the full post-processing stack (ColorCorrection, Bloom, DepthOfField, Atmosphere) and local light modification. Genre-adaptive palette
- [x] Agent system audit & de-scripting — Full diagnostic pass across all agents. Removed game-specific hardcoded patterns (luau-scripter -78%, world-builder -74%, story-teller -55%). Agents now reason from principles instead of copying previous game templates. Pipeline diagram updated across all docs.

### Planned 📋

- [x] Analytics agent — Pipeline immune system, pattern detection across cycles, 3-7 targeted fixes per cycle via ai-developer

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
