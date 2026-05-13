#!/bin/bash
# Install APT hook system-wide for Ubuntu/Debian.
# Resolves the dotfiles location from this script's path.

set -e

# Script lives at ubuntu/install-hook.sh, repo root is one level up
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/shared/scripts/config.sh"

PKGTRACK="$DOTFILES_DIR/ubuntu/scripts/pkgtrack.sh"
SYMLINK="/usr/local/bin/dotfiles-pkgtrack-ubuntu"
HOOK_SRC="$DOTFILES_DIR/ubuntu/apt-hook-autotrack.conf"
HOOK_DST="/etc/apt/apt.conf.d/99dotfiles-autotrack"

[[ -f "$PKGTRACK" ]] || { err "$PKGTRACK not found"; exit 1; }
[[ -f "$HOOK_SRC" ]] || { err "$HOOK_SRC not found"; exit 1; }

chmod +x "$PKGTRACK"

sudo ln -sf "$PKGTRACK" "$SYMLINK"
sudo chmod +x "$SYMLINK"
ok "symlink: $SYMLINK -> $PKGTRACK"

sudo install -m 644 "$HOOK_SRC" "$HOOK_DST"
ok "hook installed: $HOOK_DST"

# Seed packages.txt if empty
if [[ ! -s "$PACKAGES_DIR/packages.txt" ]]; then
    mkdir -p "$PACKAGES_DIR"
    apt-mark showmanual | sort -u > "$PACKAGES_DIR/packages.txt"
    ok "seeded $PACKAGES_DIR/packages.txt ($(wc -l < "$PACKAGES_DIR/packages.txt") packages)"
fi

echo ""
info "Auto-tracking is active. Test with: sudo apt install --reinstall hello"
info "Uninstall with: sudo rm $SYMLINK $HOOK_DST"
