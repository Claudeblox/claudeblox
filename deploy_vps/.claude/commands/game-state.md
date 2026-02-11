Read the file `C:/claudeblox/game_state.json` and display the current game state.

Format the output like this:

```
=== GAME STATE ===

PLAYER:
- Position: (x, y, z)
- Rotation: N°
- Health: H / MAX
- Room: [name]

FLASHLIGHT: [has: yes/no] [on: yes/no]

NEARBY OBJECTS:
[list top 10 by distance with name, distance, position, tags]
```

If file doesn't exist, say: "game_state.json not found. Is game_bridge.py running?"
