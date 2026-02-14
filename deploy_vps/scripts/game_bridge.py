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
PORT = 8585
HISTORY_SIZE = 10

# In-memory state
position_history = deque(maxlen=HISTORY_SIZE)
action_history = deque(maxlen=HISTORY_SIZE)
current_cycle = 0
current_goal = None
last_position = None
stuck_count = 0


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

    distance = calculate_distance(current_pos, last_position)

    if distance < 3:  # Less than 3 studs moved
        stuck_count += 1
    else:
        stuck_count = 0

    last_position = current_pos
    return stuck_count >= 2, stuck_count


def enrich_game_state(data):
    """Add history and analysis to game state"""
    global current_cycle
    current_cycle += 1

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
                actions = data.get('actions', [])
                cycle = data.get('cycle', current_cycle)

                action_history.append({
                    'cycle': cycle,
                    'actions': actions,
                    'timestamp': datetime.now().isoformat()
                })

                print(f"[{datetime.now().strftime('%H:%M:%S')}] Actions recorded: {len(actions)} commands")

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

            # Save to file
            with open(STATE_FILE, 'w', encoding='utf-8') as f:
                json.dump(enriched_data, f, indent=2)

            pos = data.get('playerPosition', {})
            enriched = enriched_data.get('_enriched', {})
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

    server = HTTPServer(('localhost', PORT), GameBridgeHandler)
    print(f"=== ENHANCED GAME BRIDGE ===")
    print(f"Running on http://localhost:{PORT}")
    print(f"State file: {STATE_FILE}")
    print(f"Features: position history, action tracking, stuck detection")
    print("Waiting for game data...")
    print()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
