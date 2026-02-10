"""
Keep Shadow PC alive - improved version with logging.
Moves mouse every 3 minutes and logs activity.
Runs without console window (.pyw extension).
"""
import time
import os
from datetime import datetime

try:
    import pyautogui
except ImportError:
    # If pyautogui not installed, try to install
    os.system("pip install pyautogui")
    import pyautogui

pyautogui.FAILSAFE = False

LOG_FILE = r"C:\claudeblox\logs\keep_alive.log"
INTERVAL = 180  # 3 minutes (more frequent than before)

def log(msg):
    """Write to log file."""
    try:
        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {msg}\n")
    except:
        pass

def keep_alive():
    """Move mouse slightly to prevent sleep."""
    try:
        pyautogui.moveRel(1, 0)
        time.sleep(0.1)
        pyautogui.moveRel(-1, 0)
        return True
    except Exception as e:
        log(f"Error moving mouse: {e}")
        return False

def main():
    log("keep_alive started")

    while True:
        try:
            success = keep_alive()
            if success:
                log("ping - mouse moved")
            time.sleep(INTERVAL)
        except Exception as e:
            log(f"Error in main loop: {e}")
            time.sleep(60)  # Wait 1 min on error, then retry

if __name__ == "__main__":
    main()
