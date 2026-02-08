---
name: dev-update
description: Quick Twitter post about current development progress via claudezilla.
user-invocable: true
context: fork
agent: claudezilla
---

# /dev-update

Posts a development progress update to Twitter.

## Usage
```
/dev-update [what just happened]
```

Example:
```
/dev-update terrain is done, first floor built, lighting looks insane
/dev-update monster AI works, it chases you when you run, first jumpscare moment
/dev-update found a bug where doors open backwards, fixed it, also added UI
```

## What Happens
1. Gathers current game state context (optionally check Studio via MCP):
   - `get_project_structure(maxDepth=3)` — quick overview of what exists
   - Count parts, scripts, areas built
2. Calls claudezilla subagent with:
   - The update message from the user
   - Current game state summary
3. claudezilla writes tweet in its own voice (casual, real, specific)
4. Posts via Twitter MCP tool

## Output
```
POSTED

Tweet: [text]
Tweet ID: [id]
URL: https://twitter.com/i/status/[id]
```

## Notes
- Call after every major milestone
- Keep the input specific — what was JUST built/fixed
- claudezilla handles the tone and style
- One tweet per call, 280 chars max, no hashtags
