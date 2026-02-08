"""
CLAUDEBLOX WATCHDOG
===================
Main supervisor process that keeps everything running 24/7.

Monitors:
- Claude Code process
- Roblox Studio process
- OBS Studio process
- Twitter MCP server

Handles:
- Process crashes (auto-restart)
- Rate limits (wait and retry)
- Network issues (wait and retry)
- Windows reboots (auto-start via Task Scheduler)
"""

import subprocess
import time
import os
import sys
import json
import logging
import psutil
from datetime import datetime
from pathlib import Path

# Configuration
CONFIG = {
    "claude_code": {
        "command": ["claude", "--dangerously-skip-permissions"],
        "cwd": "C:/claudeblox/deploy",
        "restart_delay": 10,
        "rate_limit_wait": 300,  # 5 minutes
    },
    "roblox_studio": {
        "process_name": "RobloxStudioBeta.exe",
        "exe_path": "C:/Users/Default/AppData/Local/Roblox/Versions/RobloxStudioBeta.exe",
        "project_path": "",  # Set after first run
        "restart_delay": 15,
    },
    "obs": {
        "process_name": "obs64.exe",
        "exe_path": "C:/Program Files/obs-studio/bin/64bit/obs64.exe",
        "restart_delay": 5,
    },
    "twitter_mcp": {
        "command": ["node", "C:/claudeblox/deploy/twitter_mcp/server.js"],
        "restart_delay": 5,
    },
    "check_interval": 30,  # seconds
    "log_file": "C:/claudeblox/logs/watchdog.log",
}

# Setup logging
log_dir = Path("C:/claudeblox/logs")
log_dir.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(CONFIG["log_file"]),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("watchdog")


class ProcessManager:
    """Manages a single process."""

    def __init__(self, name: str, config: dict):
        self.name = name
        self.config = config
        self.process = None
        self.restart_count = 0
        self.last_restart = None

    def is_running(self) -> bool:
        """Check if process is running."""
        if "process_name" in self.config:
            # Check by process name (for external apps like Roblox, OBS)
            for proc in psutil.process_iter(['name']):
                try:
                    if proc.info['name'] == self.config["process_name"]:
                        return True
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
            return False
        elif self.process:
            # Check subprocess
            return self.process.poll() is None
        return False

    def start(self):
        """Start the process."""
        logger.info(f"Starting {self.name}...")

        if "command" in self.config:
            # Start as subprocess
            self.process = subprocess.Popen(
                self.config["command"],
                cwd=self.config.get("cwd"),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                creationflags=subprocess.CREATE_NEW_CONSOLE if sys.platform == "win32" else 0
            )
            logger.info(f"{self.name} started with PID {self.process.pid}")
        elif "exe_path" in self.config:
            # Start external application
            exe_path = self.config["exe_path"]
            if os.path.exists(exe_path):
                subprocess.Popen([exe_path], shell=True)
                logger.info(f"{self.name} started from {exe_path}")
            else:
                logger.error(f"{self.name} executable not found: {exe_path}")

        self.restart_count += 1
        self.last_restart = datetime.now()

    def stop(self):
        """Stop the process."""
        logger.info(f"Stopping {self.name}...")

        if "process_name" in self.config:
            # Kill by name
            os.system(f'taskkill /F /IM {self.config["process_name"]} 2>nul')
        elif self.process:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()

        logger.info(f"{self.name} stopped")

    def restart(self):
        """Restart the process."""
        self.stop()
        time.sleep(self.config.get("restart_delay", 5))
        self.start()

    def check_output_for_errors(self) -> str | None:
        """Check process output for known errors."""
        if self.process and self.process.stdout:
            try:
                # Non-blocking read
                import select
                if sys.platform != "win32":
                    ready, _, _ = select.select([self.process.stdout], [], [], 0)
                    if ready:
                        line = self.process.stdout.readline().decode('utf-8', errors='ignore')
                        if "rate_limit" in line.lower() or "429" in line:
                            return "rate_limit"
                        if "error" in line.lower():
                            return "error"
            except:
                pass
        return None


class Watchdog:
    """Main watchdog that monitors all processes."""

    def __init__(self):
        self.processes = {
            "claude_code": ProcessManager("Claude Code", CONFIG["claude_code"]),
            "obs": ProcessManager("OBS Studio", CONFIG["obs"]),
            "twitter_mcp": ProcessManager("Twitter MCP", CONFIG["twitter_mcp"]),
        }
        self.running = True
        self.rate_limit_until = None

    def start_all(self):
        """Start all processes."""
        logger.info("=" * 50)
        logger.info("CLAUDEBLOX WATCHDOG STARTING")
        logger.info("=" * 50)

        # Start in order
        order = ["obs", "twitter_mcp", "claude_code"]
        for name in order:
            if name in self.processes:
                self.processes[name].start()
                time.sleep(3)  # Give each process time to start

        logger.info("All processes started")

    def check_all(self):
        """Check all processes and restart if needed."""
        for name, pm in self.processes.items():
            if not pm.is_running():
                logger.warning(f"{name} is not running!")

                # Check if we're in rate limit cooldown
                if name == "claude_code" and self.rate_limit_until:
                    if datetime.now() < self.rate_limit_until:
                        remaining = (self.rate_limit_until - datetime.now()).seconds
                        logger.info(f"Rate limit cooldown, {remaining}s remaining...")
                        # Switch OBS to IDLE scene
                        self.switch_obs_scene("IDLE")
                        continue
                    else:
                        self.rate_limit_until = None

                pm.restart()

            # Check for rate limit errors
            if name == "claude_code":
                error = pm.check_output_for_errors()
                if error == "rate_limit":
                    wait_time = CONFIG["claude_code"]["rate_limit_wait"]
                    logger.warning(f"Rate limit detected! Waiting {wait_time}s...")
                    self.rate_limit_until = datetime.now() + timedelta(seconds=wait_time)
                    self.switch_obs_scene("IDLE")

    def switch_obs_scene(self, scene: str):
        """Switch OBS scene."""
        try:
            subprocess.run(
                ["python", "C:/claudeblox/scripts/obs_control.py", "--scene", scene],
                capture_output=True,
                timeout=5
            )
            logger.info(f"Switched OBS to {scene} scene")
        except Exception as e:
            logger.error(f"Failed to switch OBS scene: {e}")

    def run(self):
        """Main loop."""
        self.start_all()

        while self.running:
            try:
                time.sleep(CONFIG["check_interval"])
                self.check_all()

                # Log status every 5 minutes
                if int(time.time()) % 300 < CONFIG["check_interval"]:
                    status = {name: pm.is_running() for name, pm in self.processes.items()}
                    logger.info(f"Status: {status}")

            except KeyboardInterrupt:
                logger.info("Shutdown requested...")
                self.running = False
            except Exception as e:
                logger.error(f"Error in main loop: {e}")
                time.sleep(10)

        self.shutdown()

    def shutdown(self):
        """Stop all processes."""
        logger.info("Shutting down all processes...")
        for pm in self.processes.values():
            pm.stop()
        logger.info("Watchdog stopped")


def main():
    """Entry point."""
    from datetime import timedelta

    # Check if already running
    current_pid = os.getpid()
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            if proc.info['pid'] != current_pid:
                cmdline = proc.info.get('cmdline') or []
                if 'watchdog.py' in ' '.join(cmdline):
                    logger.error("Watchdog is already running!")
                    sys.exit(1)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    watchdog = Watchdog()
    watchdog.run()


if __name__ == "__main__":
    main()
