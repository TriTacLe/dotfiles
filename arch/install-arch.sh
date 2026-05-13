#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p ~/.config ~/.claude

stow -d "$DOTFILES/shared/stow" -t ~ --no-folding git nvim starship lazygit backgrounds zsh
stow -d "$DOTFILES/arch/stow" -t ~ --no-folding \
    zsh tmux alacritty ghostty kitty fastfetch \
    hypr waybar swaync wofi avizo wob nwg-dock nwg-look pacseek wlogout zathura
stow -d "$DOTFILES" -t ~/.claude -R claude-config

echo "Arch setup complete."
