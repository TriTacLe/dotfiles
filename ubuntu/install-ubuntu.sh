#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

# Ensure stow is installed
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    sudo apt-get install -y stow
fi

mkdir -p ~/.config

stow -d "$DOTFILES/shared/stow" -t ~ --no-folding git nvim starship lazygit backgrounds zsh
stow -d "$DOTFILES/ubuntu/stow" -t ~ --no-folding \
    zsh tmux alacritty ghostty kitty rofi swaylock swaync wlogout fontconfig zathura systemd

stow -d "$DOTFILES" -t ~/.claude -R claude-config

echo "Ubuntu setup complete."
