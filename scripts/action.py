"""
Action Tool
===========
Performs keyboard and mouse actions for computer-player agent.

Usage:
    python action.py --key w                      # Press W key
    python action.py --key space                  # Press Space
    python action.py --key f5                     # Press F5
    python action.py --click 500 300              # Click at position
    python action.py --move 500 300               # Move mouse to position
    python action.py --move-relative 0 -100       # Move mouse relative (camera look down)
    python action.py --move-relative 0 100        # Move mouse relative (camera look up)
    python action.py --type "hello"               # Type text
    python action.py --hold w --duration 1.5      # Hold key for duration
    python action.py --wait 2                     # Wait 2 seconds
"""

import argparse
import sys
import time

try:
    import pyautogui
except ImportError:
    print("Installing pyautogui...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyautogui"])
    import pyautogui

# Safety settings
pyautogui.FAILSAFE = True  # Move mouse to corner to abort
pyautogui.PAUSE = 0.1  # Small pause between actions


# Key name mappings
KEY_MAP = {
    "space": "space",
    "enter": "enter",
    "return": "return",
    "escape": "escape",
    "esc": "escape",
    "tab": "tab",
    "shift": "shift",
    "ctrl": "ctrl",
    "control": "ctrl",
    "alt": "alt",
    "backspace": "backspace",
    "delete": "delete",
    "up": "up",
    "down": "down",
    "left": "left",
    "right": "right",
    "f1": "f1",
    "f2": "f2",
    "f3": "f3",
    "f4": "f4",
    "f5": "f5",
    "f6": "f6",
    "f7": "f7",
    "f8": "f8",
    "f9": "f9",
    "f10": "f10",
    "f11": "f11",
    "f12": "f12",
}


def press_key(key: str):
    """Press a single key."""
    key = key.lower()
    mapped_key = KEY_MAP.get(key, key)

    pyautogui.press(mapped_key)
    print(f"Pressed: {key}")


def hold_key(key: str, duration: float):
    """Hold a key for specified duration."""
    key = key.lower()
    mapped_key = KEY_MAP.get(key, key)

    pyautogui.keyDown(mapped_key)
    time.sleep(duration)
    pyautogui.keyUp(mapped_key)
    print(f"Held {key} for {duration}s")


def press_combo(*keys):
    """Press a key combination (e.g., ctrl+c)."""
    mapped_keys = [KEY_MAP.get(k.lower(), k.lower()) for k in keys]
    pyautogui.hotkey(*mapped_keys)
    print(f"Pressed combo: {'+'.join(keys)}")


def click(x: int, y: int, button: str = "left", clicks: int = 1):
    """Click at position."""
    pyautogui.click(x, y, button=button, clicks=clicks)
    print(f"Clicked at ({x}, {y}) with {button} button")


def move_mouse(x: int, y: int):
    """Move mouse to position."""
    pyautogui.moveTo(x, y)
    print(f"Moved mouse to ({x}, {y})")


def move_mouse_relative(dx: int, dy: int):
    """Move mouse relative to current position (for camera control)."""
    pyautogui.moveRel(dx, dy)
    print(f"Moved mouse by ({dx}, {dy})")


def drag(x1: int, y1: int, x2: int, y2: int, duration: float = 0.5):
    """Drag from one position to another."""
    pyautogui.moveTo(x1, y1)
    pyautogui.drag(x2 - x1, y2 - y1, duration=duration)
    print(f"Dragged from ({x1}, {y1}) to ({x2}, {y2})")


def type_text(text: str, interval: float = 0.05):
    """Type text."""
    pyautogui.typewrite(text, interval=interval)
    print(f"Typed: {text}")


def scroll(amount: int, x: int = None, y: int = None):
    """Scroll wheel."""
    if x is not None and y is not None:
        pyautogui.scroll(amount, x, y)
    else:
        pyautogui.scroll(amount)
    print(f"Scrolled: {amount}")


def wait(seconds: float):
    """Wait for specified seconds."""
    time.sleep(seconds)
    print(f"Waited {seconds}s")


def get_mouse_position() -> tuple:
    """Get current mouse position."""
    pos = pyautogui.position()
    print(f"Mouse position: ({pos.x}, {pos.y})")
    return (pos.x, pos.y)


def get_screen_size() -> tuple:
    """Get screen size."""
    size = pyautogui.size()
    print(f"Screen size: {size.width}x{size.height}")
    return (size.width, size.height)


def main():
    parser = argparse.ArgumentParser(description="Perform keyboard/mouse actions")

    # Key actions
    parser.add_argument("--key", "-k", type=str, help="Press a key")
    parser.add_argument("--hold", type=str, help="Key to hold")
    parser.add_argument("--duration", type=float, default=0.5, help="Duration for hold")
    parser.add_argument("--combo", type=str, help="Key combo (e.g., 'ctrl+c')")
    parser.add_argument("--type", "-t", type=str, help="Text to type")

    # Mouse actions
    parser.add_argument("--click", "-c", nargs=2, type=int, metavar=("X", "Y"),
                        help="Click at position")
    parser.add_argument("--rightclick", nargs=2, type=int, metavar=("X", "Y"),
                        help="Right click at position")
    parser.add_argument("--doubleclick", nargs=2, type=int, metavar=("X", "Y"),
                        help="Double click at position")
    parser.add_argument("--move", "-m", nargs=2, type=int, metavar=("X", "Y"),
                        help="Move mouse to position")
    parser.add_argument("--move-relative", nargs=2, type=int, metavar=("DX", "DY"),
                        help="Move mouse relative to current position (for camera control)")
    parser.add_argument("--drag", nargs=4, type=int, metavar=("X1", "Y1", "X2", "Y2"),
                        help="Drag from (x1,y1) to (x2,y2)")
    parser.add_argument("--scroll", type=int, help="Scroll amount")

    # Utility
    parser.add_argument("--wait", "-w", type=float, help="Wait seconds")
    parser.add_argument("--position", "-p", action="store_true",
                        help="Get current mouse position")
    parser.add_argument("--screensize", "-s", action="store_true",
                        help="Get screen size")

    args = parser.parse_args()

    # Execute action
    if args.key:
        press_key(args.key)
    elif args.hold:
        hold_key(args.hold, args.duration)
    elif args.combo:
        keys = args.combo.split("+")
        press_combo(*keys)
    elif args.type:
        type_text(args.type)
    elif args.click:
        click(args.click[0], args.click[1])
    elif args.rightclick:
        click(args.rightclick[0], args.rightclick[1], button="right")
    elif args.doubleclick:
        click(args.doubleclick[0], args.doubleclick[1], clicks=2)
    elif args.move:
        move_mouse(args.move[0], args.move[1])
    elif getattr(args, 'move_relative', None):
        move_mouse_relative(args.move_relative[0], args.move_relative[1])
    elif args.drag:
        drag(*args.drag)
    elif args.scroll is not None:
        scroll(args.scroll)
    elif args.wait:
        wait(args.wait)
    elif args.position:
        get_mouse_position()
    elif args.screensize:
        get_screen_size()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
