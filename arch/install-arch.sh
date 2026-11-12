#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
source "$DOTFILES/shared/scripts/config.sh"

# Ensure stow is installed
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    sudo pacman -S --needed --noconfirm stow
fi

# Curated desktop manifest. --needed makes a re-run a no-op.
mapfile -t DESKTOP_PKGS < <(pkgs_from "$DOTFILES/arch/packages/desktop.txt")
sudo pacman -S --needed --noconfirm "${DESKTOP_PKGS[@]}"
AUR_HELPER=$(command -v paru || command -v yay || true)
if [ -n "$AUR_HELPER" ]; then
    mapfile -t AUR_PKGS < <(pkgs_from "$DOTFILES/arch/packages/aur-desktop.txt")
    "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"
else
    echo "No AUR helper (paru or yay), skipping arch/packages/aur-desktop.txt." >&2
fi

just --justfile "$DOTFILES/justfile" stow arch
bootstrap_profile "$DOTFILES"

# Colours are generated rather than stowed, so a fresh clone has none until this
# runs. waybar, wofi and hyprlock all expect the generated file to exist.
THEME_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/current-theme"
"$HOME/.config/hypr/scripts/theme_apply.sh" \
    "$(cat "$THEME_STATE" 2>/dev/null || echo catppuccin-mocha)" --no-reload

link_claude_config "$DOTFILES"
enable_user_units battery-warning.timer log-gc.timer
# These two run scripts from the Claude config, which is private and optional.
if [ -x "$HOME/.claude/scripts/skill-gap.sh" ]; then
    enable_user_units skill-gap.timer
fi
if systemctl --user cat claude-rag-index.service &>/dev/null; then
    enable_user_units vault-index.path
fi

# /etc is not a stow target, so system tuning is copied in instead of linked.
install_system_configs() {
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/systemd/zram-generator.conf" \
        /etc/systemd/zram-generator.conf
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/systemd/oomd.conf.d/thresholds.conf" \
        /etc/systemd/oomd.conf.d/thresholds.conf
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/systemd/system/cpu-tune.service" \
        /etc/systemd/system/cpu-tune.service
    # Everything that differs between AC and battery. A drop-in rather than an
    # edited tlp.conf so pacman upgrades of the package cannot clobber it.
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/tlp.d/01-power.conf" \
        /etc/tlp.d/01-power.conf
    # Card reader and wifi PSM. Takes effect on the next load of each module,
    # so in practice at the next reboot.
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/modprobe.d/power.conf" \
        /etc/modprobe.d/power.conf
    # Dims the panel when the charger comes out. Needs a reload to take effect
    # without a reboot; the rule only fires on the next AC transition either way.
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/udev/rules.d/90-backlight-on-power.rules" \
        /etc/udev/rules.d/90-backlight-on-power.rules
    sudo udevadm control --reload-rules
    # Follows the laptop across continents: resolves the public IP to a timezone
    # on every NetworkManager connect and sets it only when it differs.
    sudo install -D -m 0755 -o root -g root \
        "$DOTFILES/arch/etc/NetworkManager/dispatcher.d/90-timezone" \
        /etc/NetworkManager/dispatcher.d/90-timezone
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/tmpfiles.d/mglru.conf" \
        /etc/tmpfiles.d/mglru.conf
    sudo systemd-tmpfiles --create /etc/tmpfiles.d/mglru.conf

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

    # Weekly mirror refresh. reflector owns this path, so writing it before the
    # package is installed makes pacman abort the whole transaction on a file
    # conflict. -b keeps a copy of whatever was there.
    sudo install -D -b -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/xdg/reflector/reflector.conf" \
        /etc/xdg/reflector/reflector.conf

    # Cap coredumps. The default is 10 percent of the filesystem, which on a
    # 46 GB root let 1.4 GB pile up unnoticed.
    sudo install -D -m 0644 -o root -g root \
        "$DOTFILES/arch/etc/systemd/coredump.conf.d/size.conf" \
        /etc/systemd/coredump.conf.d/size.conf

    sudo systemctl daemon-reload
    # daemon-reload re-runs the zram generator; the device still has to be started.
    sudo systemctl start systemd-zram-setup@zram0.service
    sudo systemctl enable --now thermald tlp cpu-tune reflector.timer paccache.timer
}

if [ "${1:-}" = "--system" ]; then
    # reflector and pacman-contrib own the timers enabled above; thermald, tlp
    # and zram-generator are the tuning itself.
    sudo pacman -S --needed --noconfirm reflector pacman-contrib thermald tlp zram-generator
    install_system_configs
else
    echo "Skipped system tuning (swapfile, pacman cache, /etc drop-ins). Re-run with --system to apply it."
fi

echo "Arch setup complete."
