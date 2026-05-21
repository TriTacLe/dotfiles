#!/bin/bash
# One-time root setup for the server profile:
#   - /srv exists (root:root, mode 755 — service subdirs created by svc-new.sh)
#   - sshd hardening drop-in is in place (mirrored from server/etc/)
#   - UFW installed, configured to allow ssh + tailscale, enabled
#   - fail2ban + ollama already handled by install-server.sh
#
# Needs sudo. Idempotent.
#
# Usage: sudo bash server-init.sh

set -e

DOTFILES="$(cd "$(dirname "$0")/../.." && pwd)"

# 1. /srv directory
mkdir -p /srv
chmod 755 /srv
chown root:root /srv

# 2. sshd hardening drop-in (copy, since /etc/ssh isn't a stow target)
install -m 0644 -o root -g root \
    "$DOTFILES/server/etc/ssh/sshd_config.d/99-hardening.conf" \
    /etc/ssh/sshd_config.d/99-hardening.conf
sshd -t  # validate config before kicking the service
systemctl reload sshd

# 2b. Ignore lid switch — closing the laptop screen must not suspend the host
install -D -m 0644 -o root -g root \
    "$DOTFILES/server/etc/systemd/logind.conf.d/lid.conf" \
    /etc/systemd/logind.conf.d/lid.conf
systemctl restart systemd-logind

# 3. UFW: install, set defaults, allow ssh from anywhere + everything on tailnet
if ! command -v ufw &>/dev/null; then
    pacman -S --needed --noconfirm ufw
fi
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'ssh'
ufw allow in on tailscale0 comment 'tailnet trusted'
# When you start serving public web traffic via cloudflared, NO inbound 80/443 is needed
# (cloudflared is outbound-only). Add these manually if you stop using cloudflared.
# ufw allow 80/tcp; ufw allow 443/tcp
ufw --force enable
systemctl enable --now ufw

echo
echo "Server init done."
echo "  /srv ready (mode 755, root:root)"
echo "  sshd hardening reloaded"
ufw status verbose | head -20
