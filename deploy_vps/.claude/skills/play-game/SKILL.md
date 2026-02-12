---
name: play-game
description: Visually play the game — take screenshots, perform actions, find bugs, save best moments for Twitter.
user-invocable: true
context: fork
agent: computer-player
---

# /play-game

Play the game visually. Take screenshots, analyze, perform actions, report bugs.

---

## Step 1: Setup

**Create cycle folder:**
```bash
mkdir C:/claudeblox/screenshots/cycle_%CYCLE_NUMBER%
mkdir C:/claudeblox/screenshots/cycle_%CYCLE_NUMBER%/for_twitter
```

**Start game bridge:**
```bash
start /B python C:/claudeblox/scripts/game_bridge.py
```

**Verify bridge is running (wait 2 sec, then check):**
```bash
curl http://localhost:8585
```
- If returns JSON → ready
- If connection refused → wait 2 sec, try again, max 3 attempts

**Switch OBS to gameplay:**
```bash
python C:/claudeblox/scripts/obs_control.py --scene PLAYING
```

---

## Step 2: Enter Play Mode

**Press F5 to start the game:**
```
PLAY
WAIT 3
SCREENSHOT start
```

Write to `C:/claudeblox/actions.txt`, then execute:
```bash
python C:/claudeblox/scripts/execute_actions.py
```

**Verify game loaded:**
```bash
python C:/claudeblox/scripts/screenshot.py
```

Read `C:/claudeblox/screenshots/screen.png` — check:
- Player character visible
- UI elements present
- Game world loaded (not gray/loading)

If not loaded → wait 2 sec, screenshot again, max 3 attempts.

---

## Step 3: Play Loop (20-50 iterations)

Each iteration:
1. Analyze current screenshot
2. Decide action based on what you see
3. Write actions to `C:/claudeblox/actions.txt`
4. Execute: `python C:/claudeblox/scripts/execute_actions.py`
5. Take screenshot, analyze result
6. Repeat

**Available commands for actions.txt:**
```
FORWARD [seconds]      - move forward (default 1s)
BACK [seconds]         - move backward
LEFT [seconds]         - strafe left
RIGHT [seconds]        - strafe right
TURN_LEFT [degrees]    - turn camera left (default 45)
TURN_RIGHT [degrees]   - turn camera right
TURN_AROUND            - 180 degree turn
JUMP                   - press space
INTERACT               - press E
FLASHLIGHT             - press F
SPRINT_FORWARD [sec]   - run forward with shift
WAIT [seconds]         - pause
SCREENSHOT [name]      - take screenshot
THOUGHT "text"         - write to stream overlay
PLAY                   - press F5 (enter play mode)
STOP                   - press Shift+F5 (exit play mode)
KEY [key]              - press any key
```

**Example actions.txt:**
```
THOUGHT "exploring the dark corridor"
FORWARD 2
TURN_RIGHT 45
SCREENSHOT corridor_1
WAIT 0.5
INTERACT
SCREENSHOT after_interact
```

**Save interesting screenshots for Twitter:**

When you see something tweet-worthy (cool moment, funny bug, impressive visual, progress milestone):
```bash
copy C:/claudeblox/screenshots/screen.png C:/claudeblox/screenshots/cycle_%CYCLE_NUMBER%/for_twitter/moment_N.png
```

Save 2-4 best screenshots per session.

---

## Step 4: Exit Play Mode

**Stop the game:**
```
SCREENSHOT final
THOUGHT "play session complete"
STOP
```

Write to actions.txt and execute:
```bash
python C:/claudeblox/scripts/execute_actions.py
```

---

## Step 5: Cleanup

**Switch OBS back:**
```bash
python C:/claudeblox/scripts/obs_control.py --scene CODING
```

**Stop game bridge:**
```bash
for /f "tokens=5" %a in ('netstat -ano ^| findstr :8585') do taskkill /PID %a /F
```

---

## Step 6: Report + Tweet

**Generate play session report:**

```
PLAY SESSION REPORT

Cycle: [N]
Duration: [X] actions over [Y] screenshots
Game State: [playing / game over / crashed]

What I saw:
- [describe visuals, atmosphere, what worked]
- [what looked broken or off]

What I did:
- [key actions taken]
- [what I was trying to accomplish]

Issues Found:
- [CRITICAL/HIGH/MEDIUM/LOW]: [description]
- [CRITICAL/HIGH/MEDIUM/LOW]: [description]

Screenshots saved for Twitter:
- for_twitter/moment_1.png — [why it's interesting]
- for_twitter/moment_2.png — [why it's interesting]

Overall Impression:
[Is this fun? Would a player enjoy this? What's missing?]
```

**Call claudezilla for tweet:**

```
Task(
  subagent_type: "claudezilla",
  description: "tweet gameplay",
  prompt: "Post about playing the game.

Screenshots available in: C:/claudeblox/screenshots/cycle_[N]/for_twitter/
- moment_1.png — [description]
- moment_2.png — [description]

What happened: [brief summary of play session]
Interesting moment: [what to highlight]

Pick the best screenshot and post."
)
```

---

## Important

1. **Always PLAY (F5) before testing** — game won't respond in Editor mode
2. **Always STOP (Shift+F5) after testing** — don't leave game running
3. **Use THOUGHT for stream** — viewers see your thoughts on overlay
4. **Save 2-4 screenshots for Twitter** — best moments only
5. **Report ALL issues** — even small ones, with priority level
