"""
Save Game Script
================
Saves the current Roblox Studio place to C:/claudeblox/game.rbxl

Usage:
    python save_game.py

How it works:
    1. Focuses Roblox Studio window
    2. Sends Ctrl+Shift+S (Save As)
    3. Types the save path
    4. Presses Enter
"""

import sys
import time

try:
    import pyautogui
    import pygetwindow as gw
except ImportError:
    print("Installing dependencies...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyautogui", "pygetwindow"])
    import pyautogui
    import pygetwindow as gw

SAVE_PATH = r"C:\claudeblox\game.rbxl"

def focus_roblox_studio():
    """Find and focus Roblox Studio window."""
    windows = gw.getWindowsWithTitle("Roblox Studio")
    if windows:
        win = windows[0]
        win.activate()
        time.sleep(0.5)
        return True
    print("ERROR: Roblox Studio window not found")
    return False

def save_game():
    """Save the game to file."""
    print("Saving game...")

    # Focus Studio
    if not focus_roblox_studio():
        return False

    # Ctrl+Shift+S = Save As
    pyautogui.hotkey('ctrl', 'shift', 's')
    time.sleep(1)

    # Clear any existing path and type new one
    pyautogui.hotkey('ctrl', 'a')
    time.sleep(0.2)
    pyautogui.typewrite(SAVE_PATH, interval=0.02)
    time.sleep(0.3)

    # Press Enter to save
    pyautogui.press('enter')
    time.sleep(2)

    # Handle "overwrite?" dialog if it appears
    pyautogui.press('enter')
    time.sleep(1)

    print(f"Game saved to: {SAVE_PATH}")
    return True

if __name__ == "__main__":
    success = save_game()
    sys.exit(0 if success else 1)
