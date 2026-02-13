"""
Action Watcher - monitors actions.txt, executes, and DELETES
============================================================

Computer-player writes actions.txt, this watcher:
1. Detects when actions.txt appears
2. Executes via execute_actions.py
3. Deletes actions.txt (execute_actions.py also deletes, but double-check)
4. Waits for next actions.txt

Usage:
    python action_watcher.py

Stop with Ctrl+C or kill the process.
"""
import time
import os
import subprocess
import sys

ACTIONS_FILE = "C:/claudeblox/actions.txt"
EXECUTOR_SCRIPT = "C:/claudeblox/scripts/execute_actions.py"
CHECK_INTERVAL = 0.2  # Check every 200ms

def main():
    print("=== ACTION WATCHER STARTED ===")
    print(f"Monitoring: {ACTIONS_FILE}")
    print(f"Executor: {EXECUTOR_SCRIPT}")
    print("Ctrl+C to stop")
    print()

    while True:
        try:
            if os.path.exists(ACTIONS_FILE):
                # Check file has content (not empty)
                size = os.path.getsize(ACTIONS_FILE)
                if size > 0:
                    print(f"[{time.strftime('%H:%M:%S')}] Found actions.txt ({size} bytes)")

                    # Execute
                    result = subprocess.run(
                        [sys.executable, EXECUTOR_SCRIPT],
                        capture_output=True,
                        text=True
                    )

                    if result.stdout:
                        print(result.stdout)
                    if result.stderr:
                        print("ERROR:", result.stderr)

                    # Delete file (execute_actions.py already deletes, but double-check)
                    if os.path.exists(ACTIONS_FILE):
                        os.remove(ACTIONS_FILE)
                        print("Deleted actions.txt")

                    print("Waiting for next actions.txt...\n")

            time.sleep(CHECK_INTERVAL)

        except KeyboardInterrupt:
            print("\nWatcher stopped by user")
            break
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(1)

if __name__ == "__main__":
    main()
