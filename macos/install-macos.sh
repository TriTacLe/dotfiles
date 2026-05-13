#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

# Homebrew
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle install --file="$DOTFILES/macos/Brewfile" --no-lock

mkdir -p ~/.config ~/.claude

stow -d "$DOTFILES/shared/stow" -t ~ --no-folding git nvim starship lazygit backgrounds zsh
stow -d "$DOTFILES/macos/stow" -t ~ --no-folding zsh tmux alacritty ghostty kitty neofetch
stow -d "$DOTFILES" -t ~/.claude -R claude-config

echo "Mac setup complete."
