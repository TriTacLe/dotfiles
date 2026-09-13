#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
source "$DOTFILES/shared/scripts/config.sh"

# Homebrew
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle install --file="$DOTFILES/macos/Brewfile" --no-lock

mkdir -p ~/.config

just --justfile "$DOTFILES/justfile" stow macos
link_claude_config "$DOTFILES"

echo "Mac setup complete."
