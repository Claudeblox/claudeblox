# showcase_screenshots.py
# Takes multiple promotional screenshots for Twitter
# Simplified version - just takes screenshots at different positions

import subprocess
import time
import os
import sys
from datetime import datetime

# Paths
SCREENSHOT_SCRIPT = "C:/claudeblox/scripts/screenshot_game.py"
ACTION_SCRIPT = "C:/claudeblox/scripts/action.py"
OUTPUT_DIR = "C:/claudeblox/screenshots/showcase"

def screenshot(name):
    """Take screenshot of game viewport"""
    filepath = f"{OUTPUT_DIR}/{name}.png"
    subprocess.run([
        "python", SCREENSHOT_SCRIPT,
        "--output", filepath
    ])
    return filepath

def action(cmd):
    """Run action.py with given arguments"""
    subprocess.run(f"python {ACTION_SCRIPT} {cmd}", shell=True)
    time.sleep(0.3)

def main():
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Clear old screenshots
    for f in os.listdir(OUTPUT_DIR):
        if f.endswith('.png'):
            os.remove(os.path.join(OUTPUT_DIR, f))

    print("=== SHOWCASE PHOTOGRAPHER ===")
    print()

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    screenshots_taken = []

    # Take screenshots from different angles
    shots = [
        ("overview", "Main view from spawn"),
        ("left", "Looking left"),
        ("right", "Looking right"),
        ("forward", "Looking forward into the level"),
    ]

    print("Taking showcase screenshots...")
    print()

    # Shot 1: Overview (current position)
    print("1. Taking overview shot...")
    filepath = screenshot(f"showcase_01_overview_{timestamp}")
    screenshots_taken.append(filepath)
    time.sleep(0.5)

    # Shot 2: Turn left 90 degrees
    print("2. Turning left, taking shot...")
    action("--move-relative -600 0")  # ~90 degrees left
    time.sleep(0.3)
    filepath = screenshot(f"showcase_02_left_{timestamp}")
    screenshots_taken.append(filepath)

    # Shot 3: Turn right 180 degrees (to face right from original)
    print("3. Turning right, taking shot...")
    action("--move-relative 1200 0")  # 180 degrees right
    time.sleep(0.3)
    filepath = screenshot(f"showcase_03_right_{timestamp}")
    screenshots_taken.append(filepath)

    # Shot 4: Turn back to center, move forward, take shot
    print("4. Moving forward, taking shot...")
    action("--move-relative -600 0")  # Back to center
    action("--key w --hold 1")  # Walk forward 1 second
    time.sleep(0.5)
    filepath = screenshot(f"showcase_04_forward_{timestamp}")
    screenshots_taken.append(filepath)

    print()
    print("=== SHOWCASE SCREENSHOTS COMPLETE ===")
    print()
    print(f"Screenshots taken: {len(screenshots_taken)}")
    print()
    print("Files:")
    for f in screenshots_taken:
        print(f"- {os.path.basename(f)}")
    print()
    print(f"Location: {OUTPUT_DIR}/")
    print()
    print("READY FOR TWITTER")

    # Return list of screenshots for use by other scripts
    return screenshots_taken

if __name__ == "__main__":
    main()
