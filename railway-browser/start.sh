#!/bin/bash

# Map Railway's PORT to Kasm's port
export KASM_PORT=${PORT:-6901}

echo "=== Starting Kasm Chrome on port $KASM_PORT ==="

# Run default Kasm entrypoint
exec /dockerstartup/kasm_default_profile.sh /dockerstartup/vnc_startup.sh
