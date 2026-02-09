#!/usr/bin/env python3
"""
Auto-publish Roblox game via Open Cloud API.

Setup:
1. Go to https://create.roblox.com/credentials
2. Create API Key with "universe.place:write" permission
3. Create .env file in C:/claudeblox/ with the values
"""

import os
import sys
from pathlib import Path

# Load .env file
env_path = Path("C:/claudeblox/.env")
if env_path.exists():
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key.strip()] = value.strip()

# Configuration from environment
API_KEY = os.environ.get("ROBLOX_API_KEY", "")
UNIVERSE_ID = os.environ.get("ROBLOX_UNIVERSE_ID", "")
PLACE_ID = os.environ.get("ROBLOX_PLACE_ID", "")
PLACE_FILE = os.environ.get("ROBLOX_PLACE_FILE", r"C:\claudeblox\game.rbxl")


def publish():
    """Publish the game to Roblox."""

    # Check configuration
    if not API_KEY:
        print("ERROR: ROBLOX_API_KEY not set in .env file")
        print("Create C:/claudeblox/.env with:")
        print("  ROBLOX_API_KEY=your_api_key")
        print("  ROBLOX_UNIVERSE_ID=your_universe_id")
        print("  ROBLOX_PLACE_ID=your_place_id")
        return False

    if not UNIVERSE_ID or not PLACE_ID:
        print("ERROR: ROBLOX_UNIVERSE_ID or ROBLOX_PLACE_ID not set in .env file")
        return False

    if not os.path.exists(PLACE_FILE):
        print(f"ERROR: Place file not found: {PLACE_FILE}")
        print("Save your game in Roblox Studio first (File > Save)")
        return False

    print(f"Publishing {PLACE_FILE}...")
    print(f"Universe: {UNIVERSE_ID}, Place: {PLACE_ID}")

    # Method 1: Using rblx-open-cloud library (preferred)
    try:
        import rblxopencloud

        place = rblxopencloud.Place(int(PLACE_ID), api_key=API_KEY)

        with open(PLACE_FILE, "rb") as f:
            version = place.upload(f, publish=True)

        print(f"SUCCESS: Published to Roblox!")
        print(f"Version: {version}")
        print(f"URL: https://www.roblox.com/games/{UNIVERSE_ID}")
        return True

    except ImportError:
        print("rblxopencloud not installed, trying requests...")
    except Exception as e:
        print(f"rblxopencloud error: {e}")
        print("Trying requests method...")

    # Method 2: Using requests (fallback)
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
            data = response.json()
            print(f"SUCCESS: Published to Roblox!")
            print(f"Version: {data.get('versionNumber', 'unknown')}")
            print(f"URL: https://www.roblox.com/games/{UNIVERSE_ID}")
            return True
        else:
            print(f"ERROR: {response.status_code}")
            print(f"Response: {response.text}")
            return False

    except ImportError:
        print("ERROR: requests not installed. Install with: pip install requests")
        return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = publish()
    sys.exit(0 if success else 1)
