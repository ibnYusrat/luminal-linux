#!/bin/bash

# Socket path for mpv IPC (user-specific runtime directory)
IPC_SOCKET="${XDG_RUNTIME_DIR:-/tmp}/mpvsocket_${USER}"

# Classes of windows that do NOT pause the video wallpaper
# (If ONLY these classes are visible on the active workspace, the video keeps playing)
IGNORED_CLASSES=(
    "kitty"
    "foot"
    "ghostty"
    "alacritty"
    "wezterm"
    "st"
    "urxvt"
    "xterm"
    "rio"
    "rofi"
    "wofi"
    "fuzzel"
    "waybar"
    "nwg-dock-hyprland"
    "quickshell"
    "caelestia"
)

STATE="playing"
UNPAUSE_STREAK=0

while true; do
    # Check if socket exists; if not, wait
    if [ ! -e "$IPC_SOCKET" ]; then
        sleep 1
        continue
    fi

    # Check DPMS status (if screens are off, keep video wallpaper paused)
    DPMS_ON=$(hyprctl monitors -j 2>/dev/null | jq '[.[].dpmsStatus] | any' 2>/dev/null)

    if [ "$DPMS_ON" = "false" ]; then
        UNPAUSE_STREAK=0
        if [ "$STATE" != "paused" ]; then
            echo '{ "command": ["set_property", "pause", true] }' | socat - UNIX-CONNECT:"$IPC_SOCKET" > /dev/null 2>&1
            STATE="paused"
        fi
        sleep 0.5
        continue
    fi

    # Get active workspace ID
    ACTIVE_WS=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' 2>/dev/null)
    
    if [ -z "$ACTIVE_WS" ] || [ "$ACTIVE_WS" = "null" ]; then
        sleep 0.5
        continue
    fi

    # Construct the jq filter
    FILTER=".[] | select(.workspace.id == $ACTIVE_WS and .mapped == true and .hidden == false"
    for class in "${IGNORED_CLASSES[@]}"; do
        FILTER+=" and .class != \"$class\""
    done
    FILTER+=")"

    # Count blocking windows
    BLOCKING_COUNT=$(hyprctl clients -j 2>/dev/null | jq "[ $FILTER ] | length" 2>/dev/null)

    if [ -z "$BLOCKING_COUNT" ] || [ "$BLOCKING_COUNT" = "null" ]; then
        BLOCKING_COUNT=0
    fi

    if [ "$BLOCKING_COUNT" -gt 0 ]; then
        UNPAUSE_STREAK=0
        if [ "$STATE" != "paused" ]; then
            echo '{ "command": ["set_property", "pause", true] }' | socat - UNIX-CONNECT:"$IPC_SOCKET" > /dev/null 2>&1
            STATE="paused"
        fi
    else
        UNPAUSE_STREAK=$((UNPAUSE_STREAK + 1))
        if [ "$UNPAUSE_STREAK" -ge 2 ]; then
            if [ "$STATE" != "playing" ]; then
                echo '{ "command": ["set_property", "pause", false] }' | socat - UNIX-CONNECT:"$IPC_SOCKET" > /dev/null 2>&1
                STATE="playing"
            fi
        fi
    fi

    sleep 0.5
done
