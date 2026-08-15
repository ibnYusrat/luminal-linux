#!/usr/bin/env bash
# Select an area on screen with slurp, capture with grim, copy to clipboard, and provide a notification option to save to file.

# Prevent running multiple instances simultaneously
if pidof slurp >/dev/null 2>&1; then
    exit 0
fi

# Run slurp for region selection:
# -b "00000060": slight dim on surrounding unselected areas
# -s "00000000": 100% transparent inside the selection box
# -c "9bd0cce6": crisp border matching theme primary color
# -d: display width x height dimensions
GEOMETRY=$(slurp -d -b "00000060" -c "9bd0cce6" -s "00000000" -w 2 2>/dev/null)

# If user made a selection (did not cancel with Esc)
if [ -n "$GEOMETRY" ]; then
    # Small buffer to ensure compositor has fully finished the fade animation
    sleep 0.15

    TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
    CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia/screenshots"
    mkdir -p "$CACHE_DIR"
    CACHE_FILE="$CACHE_DIR/screenshot_${TIMESTAMP}.png"

    # Capture to cache file and copy to clipboard
    grim -g "$GEOMETRY" "$CACHE_FILE"
    wl-copy --type image/png < "$CACHE_FILE"

    # Send notification with action button to save to Pictures/Screenshots
    ACTION=$(notify-send \
        -u low \
        -i "$CACHE_FILE" \
        -h "STRING:image-path:$CACHE_FILE" \
        --action=save="Save screenshot" \
        "Screenshot" \
        "Area copied to clipboard")

    if [ "$ACTION" = "save" ]; then
        SAVE_DIR="$HOME/Pictures/Screenshots"
        mkdir -p "$SAVE_DIR"
        FINAL_FILE="$SAVE_DIR/Screenshot_${TIMESTAMP}.png"
        cp "$CACHE_FILE" "$FINAL_FILE"
        notify-send -u low -i "$FINAL_FILE" "Screenshot Saved" "Saved to ~/Pictures/Screenshots/Screenshot_${TIMESTAMP}.png"
    fi
fi
