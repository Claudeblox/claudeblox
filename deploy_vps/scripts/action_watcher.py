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
CHECK_INTERVAL = 0.2  # Check every 200ms


def parse_actions(content):
    """Parse actions.txt into list of commands"""
    actions = []
    for line in content.strip().split('\n'):
        line = line.strip()
        if line and not line.startswith('#'):
            actions.append(line)
    return actions


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

    while True:
        try:
            if os.path.exists(ACTIONS_FILE):
                # Check file has content (not empty)
                size = os.path.getsize(ACTIONS_FILE)
                if size > 0:
                    # Read actions before execution
                    with open(ACTIONS_FILE, 'r', encoding='utf-8') as f:
                        content = f.read()

                    actions = parse_actions(content)
                    print(f"[{time.strftime('%H:%M:%S')}] Found {len(actions)} actions")

                    # Send to bridge for history
                    send_to_bridge(actions)

                    # Execute
                    result = subprocess.run(
                        [sys.executable, EXECUTOR_SCRIPT],
                        capture_output=True,
                        text=True
                    )

                    if result.stdout:
                        # Print shortened output
                        lines = result.stdout.strip().split('\n')
                        for line in lines[-5:]:  # Last 5 lines
                            print(f"  {line}")

                    if result.stderr:
                        print("ERROR:", result.stderr)

                    # Delete file
                    if os.path.exists(ACTIONS_FILE):
                        os.remove(ACTIONS_FILE)

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
