"""
Window Manager - focus windows by name.

Usage:
    python window_manager.py --list                    # List all windows
    python window_manager.py --focus "Roblox Studio"   # Focus window containing "Roblox Studio"
    python window_manager.py --focus-studio            # Focus Roblox Studio
    python window_manager.py --focus-terminal          # Focus terminal/powershell
"""
import sys
import time

try:
    import win32gui
    import win32con
except ImportError:
    print("Installing pywin32...")
    import os
    os.system("pip install pywin32")
    import win32gui
    import win32con


def get_all_windows():
    """Get list of all visible windows with titles."""
    windows = []

    def callback(hwnd, results):
        if win32gui.IsWindowVisible(hwnd):
            title = win32gui.GetWindowText(hwnd)
            if title:  # Only windows with titles
                results.append({
                    "hwnd": hwnd,
                    "title": title
                })
        return True

    win32gui.EnumWindows(callback, windows)
    return windows


def find_window(search_text):
    """Find window by partial title match."""
    windows = get_all_windows()
    search_lower = search_text.lower()

    for w in windows:
        if search_lower in w["title"].lower():
            return w

    return None


def focus_window(hwnd):
    """Bring window to foreground."""
    try:
        # First try to restore if minimized
        if win32gui.IsIconic(hwnd):
            win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
            time.sleep(0.1)

        # Bring to foreground
        win32gui.SetForegroundWindow(hwnd)
        time.sleep(0.2)
        return True
    except Exception as e:
        print(f"Error focusing window: {e}")
        return False


def focus_by_name(name):
    """Focus window by partial name match."""
    window = find_window(name)
    if window:
        print(f"Found: {window['title']}")
        success = focus_window(window["hwnd"])
        if success:
            print(f"Focused: {window['title']}")
        return success
    else:
        print(f"Window not found: {name}")
        return False


def focus_roblox_studio():
    """Focus Roblox Studio window."""
    return focus_by_name("Roblox Studio")


def focus_terminal():
    """Focus PowerShell or Command Prompt."""
    # Try different terminal names
    for name in ["PowerShell", "cmd.exe", "Command Prompt", "Windows Terminal", "Claude"]:
        if focus_by_name(name):
            return True
    return False


def list_windows():
    """Print all visible windows."""
    windows = get_all_windows()
    print(f"Found {len(windows)} windows:\n")
    for i, w in enumerate(windows, 1):
        print(f"{i:3}. {w['title'][:80]}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return

    arg = sys.argv[1]

    if arg == "--list":
        list_windows()

    elif arg == "--focus" and len(sys.argv) > 2:
        name = " ".join(sys.argv[2:])
        focus_by_name(name)

    elif arg == "--focus-studio":
        focus_roblox_studio()

    elif arg == "--focus-terminal":
        focus_terminal()

    else:
        print(__doc__)


if __name__ == "__main__":
    main()
