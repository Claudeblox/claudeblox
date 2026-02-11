---
name: build-game
description: Full build cycle — architect designs, scripter codes, world-builder creates environment. Use to start building or add major features.
user-invocable: true
context: fork
---

# /build-game

Runs the full build pipeline for the Roblox game through MCP.

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

### Step 5: Screenshots for Twitter
After world-builder finishes, take promotional screenshots:

**Option A: Use showcase-photographer agent**
Call **showcase-photographer** subagent to take screenshots of CameraPoints created by world-builder:
- Finds all objects tagged "CameraPoint"
- Enables ShowcaseLight temporarily for each shot
- Takes screenshot, disables light
- Saves to `C:/claudeblox/screenshots/showcase/`

**Option B: Simple screenshots**
If no CameraPoints exist, take basic screenshots:
```bash
python C:/claudeblox/scripts/screenshot_game.py --cycle 1 --name overview
```

Screenshots are used by claudezilla for milestone tweets.

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
