#!/bin/bash
set -euo pipefail
# Elegant confirmation before closing window

WINDOW_CLASS=$(hyprctl activewindow -j | jq -r '.class')
WINDOW_TITLE=$(hyprctl activewindow -j | jq -r '.title' | cut -c1-40)

# If empty, use class name
if [ -z "$WINDOW_TITLE" ] || [ "$WINDOW_TITLE" = "null" ]; then
    WINDOW_TITLE="$WINDOW_CLASS"
fi

# Red dialog. Destructive actions must not look like the launcher.
CHOICE=$(printf '%s\n' "Close $WINDOW_TITLE" "Keep it open" | wofi \
    --dmenu \
    --prompt "Close this window?" \
    --style ~/.config/wofi/confirm.css \
    --width 460 \
    --height 210 \
    --lines 2 \
    --cache-file /dev/null \
    --insensitive \
    --matching fuzzy)

if [[ "$CHOICE" == *"Close"* ]]; then
    # Lua configs expect a Lua expression here and exit 7 on the old name.
    # Old form first so the script keeps working on a hyprlang config too.
    hyprctl dispatch killactive || hyprctl dispatch 'hl.dsp.window.close()'
fi
