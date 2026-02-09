"""
Keep Shadow PC alive by moving mouse slightly every 5 minutes.
This file has .pyw extension so it runs without a console window.
"""
import time
import pyautogui

pyautogui.FAILSAFE = False

while True:
    pyautogui.moveRel(1, 0)
    time.sleep(0.1)
    pyautogui.moveRel(-1, 0)
    time.sleep(300)  # 5 minutes
