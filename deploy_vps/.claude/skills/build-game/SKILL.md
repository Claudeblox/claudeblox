---
name: build-game
description: Full build cycle — architect designs, scripter codes, world-builder creates environment. Use to start building or add major features.
user-invocable: true
context: fork
---

# /build-game

Runs the full build pipeline for the Roblox game through MCP.

## ⛔ MANDATORY CHECKLIST — BLOCKERS

**After EACH subagent, verify these. If ANY fails → FIX BEFORE NEXT STEP.**

### After luau-scripter:
```lua
run_code([[
  local SSS = game:GetService("ServerScriptService")
  local SP = game:GetService("StarterPack")

  local checks = {}

  -- GameStateBridge MUST exist
  local bridge = SSS:FindFirstChild("GameStateBridge")
  checks.GameStateBridge = bridge and "✅ EXISTS" or "❌ MISSING — BLOCKER!"

  -- Flashlight MUST exist for horror games
  local flashlight = SP:FindFirstChild("Flashlight")
  checks.Flashlight = flashlight and "✅ EXISTS" or "❌ MISSING — BLOCKER!"

  local result = "=== SCRIPTER CHECKLIST ===\n"
  for k, v in checks do
    result = result .. k .. ": " .. v .. "\n"
  end
  return result
]])
```
**If GameStateBridge or Flashlight MISSING → Call luau-scripter again to create them!**

### After world-builder:
```lua
run_code([[
  local Lighting = game:GetService("Lighting")
  local CS = game:GetService("CollectionService")

  local checks = {}

  -- Lighting MUST be configured
  checks.Brightness = Lighting.Brightness == 0 and "✅ 0" or "❌ " .. Lighting.Brightness .. " — BLOCKER!"
  checks.Atmosphere = not Lighting:FindFirstChild("Atmosphere") and "✅ NONE" or "❌ EXISTS — BLOCKER!"
  checks.Sky = not Lighting:FindFirstChild("Sky") and "✅ NONE" or "❌ EXISTS — BLOCKER!"

  -- SpawnLocation MUST exist
  local spawn = workspace:FindFirstChildOfClass("SpawnLocation", true)
  checks.SpawnLocation = spawn and "✅ EXISTS" or "❌ MISSING — BLOCKER!"

  -- CameraPoints for screenshots
  local cameraPoints = CS:GetTagged("CameraPoint")
  checks.CameraPoints = #cameraPoints >= 1 and "✅ " .. #cameraPoints .. " found" or "⚠️ NONE — add for screenshots"

  -- PointLights for visibility
  local lights = 0
  for _, obj in workspace:GetDescendants() do
    if obj:IsA("PointLight") or obj:IsA("SpotLight") then lights = lights + 1 end
  end
  checks.Lights = lights >= 3 and "✅ " .. lights .. " lights" or "❌ " .. lights .. " — need more!"

  local result = "=== WORLD-BUILDER CHECKLIST ===\n"
  for k, v in checks do
    result = result .. k .. ": " .. v .. "\n"
  end
  return result
]])
```
**If ANY ❌ BLOCKER → Call world-builder again to fix!**

## Usage
```
/build-game
/build-game [specific feature to build]
```

## Pipeline

### Step 0: Switch OBS Scene
Switch to CODING scene so viewers can see the build process:
```bash
python C:/claudeblox/scripts/obs_control.py --scene CODING
```

### Step 1: Check Current State
Before building, inspect what already exists in Studio:

```lua
run_code([[
  local function getStructure(instance, depth, maxDepth)
    depth = depth or 0
    maxDepth = maxDepth or 5
    if depth > maxDepth then return "" end

    local indent = string.rep("  ", depth)
    local result = indent .. instance.ClassName .. " '" .. instance.Name .. "'\n"

    for _, child in instance:GetChildren() do
      result = result .. getStructure(child, depth + 1, maxDepth)
    end
    return result
  end

  local result = ""
  result = result .. "=== ServerScriptService ===\n" .. getStructure(game:GetService("ServerScriptService"), 0, 3)
  result = result .. "\n=== ReplicatedStorage ===\n" .. getStructure(game:GetService("ReplicatedStorage"), 0, 3)
  result = result .. "\n=== Workspace ===\n" .. getStructure(workspace, 0, 3)

  return result
]])
```

This determines whether we're starting fresh or adding to an existing game.

### Step 2: Architecture
Call the **roblox-architect** subagent:
- If first build: design the entire game
- If adding a feature: design just that feature within existing architecture
- Architect must account for MCP capabilities (primitives, no custom meshes)

Wait for architecture document output.

### Step 3: Code
Switch OBS to show code being written:
```bash
python C:/claudeblox/scripts/obs_control.py --scene CODING
```

Call the **luau-scripter** subagent with the architecture:
- Create folder structure first (Modules, RemoteEvents)
- Create all scripts using `run_code` with Instance.new()
- Verify scripts exist after creation

### Step 4: World
Switch OBS to show world being built:
```bash
python C:/claudeblox/scripts/obs_control.py --scene BUILDING
```

Call the **world-builder** subagent with the architecture:
- Set up Lighting (NO Atmosphere — causes white washout!)
- Build terrain/rooms using `run_code` with Instance.new()
- Add PointLights inside lamp parts (Brightness 0.1-0.3, Range 10-15)
- Create UI elements in StarterGui
- Tag interactive objects, set attributes

**CRITICAL LIGHTING RULES:**
- Do NOT create Atmosphere (any Density causes white)
- Do NOT create Sky (empty textures = white)
- Do NOT use Neon material on large surfaces
- Use ONLY PointLight inside SmoothPlastic lamp parts
- Lighting.Brightness = 0, Ambient = [0,0,0]
- FogColor = [0,0,0], FogEnd = 80

### Step 5: Screenshots for Twitter (MANDATORY)
After world-builder finishes, take promotional screenshots.

**MUST call showcase-photographer:**
```
Task(
  subagent_type: "showcase-photographer",
  model: "sonnet",
  description: "take showcase screenshots",
  prompt: "Take screenshots of all CameraPoints. Save to C:/claudeblox/screenshots/showcase/"
)
```

If no CameraPoints exist → go back to world-builder and add them!

Screenshots are used by claudezilla for milestone tweets.

### Step 5.5: Start Game Bridge (MANDATORY for play-test)
**Before any play-testing, start game_bridge.py:**
```bash
Start-Process python -ArgumentList "C:/claudeblox/scripts/game_bridge.py" -WindowStyle Hidden
```

Verify it's running:
```bash
Test-NetConnection -ComputerName localhost -Port 8585
```

### Step 5.6: Visual Play-Test (MANDATORY)
**DO NOT SKIP visual play-test!**

```
Task(
  subagent_type: "computer-player",
  model: "sonnet",
  description: "play-test the game",
  prompt: "
    === LEVEL CONTEXT ===
    [Pass level info from architecture here]

    Play the game for at least 20 actions.
    Report any bugs, issues, or improvements needed.
  "
)
```

**After play-test, stop the bridge:**
```bash
Get-NetTCPConnection -LocalPort 8585 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

### Step 6: Verify
After both agents finish, verify via run_code:

```lua
run_code([[
  local stats = {scripts = 0, parts = 0, remotes = 0}

  -- Count scripts
  local function countScripts(instance)
    if instance:IsA("LuaSourceContainer") then
      stats.scripts = stats.scripts + 1
    end
    for _, child in instance:GetChildren() do
      countScripts(child)
    end
  end
  countScripts(game:GetService("ServerScriptService"))
  countScripts(game:GetService("ReplicatedStorage"))
  countScripts(game:GetService("StarterPlayer"))
  countScripts(game:GetService("StarterGui"))

  -- Count parts
  for _, obj in workspace:GetDescendants() do
    if obj:IsA("BasePart") then
      stats.parts = stats.parts + 1
    end
  end

  -- Count RemoteEvents
  local function countRemotes(instance)
    if instance:IsA("RemoteEvent") or instance:IsA("RemoteFunction") then
      stats.remotes = stats.remotes + 1
    end
    for _, child in instance:GetChildren() do
      countRemotes(child)
    end
  end
  countRemotes(game:GetService("ReplicatedStorage"))

  -- Check Lighting
  local Lighting = game:GetService("Lighting")
  local hasAtmosphere = Lighting:FindFirstChild("Atmosphere") ~= nil

  return string.format(
    "Scripts: %d\nParts: %d\nRemoteEvents: %d\nAtmosphere: %s\nLighting.Brightness: %s",
    stats.scripts, stats.parts, stats.remotes,
    hasAtmosphere and "EXISTS (BAD!)" or "none (good)",
    Lighting.Brightness
  )
]])
```

### Step 7: Tweet Progress
Call **claudezilla** agent or use Twitter MCP to post about what was built.
Use screenshots from `C:/claudeblox/screenshots/showcase/` for milestone tweets.

### Step 8: Report
Return summary of what was created:
```
BUILD COMPLETE

Scripts: X created
Parts: X created
UI Elements: X
RemoteEvents: X
Tags: X applied
Part Count: X (mobile safe: YES/NO)
Lighting: PointLights only, no Atmosphere

Ready for: /test-game
```
