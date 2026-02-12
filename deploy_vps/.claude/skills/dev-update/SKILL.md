---
name: dev-update
description: Quick Twitter post about current development progress via claudezilla. Can optionally publish to Roblox first.
user-invocable: true
context: fork
agent: claudezilla
---

# /dev-update

Posts a development progress update to Twitter. For major milestones, can also publish the game to Roblox first.

## Usage
```
/dev-update [what just happened]
/dev-update publish [what just happened]
```

Example:
```
/dev-update terrain is done, first floor built, lighting looks insane
/dev-update publish level 5 complete, morgue section done, ready for players
/dev-update found a bug where doors open backwards, fixed it, also added UI
```

## What Happens

### Without "publish" keyword:
1. Gathers current game state context (optionally check Studio via MCP):
   - `get_project_structure(maxDepth=3)` — quick overview of what exists
   - Count parts, scripts, areas built
2. Calls claudezilla subagent with:
   - The update message from the user
   - Current game state summary
3. claudezilla writes tweet in its own voice (casual, real, specific)
4. Posts via Twitter MCP tool

### With "publish" keyword (for milestones):
1. Call **roblox-publisher** subagent first:
   - Saves the place in Studio
   - Runs publish.py to upload to Roblox
   - Returns game URL and status
2. Then call claudezilla with:
   - What was done
   - Publish status (SUCCESS/FAILED)
   - Game URL (if published successfully)
3. claudezilla tweets with game URL if available

## Workflow

```
/dev-update level 5 complete, morgue section done
    |
    v
[claudezilla posts tweet about progress]

/dev-update publish level 5 complete, morgue section done
    |
    v
[roblox-publisher publishes game]
    |
    v
[claudezilla posts tweet with game URL]
```

## Output
```
POSTED

Tweet: [text]
Tweet ID: [id]
URL: https://twitter.com/i/status/[id]
Published: YES/NO (if publish was requested)
Game URL: https://www.roblox.com/games/[ID] (if published)
```

## Notes
- Call after every major milestone
- Keep the input specific — what was JUST built/fixed
- Use "publish" keyword when the game should be playable
- claudezilla handles the tone and style
- One tweet per call, 280 chars max, no hashtags
