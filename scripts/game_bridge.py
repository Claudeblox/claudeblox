"""
Game Bridge Server - receives game state from Roblox + tracks history + detects stuck

Enhanced version with:
- Position history (last 10 positions)
- Action history (last 10 action sets)
- Automatic stuck detection
- Cycle tracking
- Goal tracking

Usage:
    python game_bridge.py

Runs on http://localhost:8585
"""
import json
import os
import math
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime
from collections import deque

STATE_FILE = r"C:\claudeblox\game_state.json"
LOG_DIR = r"C:\claudeblox\logs"
CURRENT_LOG_FILE = r"C:\claudeblox\current_log.txt"
PORT = 8585
HISTORY_SIZE = 10

# Session log file path (set on startup)
session_log_file = None

# In-memory state
position_history = deque(maxlen=HISTORY_SIZE)
action_history = deque(maxlen=HISTORY_SIZE)
current_cycle = 0
current_goal = None
last_position = None
stuck_count = 0

# Agent command/result state (for GO_TO / INTERACT_WITH)
agent_state = {
    "command": "",
    "result": {}
}
COMMAND_FILE = r"C:\claudeblox\agent_command.txt"


def init_session_log():
    """Create new session log file and update current_log.txt pointer"""
    global session_log_file

    os.makedirs(LOG_DIR, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    session_log_file = os.path.join(LOG_DIR, f"session_{timestamp}.md")

    # Write initial header
    with open(session_log_file, 'w', encoding='utf-8') as f:
        f.write(f"# Game Session — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

    # Update pointer file so other scripts know which log to use
    with open(CURRENT_LOG_FILE, 'w', encoding='utf-8') as f:
        f.write(session_log_file)

    print(f"Session log: {session_log_file}")
    return session_log_file


def log_game_state(data, enriched):
    """Append game state to session log in markdown format"""
    global session_log_file

    if not session_log_file:
        return

    cycle = enriched.get('cycle', 0)
    timestamp = datetime.now().strftime('%H:%M:%S')

    pos = data.get('playerPosition', {})
    room = data.get('currentRoom', 'Unknown')
    health = data.get('playerHealth', 100)
    alive = data.get('isAlive', True)
    dark = data.get('isDark', False)
    flashlight = data.get('flashlightOn', False)

    is_stuck = enriched.get('isStuck', False)
    stuck_cycles = enriched.get('stuckCycles', 0)
    movement = enriched.get('movement', {})
    moved_dist = movement.get('distance', 0) if movement else 0

    collected = data.get('objectsCollected', [])
    rooms_visited = data.get('roomsVisited', [])
    recommendation = enriched.get('analysis', {}).get('recommendation', '')

    # Format nearby objects table
    nearby = data.get('nearbyObjects', [])[:10]
    nearby_table = "| Object | Distance | Direction | Angle |\n|--------|----------|-----------|-------|\n"
    for obj in nearby:
        name = obj.get('name', '?')
        dist = obj.get('distance', 0)
        direction = obj.get('direction', {})
        rel = direction.get('relative', '?')
        angle = direction.get('angle', 0)
        nearby_table += f"| {name} | {dist:.0f} | {rel} | {angle:.0f}° |\n"

    if not nearby:
        nearby_table += "| (none) | - | - | - |\n"

    # Build markdown block
    md = f"""---
## Cycle {cycle} | {timestamp}

### Game State
- **Position:** ({pos.get('x', 0):.0f}, {pos.get('y', 0):.0f}, {pos.get('z', 0):.0f}) | **Room:** {room}
- **Health:** {health} | **Alive:** {str(alive).lower()}
- **Dark:** {str(dark).lower()} | **Flashlight:** {'on' if flashlight else 'off'}
- **Stuck:** {'YES (' + str(stuck_cycles) + ' cycles)' if is_stuck else 'no'} | **Moved:** {moved_dist:.1f} studs
- **Keys collected:** {collected if collected else '[]'}
- **Rooms visited:** {', '.join(rooms_visited) if rooms_visited else 'none'}

### Nearby Objects (top 10)
{nearby_table}
### Recommendation
> {recommendation}

"""

    try:
        with open(session_log_file, 'a', encoding='utf-8') as f:
            f.write(md)
    except Exception as e:
        print(f"Log write error: {e}")


def calculate_distance(pos1, pos2):
    """Calculate distance between two positions"""
    if not pos1 or not pos2:
        return float('inf')
    dx = pos1.get('x', 0) - pos2.get('x', 0)
    dz = pos1.get('z', 0) - pos2.get('z', 0)
    return math.sqrt(dx*dx + dz*dz)


def detect_stuck(current_pos):
    """Check if player is stuck (position not changing)"""
    global last_position, stuck_count

    if last_position is None:
        last_position = current_pos
        stuck_count = 0
        return False, 0

    # Reset stuck counter when player is near spawn (new session / respawn)
    spawn_dist = math.sqrt(current_pos.get('x',0)**2 + current_pos.get('z',0)**2)
    if spawn_dist < 8:
        stuck_count = 0
        last_position = current_pos
        return False, 0

    distance = calculate_distance(current_pos, last_position)

    if distance < 3:  # Less than 3 studs moved
        stuck_count += 1
    else:
        stuck_count = 0

    last_position = current_pos
    return stuck_count >= 2, stuck_count


def enrich_game_state(data):
    """Add history and analysis to game state"""
    # Note: current_cycle is incremented only when agent acts (/actions endpoint)
    # NOT every second when Roblox sends state

    current_pos = data.get('playerPosition', {})
    current_room = data.get('currentRoom', '')

    # Detect stuck
    is_stuck, stuck_cycles = detect_stuck(current_pos)

    # Check if room changed
    room_changed = False
    if position_history:
        last_state = position_history[-1]
        room_changed = last_state.get('room', '') != current_room

    # Add to position history
    position_history.append({
        'cycle': current_cycle,
        'position': current_pos,
        'room': current_room,
        'timestamp': datetime.now().isoformat()
    })

    # Calculate movement from last cycle
    movement = None
    if len(position_history) >= 2:
        prev = position_history[-2].get('position', {})
        movement = {
            'dx': current_pos.get('x', 0) - prev.get('x', 0),
            'dz': current_pos.get('z', 0) - prev.get('z', 0),
            'distance': calculate_distance(current_pos, prev)
        }

    # Enrich the data
    data['_enriched'] = {
        'cycle': current_cycle,
        'isStuck': is_stuck,
        'stuckCycles': stuck_cycles,
        'roomChanged': room_changed,
        'movement': movement,
        'positionHistory': list(position_history)[-5:],  # Last 5 positions
        'actionHistory': list(action_history)[-5:],  # Last 5 action sets
        'currentGoal': current_goal,
        'analysis': {
            'movedSinceLastCycle': movement['distance'] > 3 if movement else True,
            'recommendation': get_recommendation(is_stuck, room_changed, data)
        }
    }

    return data


def get_recommendation(is_stuck, room_changed, data):
    """Generate recommendation based on current state"""
    if is_stuck:
        return "STUCK! Change direction. Try TURN_LEFT 90 or TURN_RIGHT 90, then FORWARD."

    if room_changed:
        return "NEW ROOM! Slow exploration first (TURN 30 + WAIT), then proceed to objective."

    # Check for nearby enemy
    nearby = data.get('nearbyObjects', [])
    for obj in nearby:
        name = obj.get('name', '').lower()
        dist = obj.get('distance', 999)
        if any(x in name for x in ['enemy', 'monster', 'creature', 'experiment', 'worker', 'patient']):
            if dist < 30:
                return f"DANGER! Enemy at {dist} studs. RUN! TURN_AROUND + SPRINT_FORWARD."
            elif dist < 60:
                return f"WARNING! Enemy at {dist} studs. Be careful, find alternate route."

    # Check flashlight
    if data.get('isDark') and not data.get('flashlightOn'):
        return "DARK! Enable FLASHLIGHT first."

    return "Proceed to objective."


class GameBridgeHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_POST(self):
        global current_goal
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode('utf-8')
            data = json.loads(body)

            # Handle /actions endpoint - receive executed actions from watcher
            if self.path == '/actions':
                global current_cycle
                current_cycle += 1  # Only increment cycle when agent actually acts

                actions = data.get('actions', [])

                action_history.append({
                    'cycle': current_cycle,
                    'actions': actions,
                    'timestamp': datetime.now().isoformat()
                })

                print(f"[{datetime.now().strftime('%H:%M:%S')}] Cycle {current_cycle}: {len(actions)} actions executed")

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b'{"status": "ok"}')
                return

            # Handle /goal endpoint - set current goal
            if self.path == '/goal':
                current_goal = data.get('goal')
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Goal set: {current_goal}")

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b'{"status": "ok"}')
                return

            # Handle /command endpoint - set agent command
            if self.path == '/command':
                agent_state["command"] = data.get("command", "")
                agent_state["result"] = {}
                if agent_state["command"]:
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Agent command set: {agent_state['command']}")

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b'{"ok": true}')
                return

            # Handle /result endpoint - set agent command result
            if self.path == '/result':
                agent_state["result"] = data
                if data:
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Agent result: {json.dumps(data)[:100]}")

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b'{"ok": true}')
                return

            # Handle /run_code endpoint for Lua execution
            if self.path == '/run_code':
                code = data.get('code', '')
                print(f"[{datetime.now().strftime('%H:%M:%S')}] run_code request: {code[:50]}...")

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({"result": "Code forwarded to MCP", "code": code}).encode())
                return

            # Default: game state update from Roblox
            data['timestamp'] = datetime.now().isoformat()
            data['received'] = True

            # Enrich with history and analysis
            enriched_data = enrich_game_state(data)

            # Save to file (no logging here — action_watcher logs when agent acts)
            with open(STATE_FILE, 'w', encoding='utf-8') as f:
                json.dump(enriched_data, f, indent=2)

            enriched = enriched_data.get('_enriched', {})
            pos = data.get('playerPosition', {})
            stuck_info = " STUCK!" if enriched.get('isStuck') else ""
            room_info = " NEW ROOM!" if enriched.get('roomChanged') else ""

            print(f"[{datetime.now().strftime('%H:%M:%S')}] Cycle {current_cycle}: pos=({pos.get('x', 0):.0f}, {pos.get('z', 0):.0f}){stuck_info}{room_info}")

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b'{"status": "ok"}')

        except Exception as e:
            print(f"Error: {e}")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())

    def do_GET(self):
        try:
            # Handle /command endpoint - return current agent command
            if self.path == '/command':
                # Check file for new command
                if os.path.exists(COMMAND_FILE):
                    try:
                        with open(COMMAND_FILE, "r") as f:
                            file_cmd = f.read().strip()
                        if file_cmd:
                            agent_state["command"] = file_cmd
                        os.remove(COMMAND_FILE)
                    except Exception:
                        pass

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({"command": agent_state["command"]}).encode())
                return

            # Handle /result endpoint - return agent command result
            if self.path == '/result':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps(agent_state["result"]).encode())
                return

            # Default: return game state
            if os.path.exists(STATE_FILE):
                with open(STATE_FILE, 'r', encoding='utf-8') as f:
                    data = f.read()
            else:
                data = '{"status": "no data yet"}'

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data.encode())
        except Exception as e:
            self.send_response(500)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()


def main():
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump({"status": "waiting for game data", "timestamp": datetime.now().isoformat()}, f)

    # Initialize session log
    init_session_log()

    server = HTTPServer(('localhost', PORT), GameBridgeHandler)
    print(f"=== ENHANCED GAME BRIDGE ===")
    print(f"Running on http://localhost:{PORT}")
    print(f"State file: {STATE_FILE}")
    print(f"Features: position history, action tracking, stuck detection, session logging")
    print("Waiting for game data...")
    print()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
