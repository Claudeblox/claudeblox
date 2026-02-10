#!/bin/bash

# Railway provides PORT, noVNC uses HTTP_PORT
export HTTP_PORT=${PORT:-80}

echo "Starting noVNC on HTTP_PORT=$HTTP_PORT"
exec /startup.sh
