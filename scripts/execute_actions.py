# execute_actions.py
# Reads simple commands from actions.txt and executes them
# LLM writes commands, this script runs them
#
# Uses SendInput (hardware-level) for keyboard simulation

import subprocess
import time
import sys
import os
import ctypes
import json
from ctypes import wintypes

try:
    import pyautogui
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyautogui"])
    import pyautogui

try:
    import win32gui
    import win32con
    import win32api
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pywin32"])
    import win32gui
    import win32con
    import win32api

try:
    import requests
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests"])
    import requests

ACTIONS_FILE = "C:/claudeblox/actions.txt"
ACTIONS_PROCESSING_FILE = "C:/claudeblox/actions.txt.processing"
ACTION_SCRIPT = "C:/claudeblox/scripts/action.py"
SCREENSHOT_SCRIPT = "C:/claudeblox/scripts/screenshot_game.py"
THOUGHT_SCRIPT = "C:/claudeblox/scripts/write_thought.py"
ROBLOX_CMD_SCRIPT = "C:/claudeblox/scripts/roblox_command.py"
DIAG_OUTPUT = "C:/claudeblox/diag_output.txt"
BRIDGE_URL = "http://localhost:8585"
COMMAND_FILE = "C:/claudeblox/agent_command.txt"

# ============================================================
# SendInput structures for hardware-level keyboard simulation
# FIXED: Proper 64-bit Windows structure definitions
# ============================================================
INPUT_KEYBOARD = 1
INPUT_MOUSE = 0
KEYEVENTF_SCANCODE = 0x0008
KEYEVENTF_KEYUP = 0x0002

# Use ULONG_PTR for 64-bit compatibility
ULONG_PTR = ctypes.POINTER(ctypes.c_ulong)

class MOUSEINPUT(ctypes.Structure):
    _fields_ = [
        ("dx", ctypes.c_long),
        ("dy", ctypes.c_long),
        ("mouseData", wintypes.DWORD),
        ("dwFlags", wintypes.DWORD),
        ("time", wintypes.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]

class KEYBDINPUT(ctypes.Structure):
    _fields_ = [
        ("wVk", wintypes.WORD),
        ("wScan", wintypes.WORD),
        ("dwFlags", wintypes.DWORD),
        ("time", wintypes.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]

class HARDWAREINPUT(ctypes.Structure):
    _fields_ = [
        ("uMsg", wintypes.DWORD),
        ("wParamL", wintypes.WORD),
        ("wParamH", wintypes.WORD),
    ]

class _INPUT_UNION(ctypes.Union):
    _fields_ = [
        ("mi", MOUSEINPUT),
        ("ki", KEYBDINPUT),
        ("hi", HARDWAREINPUT),
    ]

class INPUT(ctypes.Structure):
    _fields_ = [
        ("type", wintypes.DWORD),
        ("_input", _INPUT_UNION),
    ]

# Scan codes for common keys (hardware scan codes)
SCAN_CODES = {
    'w': 0x11, 'a': 0x1E, 's': 0x1F, 'd': 0x20,
    'e': 0x12, 'f': 0x21, 'q': 0x10, 'r': 0x13,
    '1': 0x02, '2': 0x03, '3': 0x04,
    'up': 0x48, 'down': 0x50, 'left': 0x4B, 'right': 0x4D,
    '[': 0x1A, ']': 0x1B,
    'space': 0x39, 'escape': 0x01, 'enter': 0x1C,
    'shift': 0x2A, 'lshift': 0x2A,
    'ctrl': 0x1D,
    'tab': 0x0F,
}

def send_input_key_down(scan_code):
    """Send hardware-level key down using SendInput with scan code"""
    inp = INPUT()
    inp.type = INPUT_KEYBOARD
    inp._input.ki.wVk = 0
    inp._input.ki.wScan = scan_code
    inp._input.ki.dwFlags = KEYEVENTF_SCANCODE
    inp._input.ki.time = 0
    inp._input.ki.dwExtraInfo = None
    result = ctypes.windll.user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))
    return result

def send_input_key_up(scan_code):
    """Send hardware-level key up using SendInput with scan code"""
    inp = INPUT()
    inp.type = INPUT_KEYBOARD
    inp._input.ki.wVk = 0
    inp._input.ki.wScan = scan_code
    inp._input.ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP
    inp._input.ki.time = 0
    inp._input.ki.dwExtraInfo = None
    result = ctypes.windll.user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))
    return result

def send_input_press(key, duration=0.05):
    """Press a key using SendInput (hardware-level)"""
    sc = SCAN_CODES.get(key)
    if sc is None:
        print(f"WARNING: No scan code for key '{key}'")
        return 0, 0
    r1 = send_input_key_down(sc)
    time.sleep(duration)
    r2 = send_input_key_up(sc)
    time.sleep(0.02)
    return r1, r2

def send_input_hold(key, duration):
    """Hold a key using SendInput (hardware-level)"""
    sc = SCAN_CODES.get(key)
    if sc is None:
        print(f"WARNING: No scan code for key '{key}'")
        return 0, 0
    r1 = send_input_key_down(sc)
    time.sleep(duration)
    r2 = send_input_key_up(sc)
    time.sleep(0.05)
    return r1, r2

# ============================================================
# Helper functions
# ============================================================

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

def find_roblox_window():
    """Find Roblox Studio window handle"""
    windows = []
    def callback(hwnd, _):
        if win32gui.IsWindowVisible(hwnd):
            title = win32gui.GetWindowText(hwnd)
            if "Roblox Studio" in title:
                windows.append(hwnd)
        return True
    win32gui.EnumWindows(callback, windows)
    return windows[0] if windows else None

def focus_roblox():
    """Bring Roblox Studio to foreground and ensure it has focus"""
    hwnd = find_roblox_window()
    if not hwnd:
        print("WARNING: Roblox Studio window not found")
        return None
    try:
        win32gui.SetForegroundWindow(hwnd)
    except:
        try:
            win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
            time.sleep(0.1)
            win32gui.SetForegroundWindow(hwnd)
        except:
            pass
    time.sleep(0.15)
    return hwnd

def click_viewport():
    """Click the Roblox Studio viewport to ensure it has keyboard focus"""
    try:
        hwnd = find_roblox_window()
        if not hwnd:
            print("WARNING: Roblox Studio window not found for click")
            return
        try:
            win32gui.SetForegroundWindow(hwnd)
        except:
            pass
        time.sleep(0.1)
        rect = win32gui.GetWindowRect(hwnd)
        left, top, right, bottom = rect
        viewport_left = left + 60
        viewport_top = top + 130
        viewport_right = right - 300
        viewport_bottom = bottom - 30
        cx = (viewport_left + viewport_right) // 2
        cy = (viewport_top + viewport_bottom) // 2
        pyautogui.click(cx, cy)
        print(f"Clicked viewport at ({cx}, {cy})")
        time.sleep(0.2)
    except Exception as e:
        print(f"click_viewport error: {e}")

def click_command_bar():
    """Click the Roblox Studio command bar at the bottom"""
    try:
        hwnd = find_roblox_window()
        if not hwnd:
            print("WARNING: Roblox Studio window not found")
            return False
        try:
            win32gui.SetForegroundWindow(hwnd)
        except:
            pass
        time.sleep(0.15)
        rect = win32gui.GetWindowRect(hwnd)
        left, top, right, bottom = rect
        cmd_x = (left + right) // 2
        cmd_y = bottom - 290
        pyautogui.click(cmd_x, cmd_y)
        print(f"Clicked command bar at ({cmd_x}, {cmd_y})")
        time.sleep(0.3)
        return True
    except Exception as e:
        print(f"click_command_bar error: {e}")
        return False

def execute_lua_in_command_bar(lua_code):
    """Type and execute Lua code in Roblox Studio command bar"""
    if not click_command_bar():
        print("ERROR: Could not click command bar")
        return False

    # Clear existing text
    pyautogui.hotkey('ctrl', 'a')
    time.sleep(0.1)
    pyautogui.press('delete')
    time.sleep(0.1)

    # Type the Lua code using clipboard
    try:
        import pyperclip
        pyperclip.copy(lua_code)
        pyautogui.hotkey('ctrl', 'v')
    except ImportError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pyperclip"])
        import pyperclip
        pyperclip.copy(lua_code)
        pyautogui.hotkey('ctrl', 'v')

    time.sleep(0.3)

    # Execute with Enter
    pyautogui.press('enter')
    time.sleep(0.5)

    print(f"Executed Lua: {lua_code[:80]}...")
    return True

def click_viewport_no_cursor_move():
    """Give keyboard focus to the game viewport WITHOUT moving the mouse cursor.
    Uses Win32 PostMessage to simulate a click at the viewport center.
    Moving the cursor in first-person Roblox rotates the camera — so we never do that
    unless we explicitly want to turn (turn_character uses moveRel intentionally).
    """
    hwnd = find_roblox_window()
    if not hwnd:
        return
    try:
        win32gui.SetForegroundWindow(hwnd)
    except Exception:
        pass
    time.sleep(0.1)
    rect = win32gui.GetWindowRect(hwnd)
    left, top, right, bottom = rect
    # Approximate client-space viewport center
    cx_client = ((right - left) - 300 + 60) // 2
    cy_client = ((bottom - top) - 30 + 130) // 2
    lparam = win32api.MAKELONG(cx_client, cy_client)
    win32gui.PostMessage(hwnd, win32con.WM_LBUTTONDOWN, win32con.MK_LBUTTON, lparam)
    time.sleep(0.05)
    win32gui.PostMessage(hwnd, win32con.WM_LBUTTONUP, 0, lparam)
    time.sleep(0.1)


def restore_game_focus():
    """Restore keyboard focus after command bar use — no cursor movement, no ESC."""
    time.sleep(0.4)
    click_viewport_no_cursor_move()
    time.sleep(0.25)
    click_viewport_no_cursor_move()
    time.sleep(0.15)


def move_character(key, studs):
    """Move character using SendInput hardware-level key hold."""
    hwnd = focus_roblox()
    if not hwnd:
        print("WARNING: Cannot move - Roblox not found")
        return
    # Use actual pyautogui.click to give keyboard focus to game viewport.
    # PostMessage (click_viewport_no_cursor_move) does not properly focus child windows.
    # Moving to viewport center first avoids large camera rotation on click.
    click_viewport()
    time.sleep(0.2)
    duration = studs / 16.0 + 0.15
    print(f"Moving '{key}' for {duration:.2f}s (~{studs} studs) via SendInput")
    r1, r2 = send_input_hold(key, duration)
    print(f"  SendInput results: down={r1}, up={r2}")
    time.sleep(0.2)

def turn_character(direction, degrees):
    """Turn character by holding RIGHT mouse button and dragging horizontally.

    In Roblox Studio F5 mode the cursor is NOT captured by default, so plain
    mouse moves don't rotate the camera. Right-click + drag IS the Studio camera
    rotate gesture and works regardless of cursor-lock state.
    """
    hwnd = focus_roblox()
    if not hwnd:
        print("WARNING: Cannot turn - Roblox not found")
        return

    # Pixels per degree — empirically calibrated (was 3, but produced ~2x expected rotation)
    PIXELS_PER_DEGREE = 1.5
    dx = int(degrees * PIXELS_PER_DEGREE)
    if direction == 'left':
        dx = -dx

    # Get viewport center for a consistent start point
    rect = win32gui.GetWindowRect(hwnd)
    left, top, right, bottom = rect
    viewport_left = left + 60
    viewport_top  = top + 130
    viewport_right = right - 300
    viewport_bottom = bottom - 30
    cx = (viewport_left + viewport_right) // 2
    cy = (viewport_top + viewport_bottom) // 2

    # Move cursor to viewport center (safe — we'll RMB drag, not free-look)
    pyautogui.moveTo(cx, cy)
    time.sleep(0.15)

    # Hold RIGHT mouse button while dragging — this is the Studio camera rotate gesture
    move_duration = max(0.25, abs(degrees) / 180.0)
    pyautogui.mouseDown(button='right')
    time.sleep(0.05)
    pyautogui.moveRel(dx, 0, duration=move_duration)
    time.sleep(0.05)
    pyautogui.mouseUp(button='right')
    time.sleep(0.2)

    # Return cursor to viewport center so next command starts from known position
    pyautogui.moveTo(cx, cy)
    time.sleep(0.1)

    print(f"Turn '{direction}' {degrees}° via RMB drag ({dx}px, {move_duration:.2f}s)")


STATE_FILE = r"C:\claudeblox\game_state.json"

def read_current_rotation():
    """Read current playerRotation from game_state.json"""
    try:
        with open(STATE_FILE, 'r') as f:
            data = json.load(f)
        return data.get('playerRotation', None)
    except Exception:
        return None


def normalize_angle(angle):
    """Normalize angle to -180..180 range"""
    while angle > 180:
        angle -= 360
    while angle < -180:
        angle += 360
    return angle


def turn_to_angle(target_rotation):
    """Turn to face a specific rotation using feedback loop.
    Reads actual rotation from game_state.json after each small turn.
    Much more reliable than blind pixel-based turning.
    """
    MAX_ATTEMPTS = 10
    TOLERANCE = 20  # degrees — close enough

    for attempt in range(MAX_ATTEMPTS):
        current = read_current_rotation()
        if current is None:
            print(f"TURN_TO: can't read rotation, waiting...")
            time.sleep(1.5)
            continue

        delta = normalize_angle(target_rotation - current)
        print(f"TURN_TO: target={target_rotation}° current={current}° delta={delta}°")

        if abs(delta) <= TOLERANCE:
            print(f"TURN_TO: close enough! target={target_rotation}° actual={current}°")
            return True

        # Turn by the needed amount (cap at 60° per step for reliability)
        step = min(abs(delta), 60)
        direction = 'right' if delta > 0 else 'left'
        turn_character(direction, step)

        # Wait for game state to update (bridge updates every ~1s)
        time.sleep(1.5)

    print(f"TURN_TO: gave up after {MAX_ATTEMPTS} attempts")
    return False


def run_diagnostic():
    """Run window diagnostic and save results to file"""
    lines = []
    lines.append("=== ROBLOX STUDIO DIAGNOSTIC ===")
    lines.append(f"Time: {time.strftime('%H:%M:%S')}")
    lines.append(f"INPUT struct size: {ctypes.sizeof(INPUT)} bytes")
    lines.append(f"KEYBDINPUT size: {ctypes.sizeof(KEYBDINPUT)} bytes")
    lines.append(f"MOUSEINPUT size: {ctypes.sizeof(MOUSEINPUT)} bytes")
    lines.append(f"Union size: {ctypes.sizeof(_INPUT_UNION)} bytes")
    lines.append("")

    # Find Roblox windows
    windows = []
    def callback(hwnd, _):
        if win32gui.IsWindowVisible(hwnd):
            title = win32gui.GetWindowText(hwnd)
            if "Roblox" in title or "Studio" in title:
                windows.append((hwnd, title))
        return True
    win32gui.EnumWindows(callback, None)

    lines.append(f"Found {len(windows)} Roblox windows:")
    for hwnd, title in windows:
        rect = win32gui.GetWindowRect(hwnd)
        lines.append(f"  HWND: {hwnd}, Title: {title}")
        lines.append(f"  Rect: {rect}, Size: {rect[2]-rect[0]}x{rect[3]-rect[1]}")
        lines.append("")

    # Focus info
    fg = win32gui.GetForegroundWindow()
    lines.append(f"Foreground: '{win32gui.GetWindowText(fg)}' (HWND: {fg})")

    # SendInput test
    if windows:
        hwnd = windows[0][0]
        win32gui.SetForegroundWindow(hwnd)
        time.sleep(0.3)

        lines.append(f"\nSendInput test (W key):")
        r1 = send_input_key_down(SCAN_CODES['w'])
        time.sleep(0.05)
        r2 = send_input_key_up(SCAN_CODES['w'])
        lines.append(f"  Down: {r1}, Up: {r2} (1=success, 0=fail)")
        err = ctypes.windll.kernel32.GetLastError()
        lines.append(f"  GetLastError: {err}")

    # Full screenshot
    try:
        full_ss = pyautogui.screenshot()
        full_ss.save("C:/claudeblox/screenshots/fullscreen.png")
        lines.append("\nFull screenshot saved")
    except Exception as e:
        lines.append(f"\nScreenshot error: {e}")

    lines.append("\n=== DONE ===")
    output = "\n".join(lines)
    with open(DIAG_OUTPUT, 'w', encoding='utf-8') as f:
        f.write(output)
    print(output)


def send_lua_command(cmd, timeout_seconds=15):
    """Send command to AgentControl via bridge, wait for result.

    Pipeline: execute_actions → bridge /command → GameStateBridge (polls bridge)
    → player:SetAttribute → AgentControl → humanoid:MoveTo → result back
    """
    print(f"[AGENT_CMD] Sending: {cmd}")

    try:
        # Clear any stale result first
        try:
            requests.post(f"{BRIDGE_URL}/result", json={}, timeout=1)
        except Exception:
            pass

        # Write command to file for bridge to read
        with open(COMMAND_FILE, "w") as f:
            f.write(cmd)

        # Also send via HTTP POST (redundant with file, but faster)
        try:
            requests.post(f"{BRIDGE_URL}/command", json={"command": cmd}, timeout=2)
            print(f"[AGENT_CMD] HTTP POST succeeded")
        except Exception as e:
            print(f"[AGENT_CMD] HTTP POST failed ({e}), relying on file")

        # Poll for result
        polls = int(timeout_seconds / 0.5)
        for attempt in range(polls):
            time.sleep(0.5)

            try:
                resp = requests.get(f"{BRIDGE_URL}/result", timeout=2)
                if resp.status_code == 200:
                    result = resp.json()
                    if result and result.get("command"):
                        # Check if this result matches our command
                        if result.get("command") == cmd:
                            # Clear result
                            try:
                                requests.post(f"{BRIDGE_URL}/result", json={}, timeout=1)
                            except Exception:
                                pass
                            print(f"[AGENT_CMD] Result: {json.dumps(result)[:100]}")
                            return result
            except Exception:
                pass

            # Progress indicator every 5 polls
            if (attempt + 1) % 10 == 0:
                print(f"[AGENT_CMD] Waiting... ({(attempt+1)*0.5:.0f}s/{timeout_seconds}s)")

        print(f"[AGENT_CMD] Timeout after {timeout_seconds}s waiting for result")
        return {"success": False, "error": "timeout", "command": cmd}

    except Exception as e:
        print(f"[AGENT_CMD] Error: {e}")
        return {"success": False, "error": str(e), "command": cmd}


def execute_command(line):
    """Parse and execute one command"""
    line = line.strip()
    if not line or line.startswith("#"):
        return

    parts = line.split(maxsplit=1)
    cmd = parts[0].upper()
    arg = parts[1] if len(parts) > 1 else ""

    if cmd == "DIAG":
        run_diagnostic()

    elif cmd == "PYRUN":
        script_path = arg.strip('"\'')
        result = subprocess.run(
            [sys.executable, script_path],
            capture_output=True, text=True, timeout=30
        )
        print(f"PYRUN stdout: {result.stdout[-200:]}")
        if result.stderr:
            print(f"PYRUN stderr: {result.stderr[-200:]}")

    elif cmd == "MOVETO":
        print("MOVETO disabled — no teleporting. Use FORWARD/TURN for navigation.")

    elif cmd == "LUA":
        lua_code = arg.strip('"\'')
        execute_lua_in_command_bar(lua_code)
        time.sleep(0.5)
        restore_game_focus()

    elif cmd == "FORWARD":
        studs = int(arg) if arg else 1
        move_character('w', studs)

    elif cmd == "BACK":
        studs = int(arg) if arg else 1
        move_character('s', studs)

    elif cmd == "LEFT":
        studs = int(arg) if arg else 1
        move_character('a', studs)

    elif cmd == "RIGHT":
        studs = int(arg) if arg else 1
        move_character('d', studs)

    elif cmd == "TURN_LEFT":
        degrees = int(arg) if arg else 15
        if degrees < 1:
            degrees = 15
        turn_character('left', degrees)

    elif cmd == "TURN_RIGHT":
        degrees = int(arg) if arg else 15
        if degrees < 1:
            degrees = 15
        turn_character('right', degrees)

    elif cmd == "TURN_AROUND":
        # Use feedback-controlled turn for reliability
        current = read_current_rotation()
        if current is not None:
            target = normalize_angle(current + 180)
            turn_to_angle(target)
        else:
            # Fallback: two 90-degree turns
            turn_character('left', 90)
            time.sleep(0.15)
            turn_character('left', 90)

    elif cmd == "TURN_TO":
        # Turn to absolute compass angle: TURN_TO 90 (face east), TURN_TO 0 (face north)
        target = float(arg) if arg else 0
        turn_to_angle(target)

    elif cmd == "FACE":
        # Face a compass direction: FACE NORTH, FACE EAST, FACE SOUTH, FACE WEST
        # Or a specific angle: FACE 90
        directions = {"NORTH": 0, "EAST": 90, "SOUTH": 180, "WEST": -90,
                      "N": 0, "E": 90, "S": 180, "W": -90,
                      "NE": 45, "SE": 135, "SW": -135, "NW": -45}
        target = directions.get(arg.upper().strip(), None) if arg else None
        if target is None:
            try:
                target = float(arg)
            except (ValueError, TypeError):
                target = 0
                print(f"FACE: unknown direction '{arg}', defaulting to NORTH (0°)")
        turn_to_angle(target)

    elif cmd == "INTERACT":
        focus_roblox()
        click_viewport_no_cursor_move()
        time.sleep(0.2)
        send_input_press('e', 0.1)
        time.sleep(0.1)
        send_input_hold('e', 0.3)
        print("Interact via SendInput")

    elif cmd == "FLASHLIGHT":
        # Use bridge-based flashlight (keyboard F key unreliable in Studio F5)
        result = send_lua_command("FLASHLIGHT")
        if result.get("success"):
            print("Flashlight enabled via bridge")
        else:
            print(f"Flashlight bridge failed ({result.get('error')}), trying keyboard fallback")
            focus_roblox()
            click_viewport()
            time.sleep(0.2)
            send_input_press('f', 0.1)

    elif cmd == "JUMP":
        focus_roblox()
        click_viewport_no_cursor_move()
        time.sleep(0.1)
        send_input_press('space', 0.1)
        time.sleep(0.1)

    elif cmd == "SPRINT_ON":
        send_input_hold('shift', 0.1)

    elif cmd == "SPRINT_FORWARD":
        studs = int(arg) if arg else 5
        focus_roblox()
        click_viewport_no_cursor_move()
        time.sleep(0.1)
        duration = studs / 24.0 + 0.15
        send_input_key_down(SCAN_CODES['shift'])
        time.sleep(0.05)
        send_input_key_down(SCAN_CODES['w'])
        time.sleep(duration)
        send_input_key_up(SCAN_CODES['w'])
        send_input_key_up(SCAN_CODES['shift'])
        time.sleep(0.1)
        print(f"Sprint forward ~{studs} studs")

    elif cmd == "WAIT":
        seconds = float(arg) if arg else 1
        time.sleep(seconds)

    elif cmd == "SCREENSHOT":
        name = arg if arg else "shot"
        screenshot(name)

    elif cmd == "THOUGHT":
        text = arg.strip('"\'')
        thought(text)
        time.sleep(0.8)

    elif cmd == "CAMERA_LEVEL":
        # Reset camera pitch to eye level (horizontal) — zeros out the Y component of the look vector
        lua_code = (
            "local c=workspace.CurrentCamera;"
            "local p=c.CFrame.Position;"
            "local l=c.CFrame.LookVector;"
            "local h=Vector3.new(l.X,0,l.Z);"
            "if h.Magnitude>0.01 then c.CFrame=CFrame.lookAt(p,p+h.Unit) end"
        )
        execute_lua_in_command_bar(lua_code)
        time.sleep(0.3)
        restore_game_focus()
        print("Camera leveled to eye level")

    elif cmd == "CLICK_VIEWPORT":
        click_viewport()
        print("Clicked viewport for focus")

    elif cmd == "CLICK":
        coords = arg.split()
        if len(coords) >= 2:
            x, y = int(coords[0]), int(coords[1])
            pyautogui.click(x, y)
            print(f"Clicked at ({x}, {y})")
            time.sleep(0.2)
        else:
            print("CLICK requires X Y coordinates")

    elif cmd == "PLAY":
        action("--key f5")
        time.sleep(3)

    elif cmd == "STOP":
        subprocess.run(f"python {ACTION_SCRIPT} --key shift+f5", shell=True)
        time.sleep(1)

    elif cmd == "KEY":
        key_name = arg.strip().lower()
        if key_name in SCAN_CODES:
            focus_roblox()
            send_input_press(key_name, 0.08)
        else:
            action(f"--key {arg}")

    elif cmd == "RUNCMD":
        lua_code = arg.strip('"\'')
        subprocess.run(f'python {ROBLOX_CMD_SCRIPT} "{lua_code}"', shell=True)
        time.sleep(1)
        restore_game_focus()
        print(f"RUNCMD: {lua_code[:60]}...")

    elif cmd in ("GO_TO", "WALK_TO", "GOTO", "WALKTO"):
        if not arg:
            print(f"{cmd} requires target (object name or 'x y z' coordinates)")
            return
        result = send_lua_command(f"GO_TO {arg}")
        if result.get("success"):
            dist = result.get("distance", "?")
            print(f"GO_TO {arg}: SUCCESS (final distance: {dist})")
        else:
            error = result.get("error", "unknown")
            dist = result.get("distance", "?")
            print(f"GO_TO {arg}: FAILED ({error}, distance: {dist})")

    elif cmd == "INTERACT_WITH":
        if not arg:
            print("INTERACT_WITH requires object name")
            return
        result = send_lua_command(f"INTERACT_WITH {arg}")
        if result.get("success"):
            method = result.get("method", "reached")
            print(f"INTERACT_WITH {arg}: SUCCESS ({method})")
        else:
            error = result.get("error", "unknown")
            print(f"INTERACT_WITH {arg}: FAILED ({error})")

    else:
        print(f"Unknown command: {cmd}")

def main():
    """Read actions file and execute all commands."""
    target_file = None
    if os.path.exists(ACTIONS_FILE):
        target_file = ACTIONS_FILE
    elif os.path.exists(ACTIONS_PROCESSING_FILE):
        target_file = ACTIONS_PROCESSING_FILE
    else:
        print(f"ERROR: Neither {ACTIONS_FILE} nor {ACTIONS_PROCESSING_FILE} found")
        sys.exit(1)

    print(f"Reading from: {target_file}")
    with open(target_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    if target_file == ACTIONS_FILE:
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
