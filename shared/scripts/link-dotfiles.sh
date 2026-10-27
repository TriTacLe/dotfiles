#!/bin/bash
# Symlink manager for dotfiles
# Creates symlinks from dotfiles directory to home directory

set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
LinkFile="$DOTFILES/symlinks.txt"

if [ ! -f "$LinkFile" ]; then
    echo "No symlinks.txt found in dotfiles root"
    exit 1
fi

echo "Creating symlinks from $DOTFILES to $HOME..."

while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue

    # Parse line: "source destination"
    source_file="$(echo "$line" | cut -d' ' -f1)"
    dest_file="$(echo "$line" | cut -d' ' -f2)"

    # Expand ~ in destination
    dest_file="$(echo "$dest_file" | sed 's|^~|$HOME|')"

    # Create parent directory if needed
    mkdir -p "$(dirname "$dest_file")"

    # Remove existing file/symlink if it exists
    if [ -e "$dest_file" ] || [ -L "$dest_file" ]; then
        rm -f "$dest_file"
    fi

    # Create symlink
    ln -s "$source_file" "$dest_file"
    echo "  Linked: $dest_file -> $source_file"
done < "$LinkFile"

echo "Symlink creation complete."