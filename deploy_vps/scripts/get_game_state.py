"""
Get current game state from game_state.json.

Usage:
    python get_game_state.py          # Print full state
    python get_game_state.py position # Print just position
    python get_game_state.py nearby   # Print nearby objects
"""
import json
import sys
import os

STATE_FILE = r"C:\claudeblox\game_state.json"


def get_state():
    if not os.path.exists(STATE_FILE):
        return {"error": "No game state file. Is game_bridge.py running? Is game running?"}

    with open(STATE_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def main():
    state = get_state()

    if len(sys.argv) > 1:
        key = sys.argv[1]
        if key == "position":
            pos = state.get("playerPosition", "unknown")
            print(f"Position: {pos}")
        elif key == "nearby":
            nearby = state.get("nearbyObjects", [])
            print(f"Nearby objects: {nearby}")
        elif key == "room":
            room = state.get("currentRoom", "unknown")
            print(f"Current room: {room}")
        elif key == "health":
            health = state.get("health", "unknown")
            print(f"Health: {health}")
        else:
            print(json.dumps(state.get(key, f"Key '{key}' not found"), indent=2))
    else:
        print(json.dumps(state, indent=2))


if __name__ == "__main__":
    main()
