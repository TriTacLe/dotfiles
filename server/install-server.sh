#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
source "$DOTFILES/shared/scripts/config.sh"

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

mkdir -p ~/.config

# Server XDG layout: drop a user-dirs.dirs that aliases Desktop/Music/Videos/
# Pictures/Templates/Public all to $HOME so xdg-user-dirs-update doesn't
# recreate them. Headless server has no use for those directories.
install -D -m 0644 "$DOTFILES/server/etc/xdg/user-dirs.dirs" \
    ~/.config/user-dirs.dirs

# CLI-only stow: no hypr, waybar, alacritty, ghostty, kitty, swaync, etc.
stow -d "$DOTFILES/shared/stow" -t ~ --no-folding -R \
    git nvim lazygit zsh tmux scripts ipython
stow -d "$DOTFILES/arch/stow" -t ~ --no-folding -R \
    zsh pacseek
link_claude_config "$DOTFILES"

# Server-specific stow packages (none yet, but ready when added).
if [ -d "$DOTFILES/server/stow" ]; then
    mapfile -t SERVER_STOW < <(find "$DOTFILES/server/stow" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
    if [ ${#SERVER_STOW[@]} -gt 0 ]; then
        stow -d "$DOTFILES/server/stow" -t ~ --no-folding -R "${SERVER_STOW[@]}"
    fi
fi

# Pacman post-transaction hook that auto-commits package-list changes.
# Lives under arch/ since it's pacman-specific, but servers need it too.
bash "$DOTFILES/arch/install-hook.sh"

# Nginx vhosts: copy to /etc/nginx/sites-available, enable via symlinks
NGINX_SRC="$DOTFILES/server/etc/nginx/sites-available"
if [ -d "$NGINX_SRC" ] && [ -n "$(/bin/ls -A "$NGINX_SRC" 2>/dev/null)" ]; then
    sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    for conf in "$NGINX_SRC"/*; do
        name="$(basename "$conf")"
        sudo cp "$conf" "/etc/nginx/sites-available/$name"
        sudo ln -sf "/etc/nginx/sites-available/$name" "/etc/nginx/sites-enabled/$name"
    done
    # update include directive if still pointing to sites-available
    sudo sed -i 's|include /etc/nginx/sites-available/\*;|include /etc/nginx/sites-enabled/*;|' \
        /etc/nginx/nginx.conf 2>/dev/null || true
    sudo nginx -t && sudo systemctl reload nginx
    echo "Nginx vhosts deployed."
fi

echo "Server setup complete."
