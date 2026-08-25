#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
source "$DOTFILES/shared/scripts/config.sh"

# Ensure stow is installed
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    sudo pacman -S --needed --noconfirm stow
fi

mkdir -p ~/.config

# -R (restow) so renamed or deleted files do not leave stale links behind.
# --no-folding links every file individually, which makes -R necessary.
stow -d "$DOTFILES/shared/stow" -t ~ --no-folding -R \
    git nvim lazygit backgrounds zsh tmux alacritty ghostty kitty \
    hypr waybar swaync wofi avizo wob nwg-dock nwg-look wlogout scripts ipython zathura
stow -d "$DOTFILES/arch/stow" -t ~ --no-folding -R \
    zsh fastfetch hypr-host pacseek systemd

# Colours are generated rather than stowed, so a fresh clone has none until this
# runs. waybar, wofi and hyprlock all expect the generated file to exist.
THEME_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/current-theme"
"$HOME/.config/hypr/scripts/theme_apply.sh" \
    "$(cat "$THEME_STATE" 2>/dev/null || echo catppuccin-mocha)" --no-reload

link_claude_config "$DOTFILES"
enable_user_units battery-warning.timer log-gc.timer skill-gap.timer vault-reindex.timer vault-index.path

echo "Arch setup complete."
