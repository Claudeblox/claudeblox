"""
Action Watcher - monitors actions.txt, executes, sends to bridge, deletes
=========================================================================

Computer-player writes actions.txt, this watcher:
1. Detects when actions.txt appears
2. Reads and parses actions
3. Sends actions to bridge (for history tracking)
4. Executes via execute_actions.py
5. Deletes actions.txt
6. Waits for next actions.txt

Usage:
    python action_watcher.py

Stop with Ctrl+C or kill the process.
"""
import time
import os
import subprocess
import sys
import requests
import json

ACTIONS_FILE = "C:/claudeblox/actions.txt"
EXECUTOR_SCRIPT = "C:/claudeblox/scripts/execute_actions.py"
BRIDGE_URL = "http://localhost:8585/actions"
CURRENT_LOG_FILE = "C:/claudeblox/current_log.txt"
GAME_STATE_FILE = "C:/claudeblox/game_state.json"
CHECK_INTERVAL = 0.2  # Check every 200ms


def parse_actions(content):
    """Parse actions.txt into commands and reasoning comments"""
    actions = []
    reasoning = []
    for line in content.strip().split('\n'):
        line = line.strip()
        if not line:
            continue
        if line.startswith('#'):
            reasoning.append(line)
        else:
            actions.append(line)
    return actions, reasoning


def get_current_log_file():
    """Read the current session log path from pointer file"""
    try:
        if os.path.exists(CURRENT_LOG_FILE):
            with open(CURRENT_LOG_FILE, 'r', encoding='utf-8') as f:
                return f.read().strip()
    except Exception:
        pass
    return None


def read_game_state():
    """Read current game state from JSON file"""
    try:
        if os.path.exists(GAME_STATE_FILE):
            with open(GAME_STATE_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
    except Exception:
        pass
    return None


def format_state_summary(state):
    """Format game state into compact markdown summary"""
    if not state:
        return "No state data"

    pos = state.get('playerPosition', {})
    room = state.get('currentRoom', 'Unknown')
    health = state.get('playerHealth', 100)
    dark = state.get('isDark', False)
    flashlight = state.get('flashlightOn', False)

    enriched = state.get('_enriched', {})
    cycle = enriched.get('cycle', 0)
    is_stuck = enriched.get('isStuck', False)
    stuck_cycles = enriched.get('stuckCycles', 0)

    collected = state.get('objectsCollected', [])

    # Format nearby objects (top 5)
    nearby = state.get('nearbyObjects', [])[:5]
    nearby_lines = []
    for obj in nearby:
        name = obj.get('name', '?')
        dist = obj.get('distance', 0)
        direction = obj.get('direction', {})
        angle = direction.get('angle', 0)
        nearby_lines.append(f"  - {name}: {dist:.0f} studs, angle {angle:.0f}°")

    nearby_text = '\n'.join(nearby_lines) if nearby_lines else "  (none)"

    stuck_text = f"YES ({stuck_cycles} cycles)" if is_stuck else "no"

    return f"""- Position: ({pos.get('x', 0):.0f}, {pos.get('z', 0):.0f}) | Room: {room}
- Health: {health} | Dark: {str(dark).lower()} | Flashlight: {'on' if flashlight else 'off'}
- Stuck: {stuck_text} | Cycle: {cycle}
- Collected: {collected if collected else '[]'}
- Nearby:
{nearby_text}"""


def log_agent_cycle(state_before, actions, reasoning, state_after):
    """Log complete agent cycle: state before → reasoning → actions → state after"""
    log_file = get_current_log_file()
    if not log_file or not os.path.exists(log_file):
        return

    timestamp = time.strftime('%H:%M:%S')

    # Format reasoning (strip # prefix)
    reasoning_text = '\n'.join(line.lstrip('#').strip() for line in reasoning)
    actions_text = '\n'.join(actions)

    before_summary = format_state_summary(state_before)
    after_summary = format_state_summary(state_after)

    md = f"""---
## Agent Action | {timestamp}

### State Before
{before_summary}

### Agent Reasoning
{reasoning_text}

### Actions Executed
```
{actions_text}
```

### State After
{after_summary}

"""

    try:
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(md)
    except Exception as e:
        print(f"Log write error: {e}")


def send_to_bridge(actions):
    """Send executed actions to bridge for history tracking"""
    try:
        requests.post(
            BRIDGE_URL,
            json={"actions": actions},
            timeout=2
        )
    except Exception as e:
        # Bridge might not be running, that's ok
        pass


def main():
    print("=== ACTION WATCHER STARTED ===")
    print(f"Monitoring: {ACTIONS_FILE}")
    print(f"Executor: {EXECUTOR_SCRIPT}")
    print(f"Bridge: {BRIDGE_URL}")
    print("Ctrl+C to stop")
    print()

    PROCESSING_FILE = ACTIONS_FILE + ".processing"

    while True:
        try:
            if os.path.exists(ACTIONS_FILE):
                # Claim the file — os.replace handles stale .processing on Windows
                try:
                    os.replace(ACTIONS_FILE, PROCESSING_FILE)
                except OSError:
                    time.sleep(CHECK_INTERVAL)
                    continue

                size = os.path.getsize(PROCESSING_FILE)
                if size > 0:
                    # Capture state BEFORE execution
                    state_before = read_game_state()

                    # Read actions from renamed file
                    with open(PROCESSING_FILE, 'r', encoding='utf-8') as f:
                        content = f.read()

                    actions, reasoning = parse_actions(content)
                    print(f"[{time.strftime('%H:%M:%S')}] Found {len(actions)} actions")

                    # Send to bridge for history
                    send_to_bridge(actions)

                    # Execute — try/finally guarantees .processing is ALWAYS cleaned up,
                    # even on TimeoutExpired or any other exception from subprocess.run
                    result = None
                    try:
                        result = subprocess.run(
                            [sys.executable, EXECUTOR_SCRIPT],
                            capture_output=True,
                            text=True,
                            timeout=90
                        )
                    except subprocess.TimeoutExpired:
                        print(f"[{time.strftime('%H:%M:%S')}] WARNING: action executor timed out (90s), continuing")
                    finally:
                        # Always delete processing file so watcher never deadlocks
                        try:
                            if os.path.exists(PROCESSING_FILE):
                                os.remove(PROCESSING_FILE)
                        except Exception as cleanup_err:
                            print(f"WARNING: could not remove processing file: {cleanup_err}")

                    if result and result.stdout:
                        lines = result.stdout.strip().split('\n')
                        for line in lines[-5:]:
                            print(f"  {line}")

                    if result and result.stderr:
                        print("ERROR:", result.stderr)

                    # Wait a moment for game state to update
                    time.sleep(0.5)

                    # Capture state AFTER execution and log cycle
                    state_after = read_game_state()
                    log_agent_cycle(state_before, actions, reasoning, state_after)

                    print(f"[{time.strftime('%H:%M:%S')}] Done. Waiting...\n")

            time.sleep(CHECK_INTERVAL)

        except KeyboardInterrupt:
            print("\nWatcher stopped by user")
            break
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(1)


if __name__ == "__main__":
    main()
