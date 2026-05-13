#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

# Ensure stow is installed
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    sudo pacman -S --needed --noconfirm stow
fi

mkdir -p ~/.config ~/.claude

stow -d "$DOTFILES/shared/stow" -t ~ --no-folding \
    git nvim lazygit backgrounds zsh tmux alacritty ghostty kitty
stow -d "$DOTFILES/arch/stow" -t ~ --no-folding \
    zsh fastfetch \
    hypr waybar swaync wofi avizo wob nwg-dock nwg-look pacseek wlogout zathura systemd scripts
stow -d "$DOTFILES" -t ~/.claude -R claude-config

echo "Arch setup complete."
