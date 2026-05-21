#!/bin/bash
# One-shot: turn a fresh Arch box into a hardened server.
#
# Phase 1 — root setup (idempotent):
#   /srv, sshd hardening drop-in, logind lid policy, UFW with ssh + tailnet.
# Phase 2 — strip desktop packages (idempotent):
#   Hyprland / GUI / display manager / wayland tools / audio. Two passes of
#   orphan cleanup pick up transitive deps from Electron apps. Skips missing
#   packages, so a no-op on a fresh server install.
#
# Needs sudo. Safe to re-run.
# Usage: sudo bash bootstrap.sh

set -e

DOTFILES="$(cd "$(dirname "$0")/../.." && pwd)"

# ---------------------------------------------------------------------------
# Phase 1: root setup
# ---------------------------------------------------------------------------

echo "=== Phase 1: root setup ==="

# /srv directory for service slots
mkdir -p /srv
chmod 755 /srv
chown root:root /srv

# sshd hardening drop-in (copy, since /etc/ssh isn't a stow target)
install -m 0644 -o root -g root \
    "$DOTFILES/server/etc/ssh/sshd_config.d/99-hardening.conf" \
    /etc/ssh/sshd_config.d/99-hardening.conf
sshd -t  # validate before kicking the service
systemctl reload sshd

# Ignore lid switch so closing the laptop screen doesn't suspend the host
install -D -m 0644 -o root -g root \
    "$DOTFILES/server/etc/systemd/logind.conf.d/lid.conf" \
    /etc/systemd/logind.conf.d/lid.conf
systemctl restart systemd-logind

# UFW: install, set defaults, allow ssh + tailnet
if ! command -v ufw &>/dev/null; then
    pacman -S --needed --noconfirm ufw
fi
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'ssh'
ufw allow in on tailscale0 comment 'tailnet trusted'
# cloudflared is outbound-only so no inbound 80/443 needed. Open them
# manually if you ever switch to direct nginx+certbot exposure.
ufw --force enable
systemctl enable --now ufw

echo "  /srv, sshd, lid, UFW done"
echo

# ---------------------------------------------------------------------------
# Phase 2: strip desktop packages
# ---------------------------------------------------------------------------

echo "=== Phase 2: strip desktop packages ==="

# Lists grouped for review. Bluetooth + fastfetch intentionally kept.
HYPRLAND=(
    hyprland hyprcursor hyprgraphics hyprland-guiutils hyprlang hyprpaper
    hyprtoolkit hyprutils hyprwayland-scanner hyprwire
)

PANEL_LAUNCHER_NOTIFICATIONS=(
    waybar wofi swaync avizo avizo-debug
)

TERMINAL_EMULATORS=(
    alacritty
    ghostty ghostty-shell-integration ghostty-terminfo
    kitty kitty-shell-integration kitty-terminfo
)

GUI_APPS=(
    thunar firefox obsidian
)

DISPLAY_MANAGER=( sddm )

WAYLAND_TOOLS=(
    grim slurp
    xdg-desktop-portal xdg-desktop-portal-hyprland
)

FANCY_FETCH=( neofetch-git )

# Audio: handled in the orphan passes. pipewire is required by GUI apps
# (Obsidian, Firefox, qt6-multimedia, gst-plugin-pipewire, ffmpeg via
# jack, portaudio). Once those go, the audio stack becomes orphan and
# pacman -Qtdq catches it.

ALL=(
    "${HYPRLAND[@]}"
    "${PANEL_LAUNCHER_NOTIFICATIONS[@]}"
    "${TERMINAL_EMULATORS[@]}"
    "${GUI_APPS[@]}"
    "${DISPLAY_MANAGER[@]}"
    "${WAYLAND_TOOLS[@]}"
    "${FANCY_FETCH[@]}"
)

INSTALLED=()
for pkg in "${ALL[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        INSTALLED+=("$pkg")
    fi
done

if [ ${#INSTALLED[@]} -eq 0 ]; then
    echo "Pass 1: nothing to remove (fresh server, or already stripped)"
else
    echo "Pass 1: removing ${#INSTALLED[@]} package(s):"
    printf '  %s\n' "${INSTALLED[@]}"
    pacman -Rns --noconfirm "${INSTALLED[@]}"
fi

# Orphan passes — run twice in case pass 2 creates new transitive orphans.
for pass in 2 3; do
    ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
    if [ -n "$ORPHANS" ]; then
        echo
        echo "Pass $pass orphan cleanup:"
        echo "$ORPHANS" | sed 's/^/  /'
        echo "$ORPHANS" | pacman -Rns --noconfirm -
    else
        [ "$pass" = "2" ] && echo "(no orphans after pass 1)"
        break
    fi
done

echo
echo "Bootstrap complete. UFW status:"
ufw status verbose | head -10
