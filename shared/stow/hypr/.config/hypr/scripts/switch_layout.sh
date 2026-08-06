#!/bin/bash
set -euo pipefail

file="$HOME/.config/hypr/hyprland.lua"

if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
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
fi

hyprctl reload
