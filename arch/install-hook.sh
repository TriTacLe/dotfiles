#!/bin/bash
# Install pacman hook system-wide for Arch Linux.
# Resolves the dotfiles location from this script's path.

set -e

# Script lives at arch/install-hook.sh, repo root is one level up
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/shared/scripts/config.sh"

PKGTRACK="$DOTFILES_DIR/arch/scripts/pkgtrack.sh"
SYMLINK="/usr/local/bin/dotfiles-pkgtrack"
HOOK_SRC="$DOTFILES_DIR/arch/pacman-hook-autotrack.hook"
HOOK_DST="/usr/share/libalpm/hooks/20-dotfiles-autotrack.hook"

[[ -f "$PKGTRACK" ]]  || { err "$PKGTRACK not found"; exit 1; }
[[ -f "$HOOK_SRC" ]]  || { err "$HOOK_SRC not found"; exit 1; }

sudo ln -sf "$PKGTRACK" "$SYMLINK"
sudo chmod +x "$SYMLINK"
ok "symlink: $SYMLINK -> $PKGTRACK"

sudo install -m 644 "$HOOK_SRC" "$HOOK_DST"
ok "hook installed: $HOOK_DST"

echo ""
info "Auto-tracking is active. Test with: sudo pacman -S --needed hello"
info "Uninstall with: sudo rm $SYMLINK $HOOK_DST"
