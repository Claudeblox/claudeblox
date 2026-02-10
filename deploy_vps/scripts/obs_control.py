"""
OBS Scene Controller
====================
Controls OBS Studio via WebSocket API.
Switches scenes for different phases of ClaudeBlox.

Usage:
    python obs_control.py --scene CODING
    python obs_control.py --scene PLAYING
    python obs_control.py --scene BUILDING
    python obs_control.py --scene IDLE
    python obs_control.py --status
"""

import argparse
import json
import sys
import hashlib
import base64
import subprocess
import time

try:
    import websocket
except ImportError:
    print("Installing websocket-client...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "websocket-client"])
    import websocket


def focus_window(window_type: str):
    """Focus window based on scene type."""
    try:
        if window_type == "terminal":
            subprocess.run([sys.executable, "C:/claudeblox/scripts/window_manager.py", "--focus-terminal"],
                          capture_output=True, timeout=5)
        elif window_type == "studio":
            subprocess.run([sys.executable, "C:/claudeblox/scripts/window_manager.py", "--focus-studio"],
                          capture_output=True, timeout=5)
    except:
        pass  # Don't fail if window focus fails


# OBS WebSocket configuration
OBS_HOST = "localhost"
OBS_PORT = 4455
OBS_PASSWORD = "claudeblox"  # Set this in OBS WebSocket settings

# Scene names (must match OBS scene names exactly)
SCENES = {
    "CODING": "CODING",
    "PLAYING": "PLAYING",
    "BUILDING": "PLAYING",  # BUILDING uses PLAYING scene (shows Studio)
    "IDLE": "IDLE",
}


class OBSController:
    """Controls OBS via WebSocket."""

    def __init__(self, host: str = OBS_HOST, port: int = OBS_PORT, password: str = OBS_PASSWORD):
        self.url = f"ws://{host}:{port}"
        self.password = password
        self.ws = None
        self.message_id = 0

    def connect(self) -> bool:
        """Connect to OBS WebSocket."""
        try:
            self.ws = websocket.create_connection(self.url, timeout=5)

            # Receive hello message
            hello = json.loads(self.ws.recv())

            if hello.get("op") == 0:  # Hello
                # Authenticate if required
                auth = hello.get("d", {}).get("authentication")
                if auth:
                    self._authenticate(auth)
                else:
                    # Send identify without auth
                    self._send({
                        "op": 1,
                        "d": {
                            "rpcVersion": 1
                        }
                    })

                # Wait for identified response
                response = json.loads(self.ws.recv())
                if response.get("op") == 2:  # Identified
                    return True

            return False
        except Exception as e:
            print(f"Failed to connect to OBS: {e}")
            return False

    def _authenticate(self, auth: dict):
        """Authenticate with OBS WebSocket."""
        challenge = auth.get("challenge", "")
        salt = auth.get("salt", "")

        # Generate auth string
        secret = base64.b64encode(
            hashlib.sha256((self.password + salt).encode()).digest()
        ).decode()

        auth_string = base64.b64encode(
            hashlib.sha256((secret + challenge).encode()).digest()
        ).decode()

        self._send({
            "op": 1,
            "d": {
                "rpcVersion": 1,
                "authentication": auth_string
            }
        })

    def _send(self, data: dict):
        """Send message to OBS."""
        self.ws.send(json.dumps(data))

    def _request(self, request_type: str, request_data: dict = None) -> dict:
        """Send a request and get response."""
        self.message_id += 1

        message = {
            "op": 6,
            "d": {
                "requestType": request_type,
                "requestId": str(self.message_id),
            }
        }

        if request_data:
            message["d"]["requestData"] = request_data

        self._send(message)

        # Wait for response
        while True:
            response = json.loads(self.ws.recv())
            if response.get("op") == 7:  # RequestResponse
                return response.get("d", {})

    def switch_scene(self, scene_name: str) -> bool:
        """Switch to a scene and focus appropriate window."""
        if scene_name not in SCENES:
            print(f"Unknown scene: {scene_name}")
            print(f"Available scenes: {list(SCENES.keys())}")
            return False

        try:
            result = self._request("SetCurrentProgramScene", {
                "sceneName": SCENES[scene_name]
            })

            if result.get("requestStatus", {}).get("result"):
                print(f"Switched to scene: {scene_name}")

                # Focus appropriate window
                time.sleep(0.3)  # Small delay for scene switch
                if scene_name == "CODING":
                    focus_window("terminal")
                    print("Focused: Terminal")
                elif scene_name in ("PLAYING", "BUILDING"):
                    focus_window("studio")
                    print("Focused: Roblox Studio")

                return True
            else:
                print(f"Failed to switch scene: {result}")
                return False
        except Exception as e:
            print(f"Error switching scene: {e}")
            return False

    def get_current_scene(self) -> str | None:
        """Get current scene name."""
        try:
            result = self._request("GetCurrentProgramScene")
            return result.get("currentProgramSceneName")
        except Exception as e:
            print(f"Error getting current scene: {e}")
            return None

    def get_scene_list(self) -> list:
        """Get list of all scenes."""
        try:
            result = self._request("GetSceneList")
            scenes = result.get("scenes", [])
            return [s.get("sceneName") for s in scenes]
        except Exception as e:
            print(f"Error getting scene list: {e}")
            return []

    def get_status(self) -> dict:
        """Get OBS status."""
        try:
            current = self.get_current_scene()
            scenes = self.get_scene_list()

            # Check streaming status
            stream_result = self._request("GetStreamStatus")
            recording_result = self._request("GetRecordStatus")

            return {
                "connected": True,
                "current_scene": current,
                "scenes": scenes,
                "streaming": stream_result.get("outputActive", False),
                "recording": recording_result.get("outputActive", False),
            }
        except Exception as e:
            return {
                "connected": False,
                "error": str(e)
            }

    def start_streaming(self) -> bool:
        """Start streaming."""
        try:
            self._request("StartStream")
            print("Streaming started")
            return True
        except Exception as e:
            print(f"Failed to start streaming: {e}")
            return False

    def stop_streaming(self) -> bool:
        """Stop streaming."""
        try:
            self._request("StopStream")
            print("Streaming stopped")
            return True
        except Exception as e:
            print(f"Failed to stop streaming: {e}")
            return False

    def disconnect(self):
        """Disconnect from OBS."""
        if self.ws:
            self.ws.close()


def main():
    parser = argparse.ArgumentParser(description="Control OBS Studio")
    parser.add_argument("--scene", type=str, help="Switch to scene (CODING, PLAYING, BUILDING, IDLE)")
    parser.add_argument("--status", action="store_true", help="Get OBS status")
    parser.add_argument("--start-stream", action="store_true", help="Start streaming")
    parser.add_argument("--stop-stream", action="store_true", help="Stop streaming")
    parser.add_argument("--host", type=str, default=OBS_HOST, help="OBS WebSocket host")
    parser.add_argument("--port", type=int, default=OBS_PORT, help="OBS WebSocket port")
    parser.add_argument("--password", type=str, default=OBS_PASSWORD, help="OBS WebSocket password")

    args = parser.parse_args()

    controller = OBSController(args.host, args.port, args.password)

    if not controller.connect():
        print("Failed to connect to OBS WebSocket")
        print("Make sure OBS is running and WebSocket server is enabled")
        print("Tools -> WebSocket Server Settings -> Enable WebSocket server")
        sys.exit(1)

    try:
        if args.scene:
            success = controller.switch_scene(args.scene.upper())
            sys.exit(0 if success else 1)

        elif args.status:
            status = controller.get_status()
            print(json.dumps(status, indent=2))

        elif args.start_stream:
            controller.start_streaming()

        elif args.stop_stream:
            controller.stop_streaming()

        else:
            # Default: show status
            status = controller.get_status()
            print(json.dumps(status, indent=2))

    finally:
        controller.disconnect()


if __name__ == "__main__":
    main()
