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

link_claude_config "$DOTFILES"
enable_user_units battery-warning.timer log-gc.timer skill-gap.timer vault-reindex.timer vault-index.path

# /etc is not a stow target, so system tuning is copied in instead of linked.
install_system_configs() {
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/systemd/zram-generator.conf" \
        /etc/systemd/zram-generator.conf
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/systemd/oomd.conf.d/thresholds.conf" \
        /etc/systemd/oomd.conf.d/thresholds.conf

    # Never set ManagedOOMSwap on the root slice. With zram-only swap it trips
    # under normal load and kills the session scope holding the compositor.
    sudo rm -f /etc/systemd/system/-.slice.d/oomd.conf
    sudo rmdir /etc/systemd/system/-.slice.d 2>/dev/null || true

    # Disk tier below zram (pri 100) so cold pages spill instead of hitting OOM.
    if [ ! -f /home/swapfile ]; then
        sudo fallocate -l 16G /home/swapfile
        sudo chmod 600 /home/swapfile
        sudo mkswap /home/swapfile >/dev/null
    fi
    if ! grep -q '^/home/swapfile' /etc/fstab; then
        echo '/home/swapfile none swap defaults,pri=10 0 0' | sudo tee -a /etc/fstab >/dev/null
    fi
    sudo swapon /home/swapfile 2>/dev/null || true

    sudo systemctl daemon-reload
    sudo systemctl enable --now thermald
}

install_system_configs

echo "Arch setup complete."
