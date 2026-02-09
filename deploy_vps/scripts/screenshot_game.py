"""
Take screenshot of Roblox Studio viewport only (cropped).

Usage:
    python screenshot_game.py --cycle 1          # Save to screenshots/cycle_001/001.png
    python screenshot_game.py --cycle 1          # Next call: 002.png, etc.
    python screenshot_game.py                    # Save to screenshots/game.png (one-off)
"""
import sys
import os
import time
import glob

try:
    import pyautogui
    import win32gui
except ImportError:
    print("ERROR: Missing dependencies. Run: pip install pyautogui pywin32 pillow")
    sys.exit(1)

SCREENSHOTS_DIR = r"C:\claudeblox\screenshots"


def find_roblox_window():
    """Find Roblox Studio window handle."""
    def callback(hwnd, windows):
        if win32gui.IsWindowVisible(hwnd):
            title = win32gui.GetWindowText(hwnd)
            if "Roblox Studio" in title:
                windows.append(hwnd)
        return True

    windows = []
    win32gui.EnumWindows(callback, windows)
    return windows[0] if windows else None


def get_viewport_region(hwnd):
    """Get the viewport region of Roblox Studio."""
    rect = win32gui.GetWindowRect(hwnd)
    left, top, right, bottom = rect
    width = right - left
    height = bottom - top

    # Approximate viewport region
    viewport_left = left + 60
    viewport_top = top + 130
    viewport_right = right - 300
    viewport_bottom = bottom - 30

    viewport_width = max(viewport_right - viewport_left, 400)
    viewport_height = max(viewport_bottom - viewport_top, 300)

    return (viewport_left, viewport_top, viewport_width, viewport_height)


def take_screenshot(cycle=None):
    """Take screenshot of Roblox Studio viewport."""
    hwnd = find_roblox_window()
    if not hwnd:
        print("ERROR: Roblox Studio window not found")
        return None

    try:
        win32gui.SetForegroundWindow(hwnd)
        time.sleep(0.3)
    except:
        pass

    region = get_viewport_region(hwnd)
    screenshot = pyautogui.screenshot(region=region)

    if cycle is not None:
        # Save to cycle folder
        cycle_folder = os.path.join(SCREENSHOTS_DIR, f"cycle_{cycle:03d}")
        os.makedirs(cycle_folder, exist_ok=True)

        # Find next number
        existing = glob.glob(os.path.join(cycle_folder, "*.png"))
        next_num = len(existing) + 1
        filepath = os.path.join(cycle_folder, f"{next_num:03d}.png")
    else:
        # One-off screenshot
        os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
        filepath = os.path.join(SCREENSHOTS_DIR, "game.png")

    screenshot.save(filepath)
    print(f"Saved: {filepath}")
    return filepath


def main():
    cycle = None

    if "--cycle" in sys.argv:
        idx = sys.argv.index("--cycle")
        if idx + 1 < len(sys.argv):
            cycle = int(sys.argv[idx + 1])

    result = take_screenshot(cycle=cycle)
    if not result:
        sys.exit(1)


if __name__ == "__main__":
    main()
