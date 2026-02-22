# ClaudeBlox

**AI that builds Roblox games autonomously.**

Write a prompt. Watch it build. Play your game.

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
┌─────────────────────────────────────────────────────────────────┐
│  YOU                                                            │
│  "Build a horror game with..."                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  CLAUDE CODE (Game Master)                                      │
│  Understands your vision, plans architecture, delegates tasks   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  SPECIALIZED AGENTS                                             │
│  ├── roblox-architect    → designs game structure               │
│  ├── luau-scripter       → writes all game code                 │
│  ├── world-builder       → creates 3D environment               │
│  ├── luau-reviewer       → checks code quality                  │
│  ├── roblox-playtester   → tests everything works               │
│  └── computer-player     → plays the game to find bugs          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ROBLOX STUDIO (via MCP)                                        │
│  Creates parts, writes scripts, configures lighting             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  YOUR GAME                                                      │
│  Playable. Publishable. Yours.                                  │
└─────────────────────────────────────────────────────────────────┘
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

ClaudeBlox works best with **Claude Opus** for complex reasoning and architecture decisions. **Claude Sonnet** can be used for simpler tasks or when you want faster responses.

| Model | Best for |
|-------|----------|
| **Opus** | Game architecture, complex scripts, debugging |
| **Sonnet** | World building, simple fixes, iterations |

---

## Quick Start

### 1. Install Claude Code

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Login
claude login
```

### 2. Install Roblox MCP Server

Download the official Roblox MCP server:
- Go to [Roblox Studio MCP releases](https://github.com/Roblox/studio-rust-mcp-server/releases)
- Download the latest `.exe` for Windows
- Place it somewhere (e.g., `C:\tools\rbx-studio-mcp.exe`)

### 3. Configure Claude Code

Add to your Claude Code config (`~/.claude.json`):

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

### 4. Clone ClaudeBlox

```bash
git clone https://github.com/Claudeblox/claudeblox.git
cd claudeblox
```

### 5. Open Roblox Studio

1. Open Roblox Studio
2. Create new place or open existing
3. Enable HTTP Requests: Game Settings → Security → Allow HTTP Requests

### 6. Start Building

```bash
claude
```

Then tell it what to build:

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
│   └── agents/                    # 16 Specialized AI agents
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
│   │  # Python - System Utilities
│   ├── model_manager.py           # Tracks usage, switches Opus→Sonnet to avoid rate limits
│   ├── obs_control.py             # Switches OBS scenes (CODING vs PLAYING)
│   ├── keep_alive.pyw             # Prevents Windows from sleeping during long sessions
│   │
│   │  # Lua - Roblox Scripts (copy these into your game)
│   ├── AgentControl.lua           # Receives commands, moves player precisely (GO_TO, INTERACT_WITH)
│   ├── GameStateBridge.lua        # Sends player position, nearby objects to AI every second
│   ├── FirstPersonCamera.lua      # Locks camera to horizontal first-person view
│   └── EditorLighting.lua         # Quick lighting presets for horror/bright modes
├── gamemaster/           # Game state and documents
│   ├── state.json                 # Current progress
│   ├── architecture.md            # Game design doc
│   └── buglist.md                 # Known issues
├── CLAUDE.md             # Main instructions for AI
└── README.md             # You are here
```

---

## Agents

ClaudeBlox includes **16 specialized agents** that work together to build your game.

### 🏗️ Architecture & Planning

| Agent | Role |
|-------|------|
| **roblox-architect** | Senior game architect with 12+ years experience. Designs complete game architecture — genre, core loop, services, RemoteEvents, world layout with exact dimensions, part budgets, lighting design, art direction. Creates the blueprint that all other agents execute. Handles new games, floor expansions, and feature additions. |
| **ai-developer** | AI agent architect. Designs, creates, and fixes agent prompts for the ClaudeBlox system. Builds complete agent "worlds" — not instruction sets, but full reality contexts that shape how a model thinks and works. |
| **story-teller** | Senior narrative designer with 12+ years in environmental storytelling. Creates atmospheric narrative overlays — places invisible trigger zones at room entrances, writes proximity-based typewriter text reveals, designs cryptic fragments that tell stories through implication, not exposition. |

### 💻 Code & Scripts

| Agent | Role |
|-------|------|
| **luau-scripter** | Senior Roblox engineer with 8+ years in production games. Writes production-quality Luau code with `--!strict` type checking and server-authoritative architecture. Creates scripts, modules, RemoteEvents, interactive objects, and deploys directly to Roblox Studio. Handles full builds, surgical fixes, and cross-cutting features. |
| **luau-reviewer** | Senior security engineer with 8+ years protecting Roblox games from exploits. Reviews all code for vulnerabilities, memory leaks, performance issues, and logic bugs. Builds complete system maps before reviewing. Every bug report includes exact file, line, and replacement code. The quality gate before any game goes live. |
| **general-purpose-luau-notes** | Best practices reference document for Luau scripting. Contains patterns that work, patterns that fail, MCP-specific gotchas, and guidance for ensuring code quality when the dedicated scripter agent isn't available. |

### 🌍 World Building

| Agent | Role |
|-------|------|
| **world-builder** | Senior technical environment builder with 12 years experience. Precision-builds 3D game environments through MCP — translates architecture specs into exact room geometry, lighting, doors, tagged objects, and navigation elements. Works at both floor-scale (500+ parts) and detail-scale (secret rooms). Every tag and attribute is load-bearing for downstream agents. |
| **set-dresser** | Theatrical set dresser with 15 years experience. Fills finished rooms with decorative props built from primitives. Every prop cluster tells a micro-story — a half-empty coffee mug, papers mid-spread, chair pushed back at angle. Pure visual atmosphere, no gameplay objects or scripts. |
| **enemy-designer** | Senior AI programmer and creature designer with 10+ years building enemies that haunt players. Creates terrifying NPCs from primitives, writes state machine AI with PathfindingService, implements detection via raycasting and magnitude. Builds complete enemy systems: R6 rigs, behavior scripts, sound cues, integration with difficulty scaling. |

### 🎨 Visual & Audio

| Agent | Role |
|-------|------|
| **ui-designer** | Senior UI/UX designer with 10+ years in mobile-first games. Discovers existing functional UI and transforms it from programmer-default to genre-appropriate, mobile-safe, polished interface. Modifies ONLY visual properties — never touches scripts or game logic. Adds UIGradients, UIStroke, TweenService animations, Scale-based sizing. |
| **vfx-designer** | Senior VFX artist with 12+ years in real-time visual effects. Creates environmental particles — dust motes drifting through light shafts, sparks falling from damaged fixtures, steam from cracked pipes, fog rolling along floors. Designs relationships between effects and their environmental context. Restraint at scale for mobile performance. |
| **sound-designer** | Senior audio director with 10+ years in game audio, 5 in survival horror. Creates immersive audio environments in layers — base frequency drones, mid-layer environmental detail, spatial point sources. Understands that silence is a sound. Designs audio that tells stories: a humming generator means power existed, a dripping pipe means infrastructure is failing. |
| **showcase-photographer** | Virtual camera operator. Discovers CameraPoints placed by world-builder, reads their LookAt coordinates, intelligently manages ShowcaseLights, and captures promotional screenshots. Creates beauty shots ready for social media. |

### 🧪 Testing & QA

| Agent | Role |
|-------|------|
| **roblox-playtester** | QA engineer with 12 years in gaming, 6 in Roblox studios shipping games with millions of players. Inspects game structure through MCP — finds architecture mismatches, spatial integrity failures, script-world disconnects, ClassName mismatches, enemy system failures, audio/VFX integrity issues, multi-floor consistency problems. Verifies every room is reachable, every item collectible, every door functional. The final gate before live play-test. |
| **computer-player** | QA playtest engineer who plays Roblox games autonomously through game_state.json and actions.txt — without ever seeing a screen. Maintains persistent route plans, tracks per-floor progress, adapts movement strategy based on what works. Reports bugs with hard evidence: coordinates, room names, expected vs actual behavior. Distinguishes between broken systems and navigation errors. |

### 🚀 Publishing

| Agent | Role |
|-------|------|
| **roblox-publisher** | Release engineer with 10 years shipping games on live platforms. Handles the complete publish pipeline — saves place file from Studio, uploads to Roblox via Open Cloud API, configures game settings (name, description, player limits), and verifies the game is live and accessible. Treats publishing as the most consequential action in the entire pipeline. |

### How Agents Work Together

```
                    roblox-architect
                          │
                    (architecture doc)
                          │
        ┌─────────────────┼─────────────────┐
        ↓                 ↓                 ↓
   story-teller     luau-scripter      world-builder
        │                 │                 │
        ↓                 ↓                 ↓
   (narrative)      (game scripts)    (3D environment)
                          │                 │
                          │         ┌───────┴───────┐
                          │         ↓               ↓
                          │    set-dresser    enemy-designer
                          │         │               │
                          │         ↓               ↓
                          │    (props/details)  (enemies)
                          │                 │
                          └────────┬────────┘
                                   ↓
                    ┌──────────────┼──────────────┐
                    ↓              ↓              ↓
               ui-designer   vfx-designer   sound-designer
                    │              │              │
                    └──────────────┴──────────────┘
                                   ↓
                            luau-reviewer
                                   │
                            (code review)
                                   │
                                   ↓
                          roblox-playtester
                                   │
                          (structural tests)
                                   │
                                   ↓
                           computer-player
                                   │
                           (plays the game)
                                   │
                    ┌──────────────┴──────────────┐
                    ↓                             ↓
              Bugs found?                   All good?
                    │                             │
                    ↓                             ↓
             Fix & repeat                 roblox-publisher
                                                  │
                                            (publish game)
```

---

## Scripts Explained

### Player Control System

The AI plays games by writing commands to `actions.txt`. The system executes them:

```
AI writes: actions.txt          Python reads & executes         Game responds
┌─────────────────────┐        ┌─────────────────────┐        ┌─────────────────────┐
│ THOUGHT "Finding key"│  →    │ action_watcher.py   │   →   │ Player turns right  │
│ TURN_RIGHT 45       │        │ execute_actions.py  │        │ Player walks forward│
│ FORWARD 10          │        │ action.py           │        │ Player picks up key │
│ INTERACT            │        │ (keyboard presses)  │        │                     │
└─────────────────────┘        └─────────────────────┘        └─────────────────────┘
```

**Available Commands:**
| Command | What it does |
|---------|--------------|
| `FORWARD N` | Walk forward N studs |
| `BACK N` | Walk backward N studs |
| `TURN_LEFT N` | Turn left N degrees |
| `TURN_RIGHT N` | Turn right N degrees |
| `TURN_AROUND` | Turn 180 degrees |
| `INTERACT` | Press E (pickup/use) |
| `FLASHLIGHT` | Toggle flashlight |
| `GO_TO object` | Walk precisely to named object |
| `INTERACT_WITH object` | Go to object and interact |
| `SCREENSHOT name` | Take screenshot |
| `THOUGHT "text"` | Display thought on stream |

### Game Communication

Roblox sends game state to AI every second:

```
Roblox (GameStateBridge.lua)     HTTP POST      Python (game_bridge.py)
┌─────────────────────────┐        →           ┌─────────────────────────┐
│ Player position         │                    │ Writes game_state.json  │
│ Nearby objects          │                    │ AI reads this file      │
│ Current room            │                    │ to understand the game  │
│ Health, inventory       │                    │                         │
└─────────────────────────┘                    └─────────────────────────┘
```

**game_state.json example:**
```json
{
  "playerPosition": {"x": 100, "y": 5, "z": 50},
  "currentRoom": "Lab_3",
  "nearbyObjects": [
    {"name": "Keycard", "distance": 15, "direction": {"angle": 45}},
    {"name": "Door", "distance": 30, "direction": {"angle": -90}}
  ],
  "isDark": true,
  "flashlightOn": false
}
```

---

## What can it build?

ClaudeBlox builds games from **primitives** (Parts, Lighting, Scripts). No custom meshes or external assets needed.

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
  → Calling roblox-architect to design the obby...
  → Architecture complete: 10 stages, checkpoint system, UI
  → Calling luau-scripter to create scripts...
  → Created: CheckpointManager, StageLoader, PlayerData
  → Calling world-builder to create stages...
  → Built: Stage1 (easy jumps), Stage2 (moving platforms)...
  → Calling roblox-playtester to verify...
  → All tests passed
  → Calling computer-player to playtest...
  → Completed all 10 stages, no bugs found

Your obby is ready to play!
```

---

## Configuration

### CLAUDE.md

The main instruction file. Customize it to change:
- Default game genre
- Build priorities
- Agent behavior
- Quality standards

### Model Selection

In `run_forever.bat` or Claude Code settings:

```bash
# For best quality (recommended for new games)
claude --model opus

# For faster iteration (good for fixes)
claude --model sonnet
```

---

## Troubleshooting

### "MCP not connected"
1. Make sure Roblox Studio is open
2. Check MCP server path in config
3. Restart Claude Code

### "HTTP Requests failed"
1. In Roblox Studio: Game Settings → Security
2. Enable "Allow HTTP Requests"

### "Scripts not creating"
1. Check Output panel in Roblox Studio for errors
2. Make sure you have edit permissions

---

## Contributing

ClaudeBlox is open source. Contributions welcome!

- **Agents:** Improve or add new specialized agents
- **Scripts:** Better tooling and utilities
- **Docs:** Help others get started

---

## Roadmap

### Completed ✅

- [x] **Computer-player improvements** — Plays like a real player, better camera, tests game feel
- [x] **Roblox-architect expansion** — 5 new sections: Detail Architecture, Lighting Design Brief, Game Feel Spec, Art Direction Guide, Part Budget Allocation
- [x] **More effects and events** — Enhanced gameplay with dynamic effects

### In Progress 🔨

- [ ] **Diagnose scripted patterns** — Find hardcoded Lua examples in luau-scripter, luau-reviewer, world-builder that agents copy instead of thinking
- [ ] **De-template roblox-architect and story-teller** — Remove repetitive output patterns, make each result unique
- [ ] **Review CLAUDE.md vs ai-developer** — Check for duplicate responsibilities, clean up overlap

### Planned 📋

- [ ] **New agent: Lighting Director** — Post-processes scenes after world-builder: ColorCorrection, Bloom, dramatic lighting, cinematic atmosphere
- [ ] **New agent: Art Director** — Visual reviewer that checks palette consistency, scale, empty corners, visual hierarchy
- [ ] **New agent: Interior Designer** — Plans room layouts BEFORE builders work: furniture placement, atmosphere, detail lists
- [ ] **Improve room detail** — Better detailing in world-builder and set-dresser
- [ ] **New agent: Analyst** — Reads all agent reports, finds patterns, suggests improvements, tracks cycle history
- [ ] **Update CLAUDE.md** — Add new agents, update pipeline, add part budget tracking, add art-director review loop

---

## License

MIT License. Build whatever you want.

---

## Links

- [Claude Code](https://claude.ai/code) — AI coding assistant
- [Roblox Studio](https://create.roblox.com/) — Game development platform
- [Roblox MCP Server](https://github.com/Roblox/studio-rust-mcp-server) — Studio connection

---

**Built with Claude. Powered by imagination.**
