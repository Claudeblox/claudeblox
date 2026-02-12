---
name: play-game
description: Claude visually plays the game using screenshots and keyboard/mouse actions. Requires VPS with Roblox Studio running.
user-invocable: true
context: fork
agent: computer-player
---

# /play-game

Launches a visual play session. The computer-player subagent takes screenshots, analyzes them, and performs actions.

## Prerequisites
- Shadow PC (VPS) must be running with Roblox Studio open
- screenshot.py and action.py in C:/claudeblox/scripts/
- Game must be built (run /build-game first)
- OBS must be running for stream

## Pipeline

### Step 0: Start Game Bridge
Start scripts/game_bridge.py and verify port 8585 is responding before continuing. Stop game_bridge after play session ends.

### Step 1: Switch OBS Scene
Switch OBS to PLAYING scene so viewers see the gameplay.

### Step 2: Enter Play Mode (CRITICAL!)
**MUST press F5 to start the game before any gameplay.**

Write to actions.txt:
```
PLAY
WAIT 3
SCREENSHOT start
```

Then execute:
```bash
python C:/claudeblox/scripts/execute_actions.py
```

Or manually:
```bash
python C:/claudeblox/scripts/action.py --key f5
```
Wait 3 seconds for game to load.

### Step 3: Verify Game Loaded
Take a screenshot and verify the game is running:
```bash
python C:/claudeblox/scripts/screenshot.py
```
Then read `C:/claudeblox/screenshots/screen.png` to see if game loaded.

**What to check:**
- Player character visible
- UI elements present
- Game world loaded (not gray/loading screen)

### Step 4: Play Loop (20-50 iterations)

Use execute_actions.py with actions.txt for batched actions:

**Example actions.txt:**
```
THOUGHT "exploring the first room"
FORWARD 1
TURN_RIGHT 45
SCREENSHOT room1
WAIT 0.5
FLASHLIGHT
FORWARD 2
INTERACT
```

**Available commands:**
- `FORWARD [seconds]` - move forward (default 1s)
- `BACK [seconds]` - move backward
- `LEFT [seconds]` - strafe left
- `RIGHT [seconds]` - strafe right
- `TURN_LEFT [degrees]` - turn camera left (default 45)
- `TURN_RIGHT [degrees]` - turn camera right
- `TURN_AROUND` - 180 degree turn
- `JUMP` - press space
- `INTERACT` - press E
- `FLASHLIGHT` - press F
- `SPRINT_FORWARD [seconds]` - run forward with shift
- `WAIT [seconds]` - pause
- `SCREENSHOT [name]` - take screenshot
- `THOUGHT "text"` - write to stream overlay
- `PLAY` - press F5 (enter play mode)
- `STOP` - press Shift+F5 (exit play mode)
- `KEY [key]` - press any key

**Workflow:**
1. Write commands to `C:/claudeblox/actions.txt`
2. Run `python C:/claudeblox/scripts/execute_actions.py`
3. Actions file is deleted after execution
4. Take screenshot, analyze, repeat

### Step 5: Exit Play Mode (CRITICAL!)
**MUST exit Play mode after testing is complete.**

Write to actions.txt:
```
SCREENSHOT final
THOUGHT "play session complete"
STOP
```

Then execute:
```bash
python C:/claudeblox/scripts/execute_actions.py
```

Or manually:
```bash
python C:/claudeblox/scripts/action.py --key shift+f5
```

### Step 6: Switch OBS Back and Stop Game Bridge
Switch OBS back to CODING scene. Stop game_bridge.py.

### Step 7: Tweet About Gameplay
Post about the play experience:
```
mcp__twitter__post_tweet
  text: "just played my own game for 10 minutes. [short observation]"
```

## Output

Generate play session report:
```
PLAY SESSION REPORT

Duration: ~X actions over Y screenshots
Game State: [menu / playing / game over / crashed]

What I saw:
- [describe the visual state of the game]
- [what worked well visually]
- [what looked broken or off]

What I did:
- [list key actions taken]
- [what I was trying to accomplish]

Issues Found:
- [visual bugs]
- [gameplay issues]
- [UX problems]
- [things that felt wrong]

Overall Impression:
[Is this fun? Would a player enjoy this? What's missing?]

Suggestions for next iteration:
- [specific improvements to make]
```

## Important Notes

1. **Always PLAY before testing** - Game won't respond to inputs in Editor mode
2. **Always STOP after testing** - Don't leave game running
3. **Use THOUGHT for stream** - Viewers see your thoughts
4. **Save good screenshots** - They're used for tweets later
