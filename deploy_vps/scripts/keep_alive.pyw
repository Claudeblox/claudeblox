"""
Keep Shadow PC alive - AGGRESSIVE version.
Moves mouse + presses Shift every minute.
Logs everything.
"""
import time
import os
from datetime import datetime

try:
    import pyautogui
except ImportError:
    os.system("pip install pyautogui")
    import pyautogui

pyautogui.FAILSAFE = False

LOG_FILE = r"C:\claudeblox\logs\keep_alive.log"
INTERVAL = 60  # Every 1 minute (aggressive)

def log(msg):
    try:
        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {msg}\n")
        # Keep log file small (last 1000 lines)
        with open(LOG_FILE, "r", encoding="utf-8") as f:
            lines = f.readlines()
        if len(lines) > 1000:
            with open(LOG_FILE, "w", encoding="utf-8") as f:
                f.writelines(lines[-500:])
    except:
        pass

def keep_alive():
    try:
        # Move mouse
        pyautogui.moveRel(2, 0)
        time.sleep(0.05)
        pyautogui.moveRel(-2, 0)
        time.sleep(0.05)

        # Press and release Shift (doesn't type anything)
        pyautogui.press('shift')

        return True
    except Exception as e:
        log(f"Error: {e}")
        return False

def main():
    log("=== KEEP ALIVE STARTED (aggressive mode, 1 min interval) ===")

    count = 0
    while True:
        try:
            count += 1
            success = keep_alive()
            if success:
                log(f"ping #{count}")
            time.sleep(INTERVAL)
        except Exception as e:
            log(f"Error in loop: {e}")
            time.sleep(30)

if __name__ == "__main__":
    main()
