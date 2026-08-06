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

stow -d "$DOTFILES/shared/stow" -t ~ --no-folding -R git nvim lazygit backgrounds zsh scripts ipython
stow -d "$DOTFILES/macos/stow" -t ~ --no-folding -R zsh tmux alacritty ghostty kitty neofetch starship
link_claude_config "$DOTFILES"

echo "Mac setup complete."
