#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Init submodules (safe to run even if already done)
git -C "$DOTFILES" submodule update --init --recursive

# Role pin: write a single word to ~/.dotfiles-role to override the OS default
# (currently only "server" is recognized; everything else falls through).
ROLE=""
if [ -r "$HOME/.dotfiles-role" ]; then
    ROLE="$(tr -d '[:space:]' < "$HOME/.dotfiles-role")"
fi

OS=$(uname -s)
if [ "$OS" = "Darwin" ]; then
    bash "$DOTFILES/macos/install-macos.sh"
elif [ "$OS" = "Linux" ]; then
    DISTRO=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$DISTRO" in
        arch)
            if [ "$ROLE" = "server" ]; then
                bash "$DOTFILES/server/install-server.sh"
            else
                bash "$DOTFILES/arch/install-arch.sh"
            fi
            ;;
        ubuntu|debian)  bash "$DOTFILES/ubuntu/install-ubuntu.sh" ;;
        *)              echo "Unknown distro: $DISTRO"; exit 1 ;;
    esac
else
    echo "Unknown OS: $OS"; exit 1
fi
