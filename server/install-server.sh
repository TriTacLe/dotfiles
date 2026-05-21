#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    sudo pacman -S --needed --noconfirm stow
fi

# Base packages (pacman). AUR list is currently empty; install with paru/yay if it grows.
if [ -s "$DOTFILES/server/packages/packages.txt" ]; then
    mapfile -t SERVER_PKGS < <(grep -vE '^\s*(#|$)' "$DOTFILES/server/packages/packages.txt")
    if [ ${#SERVER_PKGS[@]} -gt 0 ]; then
        sudo pacman -S --needed --noconfirm "${SERVER_PKGS[@]}"
    fi
fi

mkdir -p ~/.config ~/.claude

# Server XDG layout: drop a user-dirs.dirs that aliases Desktop/Music/Videos/
# Pictures/Templates/Public all to $HOME so xdg-user-dirs-update doesn't
# recreate them. Headless server has no use for those directories.
install -D -m 0644 "$DOTFILES/server/etc/xdg/user-dirs.dirs" \
    ~/.config/user-dirs.dirs

# CLI-only stow: no hypr, waybar, alacritty, ghostty, kitty, swaync, etc.
stow -d "$DOTFILES/shared/stow" -t ~ --no-folding \
    git nvim lazygit zsh tmux scripts starship
stow -d "$DOTFILES/arch/stow" -t ~ --no-folding \
    zsh pacseek
stow -d "$DOTFILES" -t ~/.claude -R claude-config

# Server-specific stow packages (none yet, but ready when added).
if [ -d "$DOTFILES/server/stow" ] && [ -n "$(/bin/ls -A "$DOTFILES/server/stow" 2>/dev/null)" ]; then
    stow -d "$DOTFILES/server/stow" -t ~ --no-folding \
        $(/bin/ls "$DOTFILES/server/stow")
fi

# Pacman post-transaction hook that auto-commits package-list changes.
# Lives under arch/ since it's pacman-specific, but servers need it too.
bash "$DOTFILES/arch/install-hook.sh"

echo "Server setup complete."
