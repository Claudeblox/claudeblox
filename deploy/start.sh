#!/bin/bash

# ==============================================
# ClaudeBlox - Startup Script
# ==============================================

# Debug: show all env vars containing URL or KEY
echo "=== ENV DEBUG ==="
env | grep -E "(DATABASE|TWITTER|OPENROUTER|SUPABASE|VPS)" || echo "No matching vars found"
echo "================="

# Explicitly export Railway variables
export DATABASE_URL="${DATABASE_URL}"
export TWITTER_API_KEY="${TWITTER_API_KEY}"
export TWITTER_API_SECRET="${TWITTER_API_SECRET}"
export TWITTER_ACCESS_TOKEN="${TWITTER_ACCESS_TOKEN}"
export TWITTER_ACCESS_SECRET="${TWITTER_ACCESS_SECRET}"
export OPENROUTER_API_KEY="${OPENROUTER_API_KEY}"
export SUPABASE_URL="${SUPABASE_URL}"
export SUPABASE_KEY="${SUPABASE_KEY}"
export ADMIN_TOKEN="${ADMIN_TOKEN}"
export VPS_HOST="${VPS_HOST}"
export VPS_PASSWORD="${VPS_PASSWORD}"
export VPS_USER="${VPS_USER:-Administrator}"

DATA_DIR="/data"
CLAUDE_STATE="$DATA_DIR/claude-state"
WORKSPACE="$DATA_DIR/workspace"
GENERATED="$DATA_DIR/generated_images"

echo "=== ClaudeBlox Startup ==="

# ==============================================
# Volume Setup (persistent storage)
# ==============================================

echo "Setting up persistent storage..."

mkdir -p "$CLAUDE_STATE"
mkdir -p "$WORKSPACE"
mkdir -p "$GENERATED"

echo "Directories created in /data"

# ==============================================
# Copy workspace files
# ==============================================

echo "Copying CLAUDE.md to workspace/.claude/..."
mkdir -p "$WORKSPACE/.claude"
cp /app/workspace_claude.md "$WORKSPACE/.claude/CLAUDE.md"

# ==============================================
# Copy Claude Code agents (subagents)
# ==============================================

echo "Setting up agents..."

# User scope: ~/.claude/agents/
mkdir -p "$CLAUDE_STATE/agents"
if [ -d "/app/.claude/agents" ]; then
    cp -r /app/.claude/agents/* "$CLAUDE_STATE/agents/" 2>/dev/null || true
    echo "User agents copied: $(ls $CLAUDE_STATE/agents/ 2>/dev/null)"
fi

# Project scope: workspace/.claude/agents/
mkdir -p "$WORKSPACE/.claude/agents"
if [ -d "/app/.claude/agents" ]; then
    cp -r /app/.claude/agents/* "$WORKSPACE/.claude/agents/" 2>/dev/null || true
    echo "Project agents copied: $(ls $WORKSPACE/.claude/agents/ 2>/dev/null)"
fi

# ==============================================
# Copy Claude Code skills
# ==============================================

echo "Setting up skills..."

# User scope: ~/.claude/skills/
mkdir -p "$CLAUDE_STATE/skills"
if [ -d "/app/.claude/skills" ]; then
    cp -r /app/.claude/skills/* "$CLAUDE_STATE/skills/" 2>/dev/null || true
    echo "User skills copied: $(ls $CLAUDE_STATE/skills/ 2>/dev/null)"
fi

# Project scope: workspace/.claude/skills/
mkdir -p "$WORKSPACE/.claude/skills"
if [ -d "/app/.claude/skills" ]; then
    cp -r /app/.claude/skills/* "$WORKSPACE/.claude/skills/" 2>/dev/null || true
    echo "Project skills copied: $(ls $WORKSPACE/.claude/skills/ 2>/dev/null)"
fi

# ==============================================
# Symlinks
# ==============================================

if [ -d "/home/claude/.claude" ] && [ ! -L "/home/claude/.claude" ]; then
    rm -rf /home/claude/.claude
fi
if [ -d "/app/workspace" ] && [ ! -L "/app/workspace" ]; then
    rm -rf /app/workspace
fi

mkdir -p /home/claude
ln -sfn "$CLAUDE_STATE" /home/claude/.claude
ln -sfn "$WORKSPACE" /app/workspace

echo "Symlinks created:"
echo "  /home/claude/.claude -> $CLAUDE_STATE"
echo "  /app/workspace -> $WORKSPACE"

# ==============================================
# Credentials Setup
# ==============================================

if [ -n "$CLAUDE_CREDENTIALS" ]; then
    CREDS_FILE="$CLAUDE_STATE/.credentials.json"

    if [ ! -f "$CREDS_FILE" ] || [ ! -s "$CREDS_FILE" ]; then
        echo "Saving credentials from env to volume..."
        echo "$CLAUDE_CREDENTIALS" > "$CREDS_FILE"
    else
        echo "Credentials already exist in volume"
    fi
fi

# ==============================================
# Settings + MCP Config
# ==============================================

echo "Creating settings.json with MCP config..."
cat > "$CLAUDE_STATE/settings.json" << SETTINGSEOF
{
  "theme": "dark",
  "onboardingCompleted": true,
  "hasCompletedOnboarding": true,
  "permissions": {
    "allow": [
      "Bash",
      "Read",
      "Write",
      "Edit",
      "mcp__twitter__*",
      "mcp__gen__*",
      "*"
    ],
    "deny": []
  },
  "enableAllProjectMcpServers": true,
  "autoUpdaterStatus": "disabled",
  "mcpServers": {
    "twitter": {
      "command": "node",
      "args": ["/app/twitter_mcp.js"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}",
        "TWITTER_API_KEY": "${TWITTER_API_KEY}",
        "TWITTER_API_SECRET": "${TWITTER_API_SECRET}",
        "TWITTER_ACCESS_TOKEN": "${TWITTER_ACCESS_TOKEN}",
        "TWITTER_ACCESS_SECRET": "${TWITTER_ACCESS_SECRET}"
      }
    },
    "gen": {
      "command": "python3",
      "args": ["/app/gen_mcp.py"],
      "env": {
        "OPENROUTER_API_KEY": "${OPENROUTER_API_KEY}",
        "SUPABASE_URL": "${SUPABASE_URL}",
        "SUPABASE_KEY": "${SUPABASE_KEY}"
      }
    }
  }
}
SETTINGSEOF

# ==============================================
# Project MCP Config
# ==============================================

echo "Creating .claude.json for project MCP config..."
cat > "/home/claude/.claude.json" << 'CLAUDEJSONEOF'
{
  "projects": {
    "/data/workspace": {
      "mcpServers": {
        "twitter": {
          "type": "stdio",
          "command": "node",
          "args": ["/app/twitter_mcp.js"],
          "env": {}
        },
        "gen": {
          "type": "stdio",
          "command": "python3",
          "args": ["/app/gen_mcp.py"],
          "env": {}
        }
      }
    }
  }
}
CLAUDEJSONEOF
chown claude:claude /home/claude/.claude.json

# ==============================================
# Fix Permissions
# ==============================================

chown -R claude:claude "$DATA_DIR"
chown -R claude:claude /home/claude
chmod 600 "$CLAUDE_STATE/.credentials.json" 2>/dev/null || true

# ==============================================
# Status Check
# ==============================================

echo ""
echo "=== Volume Status ==="
echo "Claude state: $(ls -la $CLAUDE_STATE 2>/dev/null | wc -l) files"
echo "Workspace: $(ls -la $WORKSPACE 2>/dev/null | wc -l) files"
echo "Credentials: $([ -f $CLAUDE_STATE/.credentials.json ] && echo 'YES' || echo 'NO')"
echo "VPS Host: ${VPS_HOST:-NOT SET}"
echo ""

# ==============================================
# Replace PORT in nginx config
# ==============================================

sed -i "s/PORT_PLACEHOLDER/${PORT:-8080}/g" /app/nginx.conf

# ==============================================
# Start Services
# ==============================================

cat > /home/claude/.bashrc << 'EOF'
export HOME=/home/claude
export TERM=xterm-256color
cd /app/workspace
EOF
chown claude:claude /home/claude/.bashrc

# Start ttyd (web terminal)
echo "Starting ttyd..."
TTYD_AUTH=""
if [ -n "$ADMIN_TOKEN" ]; then
    TTYD_AUTH="-c admin:${ADMIN_TOKEN}"
    echo "Terminal protected with Basic Auth (user: admin)"
else
    echo "WARNING: Terminal not protected (ADMIN_TOKEN not set)"
fi

sudo -E -u claude bash -c "
    export HOME=/home/claude
    export DATABASE_URL='${DATABASE_URL:-}'
    export TWITTER_API_KEY='${TWITTER_API_KEY:-}'
    export TWITTER_API_SECRET='${TWITTER_API_SECRET:-}'
    export TWITTER_ACCESS_TOKEN='${TWITTER_ACCESS_TOKEN:-}'
    export TWITTER_ACCESS_SECRET='${TWITTER_ACCESS_SECRET:-}'
    export OPENROUTER_API_KEY='${OPENROUTER_API_KEY:-}'
    export SUPABASE_URL='${SUPABASE_URL:-}'
    export SUPABASE_KEY='${SUPABASE_KEY:-}'
    export VPS_HOST='${VPS_HOST:-}'
    export VPS_PASSWORD='${VPS_PASSWORD:-}'
    export VPS_USER='${VPS_USER:-Administrator}'
    ttyd -W -p 7681 ${TTYD_AUTH} bash --login
" &

# Start Flask API
echo "Starting API server..."
sudo -E -u claude bash -c "
    export HOME=/home/claude
    export DATABASE_URL='${DATABASE_URL:-}'
    export TWITTER_API_KEY='${TWITTER_API_KEY:-}'
    export TWITTER_API_SECRET='${TWITTER_API_SECRET:-}'
    export TWITTER_ACCESS_TOKEN='${TWITTER_ACCESS_TOKEN:-}'
    export TWITTER_ACCESS_SECRET='${TWITTER_ACCESS_SECRET:-}'
    export OPENROUTER_API_KEY='${OPENROUTER_API_KEY:-}'
    export SUPABASE_URL='${SUPABASE_URL:-}'
    export SUPABASE_KEY='${SUPABASE_KEY:-}'
    export ADMIN_TOKEN='${ADMIN_TOKEN:-}'
    export VPS_HOST='${VPS_HOST:-}'
    export VPS_PASSWORD='${VPS_PASSWORD:-}'
    export VPS_USER='${VPS_USER:-Administrator}'
    export CRON_TIME='${CRON_TIME:-0}'
    cd /app && gunicorn -b 127.0.0.1:5000 -w 1 --timeout 300 api:app
" &

sleep 2

# Start nginx
echo "Starting nginx on port ${PORT:-8080}..."
nginx -c /app/nginx.conf -g "daemon off;"
