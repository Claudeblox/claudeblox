#!/bin/bash

PORT=${PORT:-8080}
echo "Railway PORT=$PORT"

# Patch nginx to listen on Railway's PORT instead of 80
sed -i "s/listen 80/listen $PORT/g" /etc/nginx/sites-enabled/default
sed -i "s/listen 443/listen $PORT/g" /etc/nginx/sites-enabled/default 2>/dev/null || true

echo "Nginx patched to listen on $PORT"

exec /startup.sh
