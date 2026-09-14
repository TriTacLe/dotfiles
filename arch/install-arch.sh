#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
source "$DOTFILES/shared/scripts/config.sh"

# Ensure stow is installed
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    sudo pacman -S --needed --noconfirm stow
fi

command -v just >/dev/null || sudo pacman -S --needed --noconfirm just
just --justfile "$DOTFILES/justfile" stow arch

# Colours are generated rather than stowed, so a fresh clone has none until this
# runs. waybar, wofi and hyprlock all expect the generated file to exist.
THEME_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/current-theme"
"$HOME/.config/hypr/scripts/theme_apply.sh" \
    "$(cat "$THEME_STATE" 2>/dev/null || echo catppuccin-mocha)" --no-reload

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

    # Root is 46 GB and pacman downloads whole upgrades into its cache before
    # installing, so the cache lives on the big partition. sed rather than a
    # shipped file: pacman.conf also carries the repo list that reflector edits.
    sudo install -d -m 0755 -o root -g root /home/pacman-cache
    sudo sed -i 's|^#\?CacheDir *=.*|CacheDir    = /home/pacman-cache/|' /etc/pacman.conf
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/systemd/journald.conf.d/size.conf" \
        /etc/systemd/journald.conf.d/size.conf
    sudo systemctl restart systemd-journald

    sudo systemctl daemon-reload
    sudo systemctl enable --now thermald
}

install_system_configs

echo "Arch setup complete."
