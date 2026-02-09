"""
Take screenshot of Roblox Studio viewport only (cropped).
Saves clean game screenshot without UI/toolbars.

Usage:
    python screenshot_game.py                    # Save to default location
    python screenshot_game.py --good             # Save as good screenshot for tweets
    python screenshot_game.py --output path.png  # Save to specific path
"""
import sys
import os
import time
from datetime import datetime

try:
    import pyautogui
    import win32gui
    import win32con
    from PIL import Image
except ImportError:
    print("ERROR: Missing dependencies. Run: pip install pyautogui pywin32 pillow")
    sys.exit(1)

SCREENSHOTS_DIR = r"C:\claudeblox\screenshots"
GOOD_SCREENSHOTS_DIR = r"C:\claudeblox\screenshots\good"


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
    """
    Get the viewport region of Roblox Studio.
    The viewport is roughly the center area, excluding toolbars and explorer.
    """
    rect = win32gui.GetWindowRect(hwnd)
    left, top, right, bottom = rect
    width = right - left
    height = bottom - top

    # Approximate viewport region (adjust these offsets as needed)
    # Left toolbar: ~60px, Top ribbon: ~130px, Right explorer: ~300px, Bottom: ~30px
    viewport_left = left + 60
    viewport_top = top + 130
    viewport_right = right - 300
    viewport_bottom = bottom - 30

    # Ensure minimum size
    viewport_width = max(viewport_right - viewport_left, 400)
    viewport_height = max(viewport_bottom - viewport_top, 300)

    return (viewport_left, viewport_top, viewport_width, viewport_height)


def take_game_screenshot(save_as_good=False, output_path=None):
    """Take screenshot of Roblox Studio viewport only."""
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

    # Find Roblox Studio window
    hwnd = find_roblox_window()
    if not hwnd:
        print("ERROR: Roblox Studio window not found")
        return None

    # Bring window to front
    try:
        win32gui.SetForegroundWindow(hwnd)
        time.sleep(0.3)  # Wait for window to be in front
    except Exception:
        pass  # Window might already be in front

    # Get viewport region
    region = get_viewport_region(hwnd)

    # Take screenshot of viewport only
    screenshot = pyautogui.screenshot(region=region)

    # Determine save path
    if output_path:
        filepath = output_path
    elif save_as_good:
        os.makedirs(GOOD_SCREENSHOTS_DIR, exist_ok=True)
        # Find next available number
        existing = [f for f in os.listdir(GOOD_SCREENSHOTS_DIR) if f.startswith("good_")]
        next_num = len(existing) + 1
        filepath = os.path.join(GOOD_SCREENSHOTS_DIR, f"good_{next_num}.png")
    else:
        filepath = os.path.join(SCREENSHOTS_DIR, "game.png")

    # Save
    screenshot.save(filepath)
    print(f"Screenshot saved: {filepath}")
    print(f"Size: {screenshot.width}x{screenshot.height}")

    return filepath


def main():
    save_as_good = "--good" in sys.argv
    output_path = None

    if "--output" in sys.argv:
        idx = sys.argv.index("--output")
        if idx + 1 < len(sys.argv):
            output_path = sys.argv[idx + 1]

    result = take_game_screenshot(save_as_good=save_as_good, output_path=output_path)

    if not result:
        sys.exit(1)


if __name__ == "__main__":
    main()
