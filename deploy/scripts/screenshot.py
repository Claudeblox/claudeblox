"""
Screenshot Tool
===============
Takes a screenshot of the screen for computer-player agent.

Usage:
    python screenshot.py                    # Save to default location
    python screenshot.py --output path.png  # Save to specific path
    python screenshot.py --region 0,0,800,600  # Capture specific region
"""

import argparse
import sys
import os
from datetime import datetime

try:
    from PIL import ImageGrab, Image
except ImportError:
    print("Installing Pillow...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import ImageGrab, Image


DEFAULT_OUTPUT = "C:/claudeblox/screenshots/screen.png"


def take_screenshot(output_path: str = None, region: tuple = None) -> str:
    """
    Take a screenshot.

    Args:
        output_path: Where to save the screenshot
        region: (x1, y1, x2, y2) tuple for specific region

    Returns:
        Path to saved screenshot
    """
    output_path = output_path or DEFAULT_OUTPUT

    # Create directory if needed
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Take screenshot
    if region:
        screenshot = ImageGrab.grab(bbox=region)
    else:
        screenshot = ImageGrab.grab()

    # Save
    screenshot.save(output_path, "PNG")

    print(f"Screenshot saved: {output_path}")
    print(f"Size: {screenshot.size[0]}x{screenshot.size[1]}")

    return output_path


def take_screenshot_with_timestamp(base_path: str = None) -> str:
    """Take screenshot with timestamp in filename."""
    base_path = base_path or "C:/claudeblox/screenshots"
    os.makedirs(base_path, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = os.path.join(base_path, f"screen_{timestamp}.png")

    return take_screenshot(output_path)


def main():
    parser = argparse.ArgumentParser(description="Take a screenshot")
    parser.add_argument("--output", "-o", type=str, default=DEFAULT_OUTPUT,
                        help="Output file path")
    parser.add_argument("--region", "-r", type=str,
                        help="Region to capture: x1,y1,x2,y2")
    parser.add_argument("--timestamp", "-t", action="store_true",
                        help="Add timestamp to filename")

    args = parser.parse_args()

    region = None
    if args.region:
        try:
            coords = [int(x.strip()) for x in args.region.split(",")]
            if len(coords) == 4:
                region = tuple(coords)
            else:
                print("Region must be x1,y1,x2,y2")
                sys.exit(1)
        except ValueError:
            print("Invalid region format. Use: x1,y1,x2,y2")
            sys.exit(1)

    if args.timestamp:
        path = take_screenshot_with_timestamp(os.path.dirname(args.output))
    else:
        path = take_screenshot(args.output, region)

    # Return path for use by other scripts
    print(f"OUTPUT:{path}")


if __name__ == "__main__":
    main()
