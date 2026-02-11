# showcase_screenshots.py
# Takes promotional screenshots using CameraPoints with temporary lighting
# CameraPoints are created by world-builder with ShowcaseLight (disabled by default)

import subprocess
import json
import time
import os
import sys

# Paths
MCP_SCRIPT = "C:/claudeblox/scripts/run_lua.py"
SCREENSHOT_SCRIPT = "C:/claudeblox/scripts/screenshot_game.py"
OUTPUT_DIR = "C:/claudeblox/screenshots/showcase"

def run_lua(code):
    """Execute Lua code via MCP and return result"""
    result = subprocess.run(
        ["python", MCP_SCRIPT, code],
        capture_output=True,
        text=True
    )
    return result.stdout.strip()

def screenshot(name):
    """Take screenshot of game viewport"""
    subprocess.run([
        "python", SCREENSHOT_SCRIPT,
        "--output", f"{OUTPUT_DIR}/{name}.png"
    ])

def get_camera_points():
    """Get all CameraPoints from the game"""
    lua_code = '''
local CollectionService = game:GetService("CollectionService")
local cameraPoints = CollectionService:GetTagged("CameraPoint")
local result = {}

for _, cp in cameraPoints do
    local data = {
        path = cp:GetFullName(),
        name = cp.Name,
        position = {x = cp.Position.X, y = cp.Position.Y, z = cp.Position.Z},
        roomName = cp:GetAttribute("RoomName") or cp.Name:gsub("CameraPoint_", ""),
        fov = cp:GetAttribute("FieldOfView") or 70,
        type = cp:GetAttribute("Type") or "Room",
        hasLight = cp:FindFirstChild("ShowcaseLight") ~= nil
    }

    -- Get lookAt target (center of room or enemy position)
    local lookAt = cp:GetAttribute("LookAt")
    if lookAt then
        data.lookAt = {x = lookAt.X, y = lookAt.Y, z = lookAt.Z}
    else
        -- Default: look forward from camera position
        local cf = cp.CFrame
        local target = cf.Position + cf.LookVector * 10
        data.lookAt = {x = target.X, y = target.Y, z = target.Z}
    end

    table.insert(result, data)
end

return game:GetService("HttpService"):JSONEncode(result)
'''
    result = run_lua(lua_code)
    try:
        return json.loads(result)
    except:
        print(f"Failed to parse camera points: {result}")
        return []

def setup_camera(cp):
    """Move camera to CameraPoint position"""
    lua_code = f'''
local camera = workspace.CurrentCamera
local pos = Vector3.new({cp['position']['x']}, {cp['position']['y']}, {cp['position']['z']})
local lookAt = Vector3.new({cp['lookAt']['x']}, {cp['lookAt']['y']}, {cp['lookAt']['z']})

camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.lookAt(pos, lookAt)
camera.FieldOfView = {cp['fov']}

return "Camera set"
'''
    return run_lua(lua_code)

def toggle_showcase_light(cp_path, enabled):
    """Enable or disable ShowcaseLight in CameraPoint"""
    lua_code = f'''
local function findByPath(path)
    local parts = string.split(path, ".")
    local current = game
    for i = 2, #parts do
        current = current:FindFirstChild(parts[i])
        if not current then return nil end
    end
    return current
end

local cp = findByPath("{cp_path}")
if not cp then return "CameraPoint not found" end

local light = cp:FindFirstChild("ShowcaseLight")
if not light then return "ShowcaseLight not found" end

light.Enabled = {str(enabled).lower()}
return "Light " .. (light.Enabled and "ON" or "OFF")
'''
    return run_lua(lua_code)

def reset_camera():
    """Reset camera to follow player"""
    lua_code = '''
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Custom
return "Camera reset"
'''
    return run_lua(lua_code)

def main():
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("=== SHOWCASE PHOTOGRAPHER ===")
    print()

    # Get all CameraPoints
    camera_points = get_camera_points()

    if not camera_points:
        print("ERROR: No CameraPoints found!")
        print("Make sure world-builder created CameraPoints with tag 'CameraPoint'")
        sys.exit(1)

    print(f"Found {len(camera_points)} CameraPoints")
    print()

    screenshots_taken = []

    for cp in camera_points:
        name = cp['roomName'].replace(" ", "_")
        filename = f"{name}_showcase"

        print(f"Shooting: {cp['name']} ({cp['type']})")

        # 1. Move camera to position
        setup_camera(cp)
        time.sleep(0.2)

        # 2. Turn ON showcase light
        if cp['hasLight']:
            toggle_showcase_light(cp['path'], True)
            time.sleep(0.5)  # Wait for lighting to update
        else:
            print(f"  Warning: No ShowcaseLight in {cp['name']}")

        # 3. Take screenshot
        screenshot(filename)
        screenshots_taken.append(f"{filename}.png")

        # 4. Turn OFF showcase light
        if cp['hasLight']:
            toggle_showcase_light(cp['path'], False)
            time.sleep(0.1)

        print(f"  -> {filename}.png")

    # Reset camera
    reset_camera()

    print()
    print("=== SHOWCASE SCREENSHOTS COMPLETE ===")
    print()
    print(f"Screenshots taken: {len(screenshots_taken)}")
    print()
    print("Files:")
    for f in screenshots_taken:
        print(f"- {f}")
    print()
    print(f"Location: {OUTPUT_DIR}/")
    print()
    print("READY FOR TWITTER")

if __name__ == "__main__":
    main()
