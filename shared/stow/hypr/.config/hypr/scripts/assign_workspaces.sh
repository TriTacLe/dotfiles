#!/bin/bash
# Assigns workspaces to monitors by physical position.
# Laptop always gets ws 1,4. Leftmost external gets ws 3, rightmost gets ws 2.
# Add more workspace assignments below as needed.

set -euo pipefail

LAPTOP="eDP-1"

assign() {
    # Old dispatcher name first, Lua expression as fallback. A Lua config rejects
    # the old name with exit 7, a hyprlang config rejects the Lua form.
    # Trailing || true: a monitor that vanished mid-run must not abort the rest.
    hyprctl dispatch moveworkspacetomonitor "$1" "$2" 2>/dev/null \
        || hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$1\", monitor = \"$2\" })" 2>/dev/null \
        || true
}

# Laptop workspaces
assign 1 "$LAPTOP"
assign 4 "$LAPTOP"

# External monitors sorted by x position: index 0 = leftmost, last = rightmost
mapfile -t externals < <(
    hyprctl monitors -j | jq -r --arg l "$LAPTOP" \
        '[.[] | select(.name != $l)] | sort_by(.x) | .[].name'
)

n=${#externals[@]}

if (( n >= 1 )); then
    assign 2 "${externals[0]}"   # leftmost
fi

if (( n >= 2 )); then
    assign 3 "${externals[$((n-1))]}"  # rightmost
fi
