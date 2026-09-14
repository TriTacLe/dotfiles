#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
source "$DOTFILES/shared/scripts/config.sh"

# Refresh the index first: a stale one makes every apt-get install below 404.
sudo apt-get update

# Ensure stow is installed
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    sudo apt-get install -y stow
fi

mkdir -p ~/.config

command -v just >/dev/null || sudo apt-get install -y just
just --justfile "$DOTFILES/justfile" stow ubuntu

link_claude_config "$DOTFILES"

echo "Ubuntu setup complete."
