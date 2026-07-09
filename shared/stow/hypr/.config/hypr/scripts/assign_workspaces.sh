#!/bin/bash
# Assigns workspaces to monitors by physical position.
# Laptop always gets ws 1,4. Leftmost external gets ws 3, rightmost gets ws 2.
# Add more workspace assignments below as needed.

LAPTOP="eDP-1"

assign() {
    hyprctl dispatch moveworkspacetomonitor "$1" "$2" 2>/dev/null
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
