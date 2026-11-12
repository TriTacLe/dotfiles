#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
# config.sh otherwise searches a few home paths for the clone; this works anywhere.
export DOTFILES_DIR="$DOTFILES"
source "$DOTFILES/shared/scripts/config.sh"

# Homebrew
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle install --file="$DOTFILES/macos/Brewfile" --no-lock

mkdir -p ~/.config

just --justfile "$DOTFILES/justfile" stow macos
bootstrap_profile "$DOTFILES"
link_claude_config "$DOTFILES"

echo "Mac setup complete."
