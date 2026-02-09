#!/usr/bin/env python3
"""
Auto-publish Roblox game via Open Cloud API.

Setup:
1. Go to https://create.roblox.com/credentials
2. Create API Key with "universe.place:write" permission
3. Fill in the values below
"""

import subprocess
import sys

# === FILL THESE IN ===
API_KEY = "YOUR_API_KEY_HERE"
UNIVERSE_ID = "YOUR_UNIVERSE_ID"  # From game URL or Creator Dashboard
PLACE_ID = "YOUR_PLACE_ID"        # From game URL
PLACE_FILE = r"C:\claudeblox\game.rbxl"  # Path to saved place file
# =====================

def publish():
    """Publish the game to Roblox."""

    if API_KEY == "YOUR_API_KEY_HERE":
        print("ERROR: Please fill in API_KEY, UNIVERSE_ID, PLACE_ID in publish.py")
        return False

    # Method 1: Using rblx-open-cloud CLI (if installed)
    # pip install rblx-open-cloud
    try:
        import rblxopencloud

        place = rblxopencloud.Place(PLACE_ID, api_key=API_KEY)

        with open(PLACE_FILE, "rb") as f:
            place.upload(f, publish=True)

        print(f"SUCCESS: Published to Roblox!")
        print(f"URL: https://www.roblox.com/games/{PLACE_ID}")
        return True

    except ImportError:
        print("rblxopencloud not installed. Install with: pip install rblx-open-cloud")
    except Exception as e:
        print(f"Error publishing: {e}")

    # Method 2: Using curl (fallback)
    try:
        import requests

        url = f"https://apis.roblox.com/universes/v1/{UNIVERSE_ID}/places/{PLACE_ID}/versions"

        headers = {
            "x-api-key": API_KEY,
            "Content-Type": "application/octet-stream"
        }

        params = {
            "versionType": "Published"
        }

        with open(PLACE_FILE, "rb") as f:
            response = requests.post(url, headers=headers, params=params, data=f.read())

        if response.status_code == 200:
            print(f"SUCCESS: Published to Roblox!")
            print(f"URL: https://www.roblox.com/games/{PLACE_ID}")
            return True
        else:
            print(f"Error: {response.status_code} - {response.text}")
            return False

    except Exception as e:
        print(f"Error publishing: {e}")
        return False

if __name__ == "__main__":
    success = publish()
    sys.exit(0 if success else 1)
