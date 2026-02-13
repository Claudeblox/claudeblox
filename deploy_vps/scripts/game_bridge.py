"""
Game Bridge Server - receives game state from Roblox via HTTP.

Roblox LocalScript sends POST requests with player position, nearby objects, etc.
This server saves the data to game_state.json for computer-player to read.

Usage:
    python game_bridge.py

Runs on http://localhost:8585
"""
import json
import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime

STATE_FILE = r"C:\claudeblox\game_state.json"
PORT = 8585


class GameBridgeHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress default logging
        pass

    def do_POST(self):
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode('utf-8')

            # Handle /run_code endpoint for Lua execution
            if self.path == '/run_code':
                data = json.loads(body)
                code = data.get('code', '')
                print(f"[{datetime.now().strftime('%H:%M:%S')}] run_code request: {code[:50]}...")

                # TODO: Forward to MCP or execute via plugin
                # For now, return placeholder - actual execution happens via MCP
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({"result": "Code forwarded to MCP", "code": code}).encode())
                return

            # Default: game state update
            data = json.loads(body)
            data['timestamp'] = datetime.now().isoformat()
            data['received'] = True

            # Save to file
            with open(STATE_FILE, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2)

            print(f"[{datetime.now().strftime('%H:%M:%S')}] State updated: pos={data.get('playerPosition', 'N/A')}")

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
        # Return current state
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
    # Create empty state file
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump({"status": "waiting for game data", "timestamp": datetime.now().isoformat()}, f)

    server = HTTPServer(('localhost', PORT), GameBridgeHandler)
    print(f"Game Bridge running on http://localhost:{PORT}")
    print(f"State file: {STATE_FILE}")
    print("Waiting for game data...")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
