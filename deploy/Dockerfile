# ClaudeBlox - Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ==============================================
# System packages
# ==============================================
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    python3 \
    python3-pip \
    nginx \
    sudo \
    sshpass \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# ==============================================
# Node.js 20
# ==============================================
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ==============================================
# Claude Code
# ==============================================
RUN npm install -g @anthropic-ai/claude-code

# ==============================================
# ttyd for web terminal
# ==============================================
RUN wget -q https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -O /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# ==============================================
# Python packages
# ==============================================
RUN pip3 install flask gunicorn psycopg2-binary requests apscheduler

# ==============================================
# Create non-root user
# ==============================================
RUN useradd -m -s /bin/bash claude && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ==============================================
# Setup directories
# ==============================================
RUN mkdir -p /app /data && \
    chown -R claude:claude /app /data

WORKDIR /app

# Copy application files
COPY --chown=claude:claude api.py .
COPY --chown=claude:claude db.py .
COPY --chown=claude:claude gen_mcp.py .
COPY --chown=claude:claude twitter_mcp.js .
COPY --chown=claude:claude package.json .
COPY --chown=claude:claude nginx.conf .
COPY --chown=claude:claude start.sh .
COPY --chown=claude:claude workspace_claude.md .
COPY --chown=claude:claude .claude/ .claude/

# Install npm dependencies
RUN npm install

# Make scripts executable
RUN chmod +x start.sh twitter_mcp.js gen_mcp.py

# Nginx needs to write to some dirs
RUN mkdir -p /tmp/nginx && chown -R claude:claude /tmp/nginx
RUN touch /run/nginx.pid && chown claude:claude /run/nginx.pid

CMD ["./start.sh"]
