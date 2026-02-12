# showcase_screenshots.py
# Takes promotional screenshots using CameraPoints with ShowcaseLight

import subprocess
import time
import os
import sys
import json
from datetime import datetime

# Paths
SCREENSHOT_SCRIPT = "C:/claudeblox/scripts/screenshot_game.py"
RUN_LUA_SCRIPT = "C:/claudeblox/scripts/run_lua.py"
OUTPUT_DIR = "C:/claudeblox/screenshots/showcase"

def run_lua(code):
    """Execute Lua code via run_lua.py"""
    try:
        result = subprocess.run(
            ["python", RUN_LUA_SCRIPT, code],
            capture_output=True,
            text=True,
            timeout=15
        )
        return result.stdout.strip()
    except Exception as e:
        print(f"Lua error: {e}")
        return ""

def get_camera_points():
    """Get all CameraPoints from the game"""
    code = '''
local CS = game:GetService("CollectionService")
local points = CS:GetTagged("CameraPoint")
local result = {}
for _, point in ipairs(points) do
    local roomName = point:GetAttribute("RoomName") or point.Name
    local fov = point:GetAttribute("FieldOfView") or 70
    local lookAt = point:GetAttribute("LookAt")
    table.insert(result, {
        path = point:GetFullName(),
        name = roomName,
        fov = fov,
        position = {point.Position.X, point.Position.Y, point.Position.Z},
        hasLight = point:FindFirstChild("ShowcaseLight") ~= nil
    })
end
return game:GetService("HttpService"):JSONEncode(result)
'''
    result = run_lua(code)
    try:
        return json.loads(result)
    except:
        return []

def toggle_showcase_light(camera_path, enabled):
    """Toggle ShowcaseLight inside a CameraPoint"""
    code = f'''
local point = game
for _, part in ipairs(string.split("{camera_path}", ".")) do
    point = point:FindFirstChild(part)
    if not point then return "not found" end
end
local light = point:FindFirstChild("ShowcaseLight")
if light then
    light.Enabled = {str(enabled).lower()}
    return "ok"
else
    return "no light"
end
'''
    return run_lua(code)

def move_camera_to_point(camera_path):
    """Move camera to CameraPoint position and look direction"""
    code = f'''
local point = game
for _, part in ipairs(string.split("{camera_path}", ".")) do
    point = point:FindFirstChild(part)
    if not point then return "not found" end
end

local camera = workspace.CurrentCamera
local lookAt = point:GetAttribute("LookAt")
local fov = point:GetAttribute("FieldOfView") or 70

camera.FieldOfView = fov

if lookAt then
    camera.CFrame = CFrame.new(point.Position, lookAt)
else
    camera.CFrame = point.CFrame
end

return "ok"
'''
    return run_lua(code)

def screenshot(name):
    """Take screenshot"""
    filepath = f"{OUTPUT_DIR}/{name}.png"
    subprocess.run(["python", SCREENSHOT_SCRIPT, "--output", filepath], capture_output=True)
    return filepath

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Clear old screenshots
    for f in os.listdir(OUTPUT_DIR):
        if f.endswith('.png'):
            os.remove(os.path.join(OUTPUT_DIR, f))

    print("=== SHOWCASE PHOTOGRAPHER ===")
    print()

    # Get CameraPoints
    print("Finding CameraPoints...")
    points = get_camera_points()

    if not points:
        print("No CameraPoints found! World-builder must create them.")
        print("Falling back to simple screenshots...")
        # Fallback to simple mode
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        screenshot(f"fallback_{timestamp}")
        return

    print(f"Found {len(points)} CameraPoints")
    print()

    screenshots_taken = []
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    for i, point in enumerate(points, 1):
        name = point.get("name", f"point_{i}")
        path = point.get("path", "")
        has_light = point.get("hasLight", False)

        print(f"{i}. {name}...")

        # Move camera
        move_camera_to_point(path)
        time.sleep(0.3)

        # Enable ShowcaseLight
        if has_light:
            toggle_showcase_light(path, True)
            time.sleep(0.3)

        # Take screenshot
        safe_name = name.replace(" ", "_").replace("/", "_")
        filepath = screenshot(f"{safe_name}_{timestamp}")
        screenshots_taken.append(filepath)

        # Disable ShowcaseLight
        if has_light:
            toggle_showcase_light(path, False)

        time.sleep(0.2)

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

    return screenshots_taken

if __name__ == "__main__":
    main()
