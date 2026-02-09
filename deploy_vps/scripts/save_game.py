"""
Save/Publish Game Script
========================
Publishes the current Roblox Studio place to Roblox cloud.

Usage:
    python save_game.py

How it works:
    1. Focuses Roblox Studio window
    2. Sends Alt+P (Publish to Roblox)
    3. Waits for publish to complete

After publish, game is playable at: roblox.com/games/YOUR_GAME_ID
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

def publish_game():
    """Publish the game to Roblox."""
    print("Publishing game to Roblox...")

    # Focus Studio
    if not focus_roblox_studio():
        return False

    # Alt+P = Publish to Roblox
    pyautogui.hotkey('alt', 'p')
    time.sleep(3)

    # Press Enter to confirm (if dialog appears)
    pyautogui.press('enter')
    time.sleep(5)

    print("Game published to Roblox!")
    print("Players can now join at: roblox.com/games/YOUR_GAME_ID")
    return True

if __name__ == "__main__":
    success = publish_game()
    sys.exit(0 if success else 1)
