#!/bin/bash
# Backup dotfiles script
# Creates a backup of dotfiles to a timestamped directory

set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$DOTFILES/backups/$(date +%Y%m%d%H%M%S)"
SOURCE_DIR="$HOME"

mkdir -p "$BACKUP_DIR"

echo "Backing up dotfiles to $BACKUP_DIR..."

# Common dotfiles to backup
for file in .zshrc .zshenv .gitconfig .gitignore_global .vimrc .config/nvim; do
    if [ -e "$SOURCE_DIR/$file" ]; then
        cp -r "$SOURCE_DIR/$file" "$BACKUP_DIR/"
        echo "  Backed up: $file"
    fi
done

# Stow-managed packages
if [ -d "$SOURCE_DIR/.config/nvim" ]; then
    cp -r "$SOURCE_DIR/.config/nvim" "$BACKUP_DIR/nvim"
    echo "  Backed up: nvim config"
fi

echo "Backup complete: $BACKUP_DIR"