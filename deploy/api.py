#!/usr/bin/env python3
"""
ClaudeBlox API Server — Roblox Game Development

Endpoints:
- GET  /health       - system status
- GET  /api/logs     - recent logs
- POST /trigger      - manual agent run
- POST /inject       - inject command to agent
- POST /vps/trigger  - trigger Claude Code on Windows VPS via SSH
- GET  /vps/status   - check VPS connection status
- GET  /status       - detailed agent run status
- GET  /workspace/<path> - serve files
"""

import os
import subprocess
import logging
import atexit
import threading
from functools import wraps
from datetime import datetime

from flask import Flask, jsonify, request, send_file
from apscheduler.schedulers.background import BackgroundScheduler

# ═══════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════

app = Flask(__name__)

DATABASE_URL = os.environ.get("DATABASE_URL")
ADMIN_TOKEN = os.environ.get("ADMIN_TOKEN", "")
WORKSPACE = "/data/workspace"
CLAUDE_HOME = "/home/claude"

# VPS config
VPS_HOST = os.environ.get("VPS_HOST", "")
VPS_PASSWORD = os.environ.get("VPS_PASSWORD", "")
VPS_USER = os.environ.get("VPS_USER", "Administrator")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
log = logging.getLogger("api")

log.info("=" * 50)
log.info("ClaudeBlox API Starting")
log.info(f"DATABASE_URL: {'SET (' + str(len(DATABASE_URL)) + ' chars)' if DATABASE_URL else 'NOT SET'}")
log.info(f"ADMIN_TOKEN: {'SET' if ADMIN_TOKEN else 'NOT SET (API unprotected!)'}")
log.info(f"VPS_HOST: {'SET' if VPS_HOST else 'NOT SET'}")
log.info("=" * 50)

# ═══════════════════════════════════════════════════════════════════════════
# AUTH
# ═══════════════════════════════════════════════════════════════════════════

def require_admin(f):
    """Decorator to require admin token for protected endpoints."""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not ADMIN_TOKEN:
            return f(*args, **kwargs)

        auth = request.headers.get("Authorization", "")
        if auth.startswith("Bearer "):
            token = auth[7:]
            if token == ADMIN_TOKEN:
                return f(*args, **kwargs)

        token = request.headers.get("X-Admin-Token", "")
        if token == ADMIN_TOKEN:
            return f(*args, **kwargs)

        token = request.args.get("token", "")
        if token == ADMIN_TOKEN:
            return f(*args, **kwargs)

        log.warning(f"Unauthorized access attempt to {request.path}")
        return jsonify({"error": "Unauthorized"}), 401

    return decorated

# ═══════════════════════════════════════════════════════════════════════════
# DATABASE
# ═══════════════════════════════════════════════════════════════════════════

def get_db_connection():
    if not DATABASE_URL:
        log.warning("DATABASE_URL not set")
        return None
    try:
        import psycopg2
        return psycopg2.connect(DATABASE_URL)
    except Exception as e:
        log.error(f"DB connection error: {e}")
        return None

def get_recent_logs(limit=50):
    conn = get_db_connection()
    if not conn:
        return []

    try:
        from psycopg2.extras import RealDictCursor
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """SELECT action, message, role, details, created_at
               FROM claudeblox.logs
               ORDER BY created_at DESC
               LIMIT %s""",
            (limit,)
        )
        rows = cur.fetchall()
        cur.close()
        conn.close()

        return [
            {
                "action": row["action"],
                "message": row["message"],
                "role": row["role"],
                "details": row["details"],
                "created_at": row["created_at"].isoformat() if row["created_at"] else None
            }
            for row in rows
        ]
    except Exception as e:
        log.error(f"Failed to get logs: {e}")
        return []

def log_to_db(action, message="", details=None, role="system"):
    """Log action to public.logs"""
    conn = get_db_connection()
    if not conn:
        return

    try:
        import json
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO claudeblox.logs (action, message, role, details)
               VALUES (%s, %s, %s, %s)""",
            (action, message, role, json.dumps(details or {}))
        )
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        log.error(f"Failed to log to DB: {e}")

# ═══════════════════════════════════════════════════════════════════════════
# AGENT (Claude Code orchestration)
# ═══════════════════════════════════════════════════════════════════════════

import uuid
from pathlib import Path

PROMPT_FILE = Path(WORKSPACE) / ".claude" / "CLAUDE.md"
INJECT_FILE = Path(WORKSPACE) / "inject.txt"

# ═══════════════════════════════════════════════════════════════════════════
# PARALLEL AGENT MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

MAX_TRIGGER_AGENTS = 3
trigger_semaphore = threading.Semaphore(MAX_TRIGGER_AGENTS)
cron_agent_running = False

active_runs = {}
active_runs_lock = threading.Lock()

def read_prompt(inject_text=None):
    """Build prompt from CLAUDE.md + inject"""
    parts = []

    if PROMPT_FILE.exists():
        parts.append(PROMPT_FILE.read_text(encoding="utf-8"))
    else:
        log.warning(f"Prompt file not found: {PROMPT_FILE}")
        parts.append("You are ClaudeBlox agent. Build a Roblox game using MCP tools.")

    if inject_text:
        parts.append(f"\n\n---\n## IMMEDIATE TASK (inject_now)\n{inject_text}\n\nDo this task FIRST before your regular work.")

    return "\n".join(parts)

def check_inject():
    """Check for inject.txt and return contents if exists."""
    if INJECT_FILE.exists():
        try:
            content = INJECT_FILE.read_text(encoding="utf-8").strip()
            INJECT_FILE.unlink()
            log.info(f"Inject found: {content[:100]}...")
            return content
        except Exception as e:
            log.error(f"Failed to read inject file: {e}")
    return None


def _run_agent_worker(run_id, prompt, inject_text, source):
    """Background worker that runs Claude Code"""
    global cron_agent_running

    def _cleanup():
        global cron_agent_running
        if source == "cron":
            cron_agent_running = False
        elif source == "trigger":
            trigger_semaphore.release()

        with active_runs_lock:
            if run_id in active_runs:
                active_runs[run_id]["status"] = "completed"
                active_runs[run_id]["end_time"] = datetime.now()

    try:
        cmd = [
            "claude",
            "-p", prompt,
            "--output-format", "json",
            "--dangerously-skip-permissions",
            "--max-turns", "100",
            "--no-session-persistence"
        ]

        env = os.environ.copy()
        env["HOME"] = CLAUDE_HOME
        env["TERM"] = "dumb"
        env["NO_COLOR"] = "1"
        env["CLAUDEBLOX_RUN_ID"] = run_id

        start_time = datetime.now()

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=7200,  # 2 hours max (continuous dev cycle)
            cwd=str(WORKSPACE),
            env=env
        )

        duration = (datetime.now() - start_time).total_seconds()
        _cleanup()

        if result.returncode == 0:
            log.info(f"Claude completed in {duration:.1f}s (source: {source})")
            log_to_db("complete", f"Агент завершил работу за {duration:.1f}s", {
                "success": True,
                "duration_seconds": duration,
                "source": source,
                "had_inject": inject_text is not None,
                "output_tail": result.stdout[-500:] if result.stdout else ""
            }, "system")
        else:
            log.error(f"Claude failed with code {result.returncode}")
            log.error(f"STDERR: {result.stderr[:1000]}")
            log_to_db("error", "Ошибка агента", {
                "returncode": result.returncode,
                "stderr": result.stderr[-500:] if result.stderr else "",
                "stdout_tail": result.stdout[-500:] if result.stdout else "",
                "duration_seconds": duration,
                "source": source
            }, "error")

    except subprocess.TimeoutExpired:
        _cleanup()
        log.error("Claude timed out (2h)")
        log_to_db("error", "Таймаут агента (2ч)", {"error": "Timeout", "source": source}, "error")

    except Exception as e:
        _cleanup()
        log.exception(f"Agent error: {e}")
        log_to_db("error", f"Критическая ошибка: {e}", {"error": str(e), "source": source}, "error")


def _start_agent(run_id, source, direct_inject=None):
    """Common agent startup logic"""
    log.info("=" * 50)
    log.info(f"AGENT RUN STARTED - run_id: {run_id} (source: {source})")
    log.info("=" * 50)

    with active_runs_lock:
        active_runs[run_id] = {
            "status": "running",
            "start_time": datetime.now(),
            "source": source,
            "inject": direct_inject[:100] if direct_inject else None
        }

    log_to_db("start", "Запуск агента", {
        "run_id": run_id,
        "source": source,
        "has_inject": direct_inject is not None,
        "inject_preview": direct_inject[:100] if direct_inject else None
    }, "system")

    if direct_inject:
        inject_text = direct_inject
    else:
        inject_text = check_inject()

    prompt = read_prompt(inject_text)
    log.info(f"Prompt loaded ({len(prompt)} chars)")

    thread = threading.Thread(
        target=_run_agent_worker,
        args=(run_id, prompt, inject_text, source),
        daemon=True
    )
    thread.start()

    return run_id, prompt, inject_text


def run_agent_cron():
    """Start agent via CRON - max 1 at a time"""
    global cron_agent_running

    if cron_agent_running:
        log.warning("Cron agent already running, skipping")
        return {"success": False, "error": "Cron agent already running"}

    cron_agent_running = True
    run_id = str(uuid.uuid4())
    _start_agent(run_id, "cron")

    return {
        "success": True,
        "run_id": run_id,
        "source": "cron",
        "status": "started"
    }


def run_agent_trigger(inject_text=None):
    """Start agent via TRIGGER - up to MAX_TRIGGER_AGENTS in parallel"""
    if not trigger_semaphore.acquire(blocking=False):
        with active_runs_lock:
            trigger_count = sum(1 for r in active_runs.values()
                               if r["status"] == "running" and r["source"] == "trigger")
        return {
            "success": False,
            "error": f"All {MAX_TRIGGER_AGENTS} trigger slots busy",
            "slots_used": trigger_count
        }

    run_id = str(uuid.uuid4())
    _start_agent(run_id, "trigger", direct_inject=inject_text)

    with active_runs_lock:
        trigger_count = sum(1 for r in active_runs.values()
                           if r["status"] == "running" and r["source"] == "trigger")

    return {
        "success": True,
        "run_id": run_id,
        "source": "trigger",
        "status": "started",
        "slots_used": trigger_count,
        "slots_total": MAX_TRIGGER_AGENTS,
        "has_inject": inject_text is not None,
        "inject_preview": inject_text[:50] + "..." if inject_text and len(inject_text) > 50 else inject_text
    }


# ═══════════════════════════════════════════════════════════════════════════
# VPS MANAGEMENT (SSH to Windows VPS running Roblox Studio)
# ═══════════════════════════════════════════════════════════════════════════

def ssh_to_vps(command, timeout=30):
    """Execute command on Windows VPS via SSH."""
    if not VPS_HOST or not VPS_PASSWORD:
        return {"success": False, "error": "VPS_HOST or VPS_PASSWORD not configured"}

    try:
        cmd = [
            "sshpass", "-p", VPS_PASSWORD,
            "ssh", "-o", "StrictHostKeyChecking=no",
            "-o", "ConnectTimeout=10",
            f"{VPS_USER}@{VPS_HOST}",
            command
        ]

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )

        return {
            "success": result.returncode == 0,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "returncode": result.returncode
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "error": f"SSH timeout ({timeout}s)"}
    except FileNotFoundError:
        return {"success": False, "error": "sshpass not installed"}
    except Exception as e:
        return {"success": False, "error": str(e)}


# ═══════════════════════════════════════════════════════════════════════════
# SCHEDULER (CRON_TIME=0 disables, default disabled for ClaudeBlox)
# ═══════════════════════════════════════════════════════════════════════════

CRON_TIME = int(os.environ.get("CRON_TIME", 0))  # default disabled

scheduler = BackgroundScheduler()

if CRON_TIME > 0:
    scheduler.add_job(func=run_agent_cron, trigger="interval", minutes=CRON_TIME, id="agent_scheduled")
    scheduler.start()
    log.info(f"Scheduler started: every {CRON_TIME} minutes")
    atexit.register(lambda: scheduler.shutdown())
else:
    log.info("Scheduler DISABLED (CRON_TIME=0). Use /trigger or /vps/trigger for manual runs.")

# ═══════════════════════════════════════════════════════════════════════════
# ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════

@app.route("/")
def index():
    with active_runs_lock:
        running_count = sum(1 for r in active_runs.values() if r["status"] == "running")
        trigger_running = sum(1 for r in active_runs.values()
                             if r["status"] == "running" and r.get("source") == "trigger")

    return jsonify({
        "service": "ClaudeBlox",
        "status": "running",
        "mode": "roblox-dev",
        "scheduler": f"every {CRON_TIME} minutes" if CRON_TIME > 0 else "disabled",
        "cron_running": cron_agent_running,
        "trigger_slots": {
            "used": trigger_running,
            "total": MAX_TRIGGER_AGENTS,
            "available": MAX_TRIGGER_AGENTS - trigger_running
        },
        "total_running": running_count,
        "vps_configured": bool(VPS_HOST)
    })


@app.route("/status")
def status():
    """Detailed status of all agent runs"""
    with active_runs_lock:
        running = []
        for run_id, info in active_runs.items():
            if info["status"] == "running":
                running.append({
                    "run_id": run_id,
                    "source": info.get("source", "unknown"),
                    "started": info["start_time"].isoformat(),
                    "duration_seconds": (datetime.now() - info["start_time"]).total_seconds(),
                    "inject": info.get("inject")
                })

        trigger_running = sum(1 for r in running if r["source"] == "trigger")

    return jsonify({
        "cron": {
            "running": cron_agent_running,
            "max": 1
        },
        "trigger": {
            "running": trigger_running,
            "max": MAX_TRIGGER_AGENTS,
            "available": MAX_TRIGGER_AGENTS - trigger_running
        },
        "active_runs": running,
        "total_running": len(running)
    })

@app.route("/health")
def health():
    try:
        result = subprocess.run(
            ["claude", "--version"],
            capture_output=True, text=True, timeout=5,
            env={**os.environ, "HOME": CLAUDE_HOME}
        )
        claude_ok = result.returncode == 0
        claude_version = result.stdout.strip() if claude_ok else None
    except:
        claude_ok = False
        claude_version = None

    return jsonify({
        "status": "ok",
        "service": "ClaudeBlox",
        "claude_available": claude_ok,
        "claude_version": claude_version,
        "agent_running": cron_agent_running or (MAX_TRIGGER_AGENTS - trigger_semaphore._value > 0),
        "scheduler_enabled": CRON_TIME > 0,
        "cron_interval_minutes": CRON_TIME,
        "vps_configured": bool(VPS_HOST),
        "database_url_set": DATABASE_URL is not None and len(DATABASE_URL) > 0,
        "timestamp": datetime.now().isoformat()
    })

@app.route("/trigger", methods=["POST"])
@require_admin
def trigger():
    """
    Manual agent trigger (runs on Railway). Requires ADMIN_TOKEN.
    Optional body: {"inject": "task for this specific agent"}
    """
    data = request.get_json() or {}
    inject_text = data.get("inject", "").strip() or None

    if inject_text:
        log.info(f"Manual trigger with inject: {inject_text[:50]}...")
    else:
        log.info("Manual trigger requested")

    result = run_agent_trigger(inject_text=inject_text)
    return jsonify(result)

@app.route("/inject", methods=["POST"])
@require_admin
def inject():
    """
    Inject command and start agent. Requires ADMIN_TOKEN.
    Body: {"text": "your command here"}
    """
    data = request.get_json() or {}
    text = data.get("text", "").strip()

    if not text:
        return jsonify({"error": "Missing 'text' field"}), 400

    log.info(f"Inject requested: {text[:50]}...")

    result = run_agent_trigger(inject_text=text)
    result["injected"] = text[:100]

    return jsonify(result)

# ═══════════════════════════════════════════════════════════════════════════
# VPS ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════

@app.route("/vps/status", methods=["GET"])
@require_admin
def vps_status():
    """Check VPS connection and Roblox Studio status."""
    if not VPS_HOST:
        return jsonify({
            "configured": False,
            "error": "VPS_HOST not set"
        })

    # Check SSH connection
    ssh_result = ssh_to_vps("echo ok", timeout=15)

    # Check if Claude Code is running on VPS
    claude_result = ssh_to_vps("tasklist /FI \"IMAGENAME eq node.exe\" /NH", timeout=15)

    # Check if Roblox Studio is running
    roblox_result = ssh_to_vps("tasklist /FI \"IMAGENAME eq RobloxStudioBeta.exe\" /NH", timeout=15)

    return jsonify({
        "configured": True,
        "host": VPS_HOST,
        "ssh_connected": ssh_result["success"],
        "claude_running": "node.exe" in claude_result.get("stdout", "") if claude_result["success"] else False,
        "roblox_studio_running": "RobloxStudioBeta" in roblox_result.get("stdout", "") if roblox_result["success"] else False,
        "ssh_error": ssh_result.get("error") if not ssh_result["success"] else None
    })

@app.route("/vps/trigger", methods=["POST"])
@require_admin
def vps_trigger():
    """
    Trigger Claude Code on Windows VPS to start building/playing.
    Body: {"command": "optional command to run", "action": "build|play|test"}
    """
    if not VPS_HOST:
        return jsonify({"success": False, "error": "VPS not configured"}), 400

    data = request.get_json() or {}
    action = data.get("action", "build")
    custom_command = data.get("command", "")

    log.info(f"VPS trigger: action={action}")
    log_to_db("vps_trigger", f"VPS trigger: {action}", {"action": action}, "system")

    if custom_command:
        # Run custom command
        result = ssh_to_vps(custom_command, timeout=60)
    elif action == "build":
        # Start Claude Code with build prompt
        result = ssh_to_vps(
            'powershell -File C:\\claudeblox\\start-claude.ps1 -Action build',
            timeout=30
        )
    elif action == "play":
        # Start Claude Code with play prompt
        result = ssh_to_vps(
            'powershell -File C:\\claudeblox\\start-claude.ps1 -Action play',
            timeout=30
        )
    elif action == "test":
        # Start Claude Code with test prompt
        result = ssh_to_vps(
            'powershell -File C:\\claudeblox\\start-claude.ps1 -Action test',
            timeout=30
        )
    else:
        return jsonify({"success": False, "error": f"Unknown action: {action}"}), 400

    if result["success"]:
        log_to_db("vps_triggered", f"VPS {action} запущен", result, "system")
    else:
        log_to_db("vps_error", f"VPS {action} ошибка", result, "error")

    return jsonify(result)

@app.route("/vps/screenshot", methods=["GET"])
@require_admin
def vps_screenshot():
    """Take screenshot from VPS and return it."""
    if not VPS_HOST:
        return jsonify({"success": False, "error": "VPS not configured"}), 400

    result = ssh_to_vps(
        'python C:\\claudeblox\\screenshot.py --base64',
        timeout=15
    )

    if result["success"]:
        return jsonify({
            "success": True,
            "image_base64": result["stdout"]
        })

    return jsonify(result)

# ═══════════════════════════════════════════════════════════════════════════
# FILES
# ═══════════════════════════════════════════════════════════════════════════

@app.route("/api/logs")
@require_admin
def api_logs():
    """Get recent logs. Requires ADMIN_TOKEN."""
    limit = request.args.get("limit", 50, type=int)
    logs = get_recent_logs(limit)
    return jsonify({"logs": logs, "count": len(logs)})

@app.route("/workspace/<path:filename>")
def serve_workspace_file(filename):
    try:
        filepath = os.path.join(WORKSPACE, filename)

        if not os.path.abspath(filepath).startswith(os.path.abspath(WORKSPACE)):
            return "Access denied", 403

        if not os.path.exists(filepath) or not os.path.isfile(filepath):
            return "File not found", 404

        return send_file(filepath)

    except Exception as e:
        return f"Error: {str(e)}", 500

GENERATED_IMAGES = "/data/generated_images"

@app.route("/images/<path:filename>")
def serve_generated_image(filename):
    """Serve generated cover images."""
    try:
        filepath = os.path.join(GENERATED_IMAGES, filename)

        if not os.path.abspath(filepath).startswith(os.path.abspath(GENERATED_IMAGES)):
            return "Access denied", 403

        if not os.path.exists(filepath) or not os.path.isfile(filepath):
            return "File not found", 404

        return send_file(filepath)

    except Exception as e:
        return f"Error: {str(e)}", 500

# ═══════════════════════════════════════════════════════════════════════════
# TWITTER CALLBACK
# ═══════════════════════════════════════════════════════════════════════════

@app.route("/auth/twitter/callback")
def twitter_callback():
    return jsonify({
        "message": "Callback received",
        "oauth_token": request.args.get("oauth_token"),
        "oauth_verifier": request.args.get("oauth_verifier"),
        "code": request.args.get("code")
    })

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    log.info(f"Starting ClaudeBlox API on port {port}")
    app.run(host="0.0.0.0", port=port, debug=False)
