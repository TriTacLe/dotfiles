#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

OS=$(uname -s)
if [ "$OS" = "Darwin" ]; then
    bash "$DOTFILES/macos/install-macos.sh"
elif [ "$OS" = "Linux" ]; then
    DISTRO=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$DISTRO" in
        arch)           bash "$DOTFILES/arch/install-arch.sh" ;;
        ubuntu|debian)  bash "$DOTFILES/ubuntu/install-ubuntu.sh" ;;
        *)              echo "Unknown distro: $DISTRO"; exit 1 ;;
    esac
else
    echo "Unknown OS: $OS"; exit 1
fi
