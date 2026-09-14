#!/bin/bash
set -euo pipefail

file="$HOME/.config/hypr/input.lua"

if [[ ! -f "$file" ]]; then
    echo "File not found: $file" >&2
    exit 1
fi

# --follow-symlinks: the file is a stow symlink into the dotfiles repo. Without
# this, sed -i replaces the symlink with a regular file and detaches it from git.

if grep -q 'kb_layout = "us"' "$file"; then
    sed -i --follow-symlinks 's|kb_layout = "us"|kb_layout = "no"|' "$file"
    notify-send "Set keyboard layout to Norwegian"
    echo "Changed layout to no in $file"

elif grep -q 'kb_layout = "no"' "$file"; then
    sed -i --follow-symlinks 's|kb_layout = "no"|kb_layout = "us"|' "$file"
    notify-send "Set keyboard layout to American"
    echo "Changed layout to us in $file"

else
    # Fail loudly. The previous version pointed at hyprland.lua, which stopped
    # holding kb_layout when the config was split, and exited 0 changing nothing.
    echo "No kb_layout = \"us\" or \"no\" line in $file" >&2
    notify-send -u critical "Keyboard layout" "No kb_layout line found in input.lua"
    exit 1
fi

hyprctl reload
