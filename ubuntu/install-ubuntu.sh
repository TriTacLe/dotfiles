#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

# Ensure stow is installed
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    sudo apt-get install -y stow
fi

mkdir -p ~/.config

stow -d "$DOTFILES/shared/stow" -t ~ --no-folding \
    git nvim lazygit backgrounds zsh tmux alacritty ghostty kitty \
    hypr waybar swaync wofi avizo wob nwg-dock nwg-look wlogout scripts
stow -d "$DOTFILES/ubuntu/stow" -t ~ --no-folding \
    zsh rofi swaylock fontconfig zathura systemd hypr-host sway

stow -d "$DOTFILES" -t ~/.claude -R claude-config

echo "Ubuntu setup complete."
