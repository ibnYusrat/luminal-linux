#!/usr/bin/env bash
set -uo pipefail

# Configuration
IPC_SOCKET="${XDG_RUNTIME_DIR:-/tmp}/mpvsocket_${USER}"
MPV_OPTS="--loop --no-audio --hwdec=auto --input-ipc-server=$IPC_SOCKET"
STATE_FILE="$HOME/.config/hypr/.wallpaper_state"
WALLPAPER_FILE_CONF="$HOME/.config/hypr/.wallpaper_file"
DEFAULT_WALLPAPER="$HOME/Pictures/Wallpapers/ni2op3398zgh1.png"
DEFAULT_VIDEO="$HOME/Pictures/Wallpapers/live_wallpaper.mp4"

# Ensure directories exist
mkdir -p "$HOME/.config/hypr"
mkdir -p "$HOME/Pictures/Wallpapers"

TARGET_FILE=""
MODE=""

# Parse arguments flexibly (mode numbers or file paths)
for arg in "$@"; do
    if [[ "$arg" =~ ^[1-3]$ ]]; then
        MODE="$arg"
    elif [ -f "$arg" ]; then
        TARGET_FILE="$arg"
    fi
done

# If no target file passed, read from saved config or use default
if [ -z "$TARGET_FILE" ]; then
    if [ -f "$WALLPAPER_FILE_CONF" ]; then
        SAVED=$(cat "$WALLPAPER_FILE_CONF")
        if [ -f "$SAVED" ]; then
            TARGET_FILE="$SAVED"
        fi
    fi
fi

# Fallback to default wallpaper if still empty
if [ -z "$TARGET_FILE" ] || [ ! -f "$TARGET_FILE" ]; then
    if [ -f "$DEFAULT_WALLPAPER" ]; then
        TARGET_FILE="$DEFAULT_WALLPAPER"
    elif [ -f "$DEFAULT_VIDEO" ]; then
        TARGET_FILE="$DEFAULT_VIDEO"
    else
        # Find first image/video in directory
        TARGET_FILE=$(find "$HOME/Pictures/Wallpapers" /usr/share/backgrounds/distro -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.mp4" \) 2>/dev/null | head -n 1 || true)
    fi
fi

if [ -z "$TARGET_FILE" ] || [ ! -f "$TARGET_FILE" ]; then
    echo "❌ No valid wallpaper file found."
    exit 1
fi

# Save active wallpaper file path
echo "$TARGET_FILE" > "$WALLPAPER_FILE_CONF"

# Detect file mime type
MIME_TYPE=$(file --mime-type -b "$TARGET_FILE" 2>/dev/null || echo "")

# --- 1. HANDLE STATIC IMAGES ---
if [[ "$MIME_TYPE" =~ image/ ]] || [[ "$TARGET_FILE" =~ \.(png|jpg|jpeg|webp|bmp)$ ]]; then
    echo "==> Applying static wallpaper via Caelestia: $TARGET_FILE"
    
    # Terminate video wallpaper daemons
    pkill -u "$USER" -f "smart_pause.sh" 2>/dev/null || true
    pkill -u "$USER" -x mpvpaper 2>/dev/null || true
    rm -f "$IPC_SOCKET"

    # Set wallpaper and trigger Material You color regeneration
    if command -v caelestia &>/dev/null; then
        caelestia wallpaper -f "$TARGET_FILE" 2>/dev/null || true
    elif command -v swww &>/dev/null; then
        swww img "$TARGET_FILE" 2>/dev/null || true
    elif command -v hyprpaper &>/dev/null; then
        pkill -u "$USER" -x hyprpaper 2>/dev/null || true
        hyprpaper &
    fi

    if command -v notify-send &>/dev/null; then
        notify-send "Wallpaper Updated" "Static: $(basename "$TARGET_FILE")" -i preferences-desktop-wallpaper -t 2500
    fi
    exit 0
fi

# --- 2. HANDLE LIVE VIDEO WALLPAPERS ---
if [[ "$MIME_TYPE" =~ video/ ]] || [[ "$TARGET_FILE" =~ \.(mp4|mkv|webm|mov|avi)$ ]]; then
    echo "==> Applying live video wallpaper via mpvpaper: $TARGET_FILE"
    MODE="${MODE:-2}" # Default to Smart Mode (2)

    # Cleanup existing wallpaper daemons
    pkill -u "$USER" -f "smart_pause.sh" 2>/dev/null || true
    pkill -u "$USER" -x mpvpaper 2>/dev/null || true
    rm -f "$IPC_SOCKET"
    sleep 0.2

    # Detect monitor
    MONITOR=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name // "*"' 2>/dev/null)
    MONITOR="${MONITOR:-*}"

    case "$MODE" in
        1)
            # Always Playing
            nohup mpvpaper -l background -o "$MPV_OPTS" "$MONITOR" "$TARGET_FILE" >/dev/null 2>&1 &
            ;;
        2)
            # Smart Mode (Auto-pause when windows obscure)
            nohup mpvpaper -l background -o "$MPV_OPTS" "$MONITOR" "$TARGET_FILE" >/dev/null 2>&1 &
            sleep 0.8
            nohup "$HOME/.config/hypr/smart_pause.sh" >/dev/null 2>&1 &
            ;;
        3)
            # Paused
            nohup mpvpaper -l background -o "$MPV_OPTS --pause" "$MONITOR" "$TARGET_FILE" >/dev/null 2>&1 &
            ;;
    esac

    if command -v notify-send &>/dev/null; then
        notify-send "Live Wallpaper Applied" "File: $(basename "$TARGET_FILE")" -i preferences-desktop-wallpaper -t 2500
    fi
    exit 0
fi
