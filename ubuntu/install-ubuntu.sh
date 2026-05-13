#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p ~/.config

stow -d "$DOTFILES/shared/stow" -t ~ --no-folding git nvim starship lazygit backgrounds zsh
stow -d "$DOTFILES/ubuntu/stow" -t ~ --no-folding \
    zsh tmux alacritty ghostty rofi swaylock swaync wlogout fontconfig zathura

# Uncomment if claude-config is used on this machine:
# stow -d "$DOTFILES" -t ~/.claude -R claude-config

echo "Ubuntu setup complete."
