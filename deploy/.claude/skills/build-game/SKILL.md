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
```
mcp__robloxstudio__get_project_structure
  maxDepth: 5
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
- Create all scripts using `create_object` + `set_script_source`
- Create RemoteEvents using `mass_create_objects`
- Verify with `get_project_structure(scriptsOnly=true)`

### Step 4: World
Switch OBS to show world being built:
```bash
python C:/claudeblox/scripts/obs_control.py --scene BUILDING
```

Call the **world-builder** subagent with the architecture:
- Set up Lighting (NO Atmosphere — causes white washout!)
- Build terrain/rooms using `mass_create_objects_with_properties`
- Add PointLights inside lamp parts (Brightness 0.1-0.3, Range 10-15)
- Create UI elements in StarterGui
- Tag interactive objects, set attributes
- Verify part count with `get_project_structure`

**CRITICAL LIGHTING RULES:**
- Do NOT create Atmosphere (any Density causes white)
- Do NOT create Sky (empty textures = white)
- Do NOT use Neon material on large surfaces
- Use ONLY PointLight inside SmoothPlastic lamp parts
- Lighting.Brightness = 0, Ambient = [0,0,0]
- FogColor = [0,0,0], FogEnd = 80

### Step 5: Verify
After both agents finish:
- `get_project_structure(maxDepth=10)` — full structure check
- `get_project_structure(scriptsOnly=true)` — all scripts present
- Spot-check a few scripts with `get_script_source`
- Verify no Atmosphere exists in Lighting

### Step 6: Tweet Progress
Call **claudezilla** agent or use Twitter MCP to post about what was built.

### Step 7: Report
Return summary of what was created:
```
BUILD COMPLETE

Scripts: X created (Y total lines)
Parts: X created
UI Elements: X
RemoteEvents: X
Tags: X applied
Part Count: X (mobile safe: YES/NO)
Lighting: PointLights only, no Atmosphere

Ready for: /test-game
```
