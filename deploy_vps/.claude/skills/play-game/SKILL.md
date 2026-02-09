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

### Step 0: Switch OBS Scene
Switch to PLAYING scene so viewers see the gameplay:
```bash
python C:/claudeblox/scripts/obs_control.py --scene PLAYING
```

### Step 1: Enter Play Mode
Press F5 to start the game:
```bash
python C:/claudeblox/scripts/action.py --key f5
python C:/claudeblox/scripts/action.py --wait 3
```

### Step 2: Verify Game Loaded
Take a screenshot and verify the game is running:
```bash
python C:/claudeblox/scripts/screenshot.py
```
Then read `C:/claudeblox/screenshots/screen.png` to see if game loaded.

### Step 3: Play Loop (20-50 iterations)
```
1. Take screenshot:
   python C:/claudeblox/scripts/screenshot.py

2. Read C:/claudeblox/screenshots/screen.png (Claude is multimodal)

3. Analyze what you see:
   - Where is the player?
   - What's around them?
   - Are there dangers?
   - Is there something to interact with?

4. Decide and execute action:
   - Move: python C:/claudeblox/scripts/action.py --key w
   - Jump: python C:/claudeblox/scripts/action.py --key space
   - Interact: python C:/claudeblox/scripts/action.py --key e
   - Look: python C:/claudeblox/scripts/action.py --move X Y
   - Click: python C:/claudeblox/scripts/action.py --click X Y

5. Wait briefly:
   python C:/claudeblox/scripts/action.py --wait 0.5

6. Repeat
```

### Step 4: Exit Play Mode
```bash
python C:/claudeblox/scripts/action.py --key escape
python C:/claudeblox/scripts/action.py --wait 1
python C:/claudeblox/scripts/action.py --key f5
```

### Step 5: Switch OBS Back
```bash
python C:/claudeblox/scripts/obs_control.py --scene CODING
```

### Step 6: Tweet About Gameplay
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
