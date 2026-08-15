#!/bin/bash
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/mpv_pause.log"
SOCKET="${XDG_RUNTIME_DIR:-/tmp}/mpvsocket_${USER}"

echo "=== Watcher started at $(date) ===" > "$LOG_FILE"
LAST_STATE=""

while true; do
    if [ -e "$SOCKET" ]; then
        STATE=$(echo '{ "command": ["get_property", "pause"] }' | socat - UNIX-CONNECT:"$SOCKET" 2>/dev/null | jq -r '.data' 2>/dev/null)
        if [ "$STATE" != "$LAST_STATE" ] && [ -n "$STATE" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] mpvpaper pause state: $STATE" >> "$LOG_FILE"
            LAST_STATE="$STATE"
        fi
    fi
    sleep 0.5
done
