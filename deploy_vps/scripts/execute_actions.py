# execute_actions.py
# Reads simple commands from actions.txt and executes them
# LLM writes commands, this script runs them

import subprocess
import time
import sys
import os

try:
    import pyautogui
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyautogui"])
    import pyautogui

ACTIONS_FILE = "C:/claudeblox/actions.txt"
ACTION_SCRIPT = "C:/claudeblox/scripts/action.py"
SCREENSHOT_SCRIPT = "C:/claudeblox/scripts/screenshot_game.py"
THOUGHT_SCRIPT = "C:/claudeblox/scripts/write_thought.py"

def action(cmd):
    """Run action.py with given arguments"""
    subprocess.run(f"python {ACTION_SCRIPT} {cmd}", shell=True)
    time.sleep(0.15)

def screenshot(name):
    """Take screenshot to temp folder"""
    subprocess.run(f"python {SCREENSHOT_SCRIPT} --name {name}", shell=True)

def thought(text):
    """Write thought to stream overlay"""
    subprocess.run(f'python {THOUGHT_SCRIPT} "{text}"', shell=True)

def execute_command(line):
    """Parse and execute one command"""
    line = line.strip()
    if not line or line.startswith("#"):
        return  # skip empty lines and comments

    parts = line.split(maxsplit=1)
    cmd = parts[0].upper()
    arg = parts[1] if len(parts) > 1 else ""

    # Movement commands
    if cmd == "FORWARD":
        seconds = float(arg) if arg else 1
        action(f"--hold w --duration {seconds}")

    elif cmd == "BACK":
        seconds = float(arg) if arg else 1
        action(f"--hold s --duration {seconds}")

    elif cmd == "LEFT":
        seconds = float(arg) if arg else 1
        action(f"--hold a --duration {seconds}")

    elif cmd == "RIGHT":
        seconds = float(arg) if arg else 1
        action(f"--hold d --duration {seconds}")

    # Turn commands (camera always horizontal, Y=0)
    elif cmd == "TURN_LEFT":
        degrees = int(arg) if arg else 45
        pixels = int(degrees * 6.67)  # ~600px = 90 degrees
        action(f"--move-relative -- -{pixels} 0")

    elif cmd == "TURN_RIGHT":
        degrees = int(arg) if arg else 45
        pixels = int(degrees * 6.67)
        action(f"--move-relative -- {pixels} 0")

    elif cmd == "TURN_AROUND":
        action("--move-relative -- 1200 0")  # 180 degrees

    # Actions
    elif cmd == "INTERACT":
        action("--key e")

    elif cmd == "FLASHLIGHT":
        action("--key f")

    elif cmd == "JUMP":
        action("--key space")

    elif cmd == "SPRINT_ON":
        action("--hold shift --duration 0.1")  # start holding shift
        # Note: for continuous sprint, use SPRINT_FORWARD

    elif cmd == "SPRINT_FORWARD":
        seconds = float(arg) if arg else 1
        # Hold shift+w together using pyautogui directly
        pyautogui.keyDown('shift')
        pyautogui.keyDown('w')
        time.sleep(seconds)
        pyautogui.keyUp('w')
        pyautogui.keyUp('shift')
        print(f"Sprint forward for {seconds}s")

    # Utility
    elif cmd == "WAIT":
        seconds = float(arg) if arg else 1
        time.sleep(seconds)

    elif cmd == "SCREENSHOT":
        name = arg if arg else "shot"
        screenshot(name)

    elif cmd == "THOUGHT":
        text = arg.strip('"\'')
        thought(text)

    # Play mode control
    elif cmd == "PLAY":
        # Press F5 to enter Play mode, wait for game to load
        action("--key f5")
        time.sleep(3)  # Wait for game to load

    elif cmd == "STOP":
        # Press Shift+F5 to exit Play mode
        subprocess.run(f"python {ACTION_SCRIPT} --key shift+f5", shell=True)
        time.sleep(1)  # Wait for editor to return

    # Raw key (for anything else)
    elif cmd == "KEY":
        action(f"--key {arg}")

    else:
        print(f"Unknown command: {cmd}")

def main():
    """Read actions.txt and execute all commands"""
    if not os.path.exists(ACTIONS_FILE):
        print(f"ERROR: {ACTIONS_FILE} not found")
        sys.exit(1)

    with open(ACTIONS_FILE, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Delete actions.txt immediately after reading
    os.remove(ACTIONS_FILE)
    print(f"Deleted {ACTIONS_FILE}")

    print(f"Executing {len([l for l in lines if l.strip() and not l.startswith('#')])} commands...")

    for i, line in enumerate(lines, 1):
        if line.strip() and not line.startswith("#"):
            print(f"[{i}] {line.strip()}")
            execute_command(line)

    print("DONE")

if __name__ == "__main__":
    main()
