# General-Purpose Agent as Luau Scripter -- Best Practices

When the general-purpose agent (no dedicated prompt file) is used for Luau scripting tasks in Roblox Studio via MCP, it lacks the rich "world" that the dedicated `luau-scripter` agent inhabits. This document captures patterns that work, patterns that fail, and concrete guidance for crafting task prompts that compensate for the missing agent prompt.

---

## WHY THE GENERAL-PURPOSE AGENT UNDERPERFORMS

The dedicated `luau-scripter` has ~2000 lines of prompt that build an entire reality: a senior engineer with 8+ years in production games, who treats every line of code as a conscious decision, who knows MCP can silently truncate, who verifies every write, who uses --!strict in every file, who never submits a first draft as final. The general-purpose agent has none of this context. It operates from its base training, which means:

1. **No quality floor.** Without the "your code will be reviewed by a paranoid security engineer" context, the model defaults to tutorial-quality code -- shorter, less defensive, more likely to use deprecated APIs.

2. **No verification instinct.** The dedicated scripter prompt drills "created script -> read it back -> make sure it wrote correctly" into the agent's core cycle. The general-purpose agent creates and moves on -- it does not reflexively verify through MCP.

3. **No MCP awareness.** The general-purpose agent does not know that MCP can silently truncate long scripts, that `run_code` output has limits, or that `[=[...]=]` string delimiters are needed for script Source containing brackets. It may use `[[...]]` and break on nested brackets in the Lua source.

4. **No Roblox-specific patterns.** It does not know `task.wait()` replaced `wait()`, that `Instance.new(class, parent)` is deprecated, that server-authoritative architecture is mandatory, or that --!strict should be in every file.

---

## KNOWN FAILURE PATTERNS

### 1. Skeleton code (too short)

**Symptom:** Agent creates a 20-line script that has the right structure but minimal implementation -- placeholders, TODOs, single print statements where game logic should be.

**Root cause:** Without the "completeness" priority and the "No TODO, FIXME, implement later" constraint from the dedicated prompt, the general-purpose agent treats the task as "demonstrate the pattern" rather than "build the production system."

**Mitigation in task prompt:** Be explicit about expected substance. Example:
```
Write COMPLETE, PRODUCTION-READY code. No placeholders, no TODOs, no skeleton code.
The TutorialController must be a fully functional system with:
- All tutorial steps implemented (not just step 1)
- All UI elements created with real content
- All event connections wired
- Error handling for edge cases
Expected: 80-150 lines of real logic, not 20 lines of structure.
```

### 2. No MCP verification after creation

**Symptom:** Agent creates a script via `run_code`, gets "Done" back, and moves to the next task without reading the script back to confirm it was written correctly.

**Root cause:** The general-purpose agent does not have the "MCP can silently fail" awareness. It trusts the return value.

**Mitigation in task prompt:**
```
VERIFICATION IS MANDATORY. After EVERY script creation through run_code:
1. Read the script back: run_code to get script.Source
2. Check the LAST 10 lines -- truncation cuts from the end
3. Verify line count matches expectation
4. If truncated or missing code, rewrite using chunked approach

Do NOT trust "Done" from run_code. Verify what actually exists in Studio.
```

### 3. Deprecated Roblox APIs

**Symptom:** Code uses `wait()` instead of `task.wait()`, `spawn()` instead of `task.spawn()`, `delay()` instead of `task.delay()`, or `Instance.new("Part", parent)` (two-argument form).

**Root cause:** The model's training data includes vast amounts of older Roblox tutorials that use deprecated APIs. Without the dedicated prompt's explicit prohibition, these patterns surface naturally.

**Mitigation in task prompt:**
```
MODERN LUAU ONLY:
- task.wait() NOT wait()
- task.spawn() NOT spawn()
- task.delay() NOT delay()
- Instance.new("ClassName") then set .Parent separately -- NEVER Instance.new(class, parent)
- Use --!strict at the top of EVERY script
```

### 4. Lua string patterns with special characters (gsub/find)

**Symptom:** When the agent needs to modify script source via MCP (string replacement), it uses `string.gsub` with patterns containing special Lua pattern characters like `(`, `)`, `.`, `%`, `+`, `-`, `*`, `?`, `[`, `]`, `^`, `$`. These are interpreted as pattern metacharacters and cause either wrong replacements or silent failures.

**Root cause:** Lua's `string.gsub` and `string.find` use Lua patterns by default, not plain strings. Characters like `(` and `)` have special meaning. The general-purpose agent does not distinguish between "pattern matching" and "literal string replacement."

**Mitigation in task prompt:**
```
LUA STRING REPLACEMENT -- CRITICAL:
When modifying script Source through string operations:
- NEVER use gsub with raw code strings as patterns -- special chars will break it
- For literal string replacement, use string.find with plain=true + string.sub:
  local startIdx, endIdx = source:find("old text", 1, true)  -- plain=true!
  if startIdx then
    source = source:sub(1, startIdx - 1) .. "new text" .. source:sub(endIdx + 1)
  end
- OR rewrite the entire script.Source in one go (preferred for large changes)
- NEVER rely on gsub for code modification -- parentheses, brackets, dots in code
  are Lua pattern metacharacters and WILL cause silent corruption
```

### 5. Wrong string delimiters for script Source

**Symptom:** Agent writes `script.Source = [[...]]` and the Lua code inside contains `]]` (end of a table, a comment, or nested brackets), which prematurely terminates the string.

**Root cause:** General-purpose agent defaults to `[[...]]` for multiline strings. Does not know about `[=[...]=]`, `[==[...]==]` leveled delimiters.

**Mitigation in task prompt:**
```
When setting script.Source, ALWAYS use leveled string delimiters:
  script.Source = [=[
    -- your code here
  ]=]
This prevents premature termination if code contains ]] or [[ sequences.
For code that itself uses [=[...]=], use [==[...]==] (two equals signs).
```

### 6. Integration-point blindness (skipping existing-code reads)

**Symptom:** Agent is told to build a feature that must integrate with existing scripts -- for example, an achievements system that fires when player collects keys, opens doors, or completes a floor. The prompt explicitly says "read Main script source to understand attribute patterns." The agent either skips the read entirely, reads it but does not extract the specific patterns it needs, or extracts patterns but invents its own incompatible ones when writing the new code.

Concrete example: Main script tracks key collection via `player:SetAttribute("Keys_Floor1", count)` and fires `KeyCollected` RemoteEvent. The achievements system needs to listen for these exact attribute changes or RemoteEvent fires. Without reading Main, the agent invents a different integration mechanism (polling a nonexistent `player.leaderstats.Keys` value, or listening for a `CollectionService` tag change that never happens). The code compiles, looks correct in isolation, but does nothing at runtime because it hooks into the wrong signals.

**Root cause:** This is a hybrid of TYPE 1 (missing work cycle -- no "read before you write" discipline baked into the agent) and TYPE 2 (missing context -- even if told to read, the agent does not know WHAT to look for in the existing code).

The dedicated `luau-scripter` prompt has Mode B (Targeted Fixes) which mandates "Never modify a script without reading it first" and Mode C (Complex Feature Build) which mandates "decompose into layers" including a wiring layer that maps how new code connects to existing code. It also has Mode D (Feature Extension) which mandates "Deep Read and Structural Mapping" before any modifications. The general-purpose agent has none of these instincts.

**Why "just telling it to read" is not enough:**

Telling the agent "read Main script source first" solves the READ step but not the EXTRACT step. The agent needs to know what it is looking for. Without guidance, it reads 300 lines of Main, takes away a vague impression ("it manages keys and doors"), and then writes achievement hooks based on assumptions rather than the specific attribute names, RemoteEvent names, and payload shapes it just saw.

**Mitigation in task prompt:**

The prompt must make the read step actionable by specifying WHAT to extract:

```
=== MANDATORY INTEGRATION READS ===

BEFORE writing any code, you MUST read these existing scripts and extract specific data:

1. Read Main script in ServerScriptService:
   run_code({ code = [[ return game:GetService("ServerScriptService"):FindFirstChild("Main").Source ]] })

   EXTRACT from Main and write down:
   - Exact attribute names set on player (e.g., "Keys_Floor1", "CurrentFloor")
   - Exact RemoteEvent names fired (e.g., "KeyCollected", "GameStateChanged")
   - Exact payloads sent with each RemoteEvent (e.g., keyType: string, totalKeys: number)
   - How game state transitions work (what triggers floor completion, death, win)

2. Read Config module in ReplicatedStorage:
   run_code({ code = [[ return game:GetService("ReplicatedStorage").Modules:FindFirstChild("Config").Source ]] })

   EXTRACT: any constants your achievements will reference (key counts per floor, etc.)

YOUR NEW CODE MUST USE THE EXACT SAME:
- Attribute names (copy-paste from what you read, do not invent new ones)
- RemoteEvent names (listen to the ones that already exist)
- Payload shapes (destructure exactly what the server sends)

If Main sets player:SetAttribute("Keys_Floor1", count), your AchievementTracker
MUST listen for player:GetAttributeChangedSignal("Keys_Floor1"), not invent
"player.leaderstats.Keys" or any other mechanism.
```

**Why this works where a generic "read first" instruction fails:**

The agent is told not just to READ but to WRITE DOWN specific extracted data before proceeding. This forces it to actually parse the existing code's interface rather than skimming it. The explicit "copy-paste, do not invent" instruction prevents the common failure mode where the agent acknowledges what it read and then writes something different anyway.

### 7. Multi-script orchestration disorder

**Symptom:** When building a feature that requires multiple scripts (e.g., AchievementService ModuleScript + AchievementTracker server Script + AchievementDisplay client LocalScript + AchievementGui UI elements), the agent creates them in arbitrary order, sometimes creating the client script before the RemoteEvents it needs exist, or creating the UI before the ScreenGui parent exists. Each script may be internally correct but the wiring between them is broken.

Common wiring failures:
- Client script listens on `RemoteEvents:FindFirstChild("AchievementUnlocked")` but the event was never created
- Server script requires a ModuleScript that has not been created yet
- UI script references `AchievementGui.Frame.List` but the GUI was created with a different hierarchy
- Client and server disagree on RemoteEvent payload shape (server sends `{id, title, icon}`, client expects `{achievementId, name, imageId}`)

**Root cause:** The dedicated `luau-scripter` has Mode A (Full Build) which mandates "First -- the skeleton. Folders, RemoteEvents, base modules" and Mode C (Complex Feature Build) which mandates decomposing into Physical/Logic/Wiring layers and building infrastructure first. The general-purpose agent has no such sequencing instinct. It tends to write the most "interesting" script first (usually the logic script) and then scrambles to create dependencies after the fact.

**Mitigation in task prompt:**

```
=== BUILD ORDER (MANDATORY) ===

You are creating a multi-component feature. Follow this EXACT order:

STEP 1: INFRASTRUCTURE
- Create RemoteEvents in ReplicatedStorage/RemoteEvents/
  List every event needed: [AchievementUnlocked]
- Create ModuleScript first (other scripts depend on it)
- Verify: run_code to confirm events and modules exist

STEP 2: SERVER LOGIC
- Create server Script that requires the module, listens to game events
- Verify: read back source

STEP 3: UI STRUCTURE
- Create ScreenGui + all child elements (Frames, Labels, Lists)
- Verify: read back hierarchy

STEP 4: CLIENT LOGIC
- Create LocalScript that references UI elements and listens to RemoteEvents
- Verify: read back source

STEP 5: CROSS-CHECK
- Confirm every RemoteEvent that client listens on is the same one server fires
- Confirm every UI path the client references matches the actual GUI hierarchy
- Confirm ModuleScript exports match what server and client expect
```

### 8. Hallucinated integration points (inventing APIs that do not exist)

**Symptom:** Agent creates code that references Roblox APIs, services, or game-specific systems that do not exist. Examples: `game:GetService("AchievementService")` (not a real Roblox service), `player:FindFirstChild("leaderstats")` when no leaderstats folder was ever created, `CollectionService:GetTagged("Achievement")` when no Achievement tags exist in the game. The code looks plausible and compiles, but does nothing or errors at runtime.

**Root cause:** The general-purpose agent has strong pattern-matching for "how achievements usually work in Roblox games" from its training data, which includes many tutorials using leaderstats, BadgeService, or custom achievement frameworks. Without the dedicated prompt's emphasis on "architecture is the main source" and "follow what exists, do not improvise," the agent defaults to common tutorial patterns rather than integrating with the actual game.

**Mitigation in task prompt:**

```
=== WHAT EXISTS IN THIS GAME (USE ONLY THESE) ===

Services you can use:
- ServerScriptService, ReplicatedStorage, StarterGui, StarterPlayerScripts
- CollectionService (tags: Key, Interactable, ExitZone, NarrativeTrigger)
- Players, DataStoreService

Integration points for achievements:
- Player attributes set by Main: Keys_Floor1 (number), Keys_Floor2 (number), Keys_Floor3 (number)
- RemoteEvents: KeyCollected, DoorInteract, GameStateChanged, GameOver
- Game states: "Idle", "Active", "Escalation1", "Escalation2", "EscapeSequence", "Won", "Dead"

DO NOT USE or reference:
- BadgeService (we are not using Roblox badges)
- leaderstats (this game does not use leaderstats)
- Any service or attribute not listed above
- Any RemoteEvent not listed above

If you need something that does not exist, CREATE IT. Do not assume it exists.
```

### 9. Feature extension blindness (appending instead of interleaving)

**Symptom:** When told to add new variants, types, or behaviors to an existing script, the agent reads the script (if prompted to), then appends all new code at the bottom of the file. The new functions compile but are never called because the existing dispatcher/state machine/config table does not know about them. For example: adding 3 new phantom variants to PhantomController -- the agent adds `stalkerMovement()`, `swarmMovement()`, `mirrorMovement()` functions at line 565+ but never adds entries to the variant config table at line 30 or cases to the spawn dispatcher at line 400.

**Root cause:** The general-purpose agent does not have Mode D (Feature Extension) which the dedicated luau-scripter uses for this exact scenario. Mode D mandates: (1) Deep Read and Structural Mapping -- understanding every section of the existing script; (2) identifying ALL insertion points before writing; (3) rewriting the complete script.Source with additions woven in at the correct structural locations. Without this discipline, the agent treats "add new code" as "append new code."

**Why this is especially dangerous:** The code looks correct. Every new function is well-written. It passes a cursory review. But at runtime, nothing new happens because the existing control flow never reaches the appended code. This is a silent integration failure -- the hardest kind to debug.

**Mitigation in task prompt:**

```
=== FEATURE EXTENSION -- CRITICAL RULES ===

You are EXTENDING an existing script, not appending to it. This means:

1. READ the full existing script FIRST via run_code
2. MAP every location where new code must be added:
   - Config/constant tables where new entries go alongside existing ones
   - Type definitions that need new union members
   - Handler/dispatcher functions that need new cases
   - Spawn/initialization functions that need new conditions
   - Any other section that references the set of variants/types/features
3. REWRITE the ENTIRE script.Source with all additions woven in at the correct locations
4. DO NOT append code at the end -- that creates functions that are never called

For a 500+ line script, use chunked writes:
  script.Source = chunk1 .. chunk2 .. chunk3

Verify BOTH that existing features are preserved AND new features are present.
```

---

## EFFECTIVE TASK PROMPT TEMPLATE

When Game Master needs to use the general-purpose agent for Luau scripting work, the task prompt should include these sections. This compensates for the missing dedicated prompt:

```
=== ROLE CONTEXT ===
You are writing production-quality Luau code for a Roblox game through MCP (run_code).
Your code will be reviewed by a paranoid security engineer. It must pass on first review.
Every script uses --!strict. Every function has type annotations. Every connection has cleanup.

=== MCP PATTERNS ===
Tool: mcp__roblox-studio__run_code  (the ONLY method -- everything is Lua)

Creating scripts:
  run_code({ code = [[ ... ]] })
  Use [=[...]=] for script.Source (never [[...]] -- nested brackets break it)

VERIFICATION IS MANDATORY:
  After creating ANY script, read it back immediately:
  run_code({ code = [[ return game:GetService("..."):FindFirstChild("ScriptName").Source ]] })
  Check last 10 lines -- MCP truncates silently from the end.

For scripts over 150 lines, split into chunks:
  local part1 = [=[first half]=]
  local part2 = [=[second half]=]
  script.Source = part1 .. part2

String replacement in Source -- use string.find with plain=true, NOT gsub:
  local s, e = source:find("old", 1, true)
  source = source:sub(1, s-1) .. "new" .. source:sub(e+1)

For large modifications (50+ lines changed, multiple locations), rewrite the entire
script.Source with all changes applied. Do NOT use string replacement for large mods.

=== MODERN LUAU REQUIREMENTS ===
- --!strict at top of every file
- task.wait() not wait(), task.spawn() not spawn(), task.delay() not delay()
- Instance.new("Class") then set Parent -- never two-arg form
- Type annotations on all function parameters and return values
- pcall around DataStore, HTTP, anything that can fail
- Connection cleanup in PlayerRemoving
- Server-authoritative: client sends intent, server validates and executes

=== COMPLETENESS REQUIREMENT ===
Every script must be FULLY FUNCTIONAL. No TODOs, no placeholders, no "implement later."
Expected substance: 50-200 lines per script depending on complexity.
A 20-line skeleton is a FAILURE. Write the real implementation.

=== ITERATION REQUIREMENT ===
After writing the first version:
1. Switch to critic mode -- reread what you wrote
2. Check: is every function complete? Edge cases handled? Types correct?
3. Fix anything weak
4. Verify through MCP that code exists as intended
First draft submitted as final = failure.

=== TASK ===
[actual task description here]

=== EXPECTED OUTPUT ===
After completion, report:
SCRIPTS CREATED:
- [path] ([ClassName], [N] lines) -- [description]
VERIFICATION: [what you checked and confirmed through MCP]
READY FOR REVIEW
```

---

## SPECIFIC PATTERNS FOR COMPLEX INTEGRATION FEATURES (like Achievements)

When the task requires a multi-script feature that must hook into existing game systems:

### The three-phase approach: Read, Plan, Build

The general-purpose agent's biggest failure mode on complex features is not lack of coding skill -- it writes solid Luau. The failure is in the integration: connecting new code to existing systems correctly. This requires a disciplined three-phase approach that must be spelled out explicitly because the agent does not have it built in.

**Phase 1: READ existing systems (mandatory, before any creation)**

The agent must read the specific scripts it will integrate with and extract concrete data points. Not "understand the codebase" (too vague) but "find the exact attribute names, RemoteEvent names, and payload shapes." The task prompt must list exactly which scripts to read and exactly what to extract from each.

Pattern for task prompt:
```
BEFORE WRITING ANY CODE, complete these reads:

Read 1: Main script
  run_code to get ServerScriptService.Main.Source
  Extract and write down:
  - Player attributes: [list what to look for]
  - RemoteEvents fired: [list what to look for]
  - State transitions: [list what to look for]

Read 2: Config module
  run_code to get ReplicatedStorage.Modules.Config.Source
  Extract and write down:
  - Constants relevant to achievements: [list what to look for]

Read 3: Existing UI hierarchy
  run_code to get StarterGui children and structure
  Extract and write down:
  - What ScreenGuis exist, their DisplayOrders
  - Naming conventions used

WRITE YOUR EXTRACTED DATA before proceeding. This is your integration contract.
```

**Phase 2: PLAN the wiring (mandatory, before any creation)**

After reads are complete, the agent must write out the contract between its new scripts: which RemoteEvents will be created, what their payloads look like, which attributes will be read/set, which UI paths will be referenced. This catches wiring mismatches before they become bugs.

Pattern for task prompt:
```
AFTER READING, write your integration plan:

1. New RemoteEvents needed: [name -> payload shape]
2. Existing events I will listen to: [name -> what I expect]
3. Existing attributes I will read: [name -> type -> which script sets it]
4. New UI hierarchy: [ScreenGui -> Frame -> children, with names]
5. Build order: [what gets created first, second, third]
6. Cross-references: [client expects X from server, server fires X with Y payload]
```

**Phase 3: BUILD in infrastructure-first order**

Create RemoteEvents and shared modules first, then server logic, then UI structure, then client logic. Verify after each step. Cross-check at the end.

### What makes achievements specifically tricky

Achievements touch EVERY system in the game. Unlike a self-contained feature (flashlight, tutorial), achievements need to observe: key collection, door opens, floor completion, enemy encounters, death events, time tracking, collectible pickups. Each of these is managed by a different script with different patterns.

The general-purpose agent tends to either:
- Over-centralize: put all achievement logic in one monolithic script that tries to track everything itself (duplicating logic from Main, BuildingAI, etc.)
- Under-integrate: create a beautiful achievement module that nobody ever calls because it was not wired into the actual game events

The correct approach for this game (The Gullet) is:
- AchievementService ModuleScript in ReplicatedStorage: defines achievements, checks conditions, stores unlock state
- AchievementTracker Script in ServerScriptService: listens to existing game events (attribute changes on player, RemoteEvent fires, CollectionService tag events) and calls AchievementService to check/unlock
- AchievementDisplay LocalScript in StarterPlayerScripts: listens to a new AchievementUnlocked RemoteEvent, shows notification UI
- AchievementGui ScreenGui in StarterGui: the notification popup elements

The critical integration point is AchievementTracker -- it must listen to the EXACT signals that Main and BuildingAI already fire, not invent new ones. This is where the read-extract-plan discipline pays off.

---

## SPECIFIC PATTERNS FOR UI + LOCALSCRIPT TASKS (like TutorialController)

When the task involves creating both UI elements (ScreenGui hierarchy) and a controlling LocalScript:

### Create UI structure FIRST, then the script

The agent should create the ScreenGui, Frames, TextLabels, TextButtons through one `run_code` call, then create the LocalScript that references them in a second call. This ensures all UI references are valid when the script runs.

```
Step 1: Create ScreenGui + all child UI elements in one run_code call
Step 2: Verify UI structure exists (read back the hierarchy)
Step 3: Create LocalScript that references the UI elements
Step 4: Verify LocalScript source (read it back, check for truncation)
```

### UI creation through MCP -- key patterns

```lua
-- Create ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "TutorialGui"
gui.DisplayOrder = 15  -- above game UI, below narrative
gui.ResetOnSpawn = false
gui.Parent = game:GetService("StarterGui")

-- Create Frame with Scale sizing (MOBILE SAFE)
local frame = Instance.new("Frame")
frame.Name = "TutorialFrame"
frame.Size = UDim2.new(0.4, 0, 0.12, 0)  -- Scale, NOT Offset
frame.Position = UDim2.new(0.3, 0, 0.85, 0)
frame.AnchorPoint = Vector2.new(0, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.3
frame.Parent = gui

-- Add UICorner for polish
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame
```

Key rules for UI creation in task prompts:
- All sizing must use Scale (0-1 range), never Offset alone -- 60%+ players are mobile
- Buttons must be at least 44px equivalent (Scale of ~0.04 on Y axis minimum)
- Text minimum 14pt, preferably 16+
- Always set AnchorPoint when using Scale positioning
- Set DisplayOrder explicitly (avoid conflicts with other ScreenGuis)
- ResetOnSpawn = false for persistent UI, true for per-life UI

### LocalScript connecting to UI -- avoid common mistakes

Tell the agent explicitly:
```
The LocalScript must:
- WaitForChild for every UI element reference (race conditions are real)
- Use PlayerGui, not StarterGui, for runtime references
- Handle character death/respawn if the tutorial interacts with character state
- Clean up connections on completion (don't leave listeners after tutorial ends)
```

---

## WHEN TO USE GENERAL-PURPOSE vs DEDICATED LUAU-SCRIPTER

| Situation | Use |
|-----------|-----|
| Full game script build from architecture | Dedicated luau-scripter (always) |
| Bug fixes from reviewer | Dedicated luau-scripter (always) |
| Feature extension (adding to existing large script) | Dedicated luau-scripter (always -- Mode D) |
| Complex multi-script feature (3+ scripts, cross-system integration) | Dedicated luau-scripter (always) |
| Medium feature (2-3 scripts, limited integration) | General-purpose OK with heavy prompt guidance including integration reads |
| Small isolated feature (1-2 scripts) | General-purpose OK with heavy prompt guidance |
| Quick MCP verification or property fix | General-purpose OK (not really scripting) |
| Emergency fix when scripter pipeline is busy | General-purpose OK with full template above |

**Feature extension is especially dangerous for the general-purpose agent.** Adding new variants to a 500-line controller requires understanding the existing code's architecture, identifying 5-8 insertion points, and rewriting the entire script with additions woven in. The general-purpose agent will almost always append at the end instead of interleaving, creating code that compiles but never executes. Always use the dedicated luau-scripter with Mode D for this.

**The achievements scenario is a borderline case.** It is technically 3-4 scripts, which normally calls for the dedicated luau-scripter. However, if the general-purpose agent is given the full template PLUS the integration read/plan/build discipline, it can produce adequate results. The key risk is integration-point blindness (failure pattern #6). If the task prompt does not include explicit read instructions with specific extraction targets, the agent WILL invent integration points rather than discovering the real ones.

**Rule of thumb:** If the feature requires reading more than 2 existing scripts to understand integration points, use the dedicated luau-scripter. The general-purpose agent's context window gets consumed by the injected prompt template, leaving less room for the actual existing code it needs to understand.

---

## CHECKLIST FOR GAME MASTER BEFORE CALLING GENERAL-PURPOSE FOR LUAU WORK

Before sending a Luau scripting task to the general-purpose agent, verify your task prompt includes:

- [ ] Role context establishing production quality expectations
- [ ] MCP tool name and patterns (run_code, [=[...]=] delimiters)
- [ ] Verification requirement (read back after every creation)
- [ ] Modern Luau requirements (task.*, --!strict, type annotations)
- [ ] String replacement warning (plain=true for string.find, no gsub with code)
- [ ] Truncation awareness (check last 10 lines, chunk long scripts)
- [ ] Completeness requirement (no skeletons, expected line counts)
- [ ] Iteration requirement (first draft is not final)
- [ ] Architecture context if the script integrates with existing systems
- [ ] List of existing scripts/services it must integrate with
- [ ] Expected output format (SCRIPTS CREATED: marker for pipeline parsing)
- [ ] Genre and game context (horror needs different UI treatment than tycoon)

**Additional checklist items for integration features (achievements, progression, etc.):**

- [ ] Explicit "read these scripts first" instructions with run_code snippets
- [ ] Specific extraction targets for each read (attribute names, RemoteEvent names, payloads)
- [ ] "Write down extracted data" requirement before proceeding
- [ ] Integration plan requirement (new events, existing events to listen to, wiring)
- [ ] Build order specification (infrastructure -> server -> UI -> client)
- [ ] "What exists" inventory (available services, tags, attributes, events)
- [ ] "What does NOT exist" anti-inventory (no leaderstats, no BadgeService, etc.)
- [ ] Cross-check requirement at the end (client/server payload agreement, UI paths)

**Additional checklist items for feature extensions (adding to existing scripts):**

- [ ] Explicit "read the full existing script first" instruction
- [ ] "Map ALL insertion points before writing" instruction
- [ ] "Rewrite entire script.Source, do NOT append at the end" instruction
- [ ] "Use chunked writes for scripts over 500 lines" instruction
- [ ] "Verify both existing features preserved AND new features present" instruction
- [ ] Description of existing code patterns to match (naming, structure, error handling)

Missing any of these will degrade output quality. The dedicated luau-scripter has all of this baked in; the general-purpose agent needs it injected every time.

---

## SUMMARY OF ROOT CAUSES

| Problem | Root cause level | Fix level |
|---------|-----------------|-----------|
| Skeleton code | Missing role context (no quality bar) | Task prompt: role + completeness requirement |
| No verification | Missing work cycle (no verify step) | Task prompt: explicit verification mandate |
| Deprecated APIs | Missing domain knowledge (Luau specifics) | Task prompt: modern Luau requirements block |
| gsub special chars | Missing factual knowledge (Lua patterns) | Task prompt: string replacement warning |
| Wrong delimiters | Missing factual knowledge (MCP specifics) | Task prompt: [=[...]=] requirement |
| No iteration | Missing work cycle (no self-critique step) | Task prompt: iteration requirement |
| No type annotations | Missing domain standard (--!strict) | Task prompt: modern Luau requirements block |
| No connection cleanup | Missing priority (memory management) | Task prompt: server-authoritative + cleanup block |
| Integration-point blindness | Missing work cycle (no read-before-write) + missing context (does not know WHAT to extract) | Task prompt: explicit read instructions with extraction targets + write-down requirement |
| Multi-script wiring disorder | Missing work cycle (no infrastructure-first sequencing) | Task prompt: mandatory build order + cross-check |
| Hallucinated APIs/systems | Missing context (does not know what exists in this game) | Task prompt: explicit "what exists" + "what does NOT exist" inventories |
| Feature extension append-only | Missing work cycle (no structural mapping, no interleaving discipline) | Task prompt: insertion point mapping + full rewrite instruction + chunked writes |

Every one of these is a TYPE 2 problem (context/information). The general-purpose agent is capable -- it just does not receive the context that the dedicated agent's prompt provides permanently. The fix is always: inject the missing context into the task prompt.

The three integration patterns (#6, #7, #8) are specifically dangerous for integration-heavy features like achievements because they compound: the agent does not read existing code (#6), does not sequence its creation correctly (#7), and fills the gaps with hallucinated APIs (#8). Any one of these alone produces code that looks right but fails at runtime. Together they produce a feature that is internally coherent but completely disconnected from the actual game.

The feature extension pattern (#9) is the newest and most insidious failure mode because the code IS connected to the right systems -- the new functions reference the right services, use the right types, follow the right patterns -- but they are NEVER CALLED because they sit at the end of the file, outside the control flow of the existing dispatcher. The dedicated luau-scripter's Mode D solves this with structural mapping and mandatory interleaving.
