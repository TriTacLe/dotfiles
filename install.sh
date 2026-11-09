#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# The claude-config submodule is Tri's config and may not be reachable from
# another account. A profile can point at its own repository instead, so a
# failed submodule fetch must not stop the install.
if ! git -C "$DOTFILES" submodule update --init --recursive; then
    echo "warning: could not initialize claude-config submodule" >&2
    echo "Set CLAUDE_CONFIG_REPO or CLAUDE_CONFIG_DIR in your profile to use your own Claude config." >&2
fi

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
    DISTRO=$(grep ^ID= /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
    # No pipefail here, so an unreadable or ID-less os-release yields an empty
    # DISTRO rather than an error. Say which it was.
    if [ -z "$DISTRO" ]; then
        echo "Could not read ID= from /etc/os-release" >&2; exit 1
    fi
    case "$DISTRO" in
        arch)
            if [ "$ROLE" = "server" ]; then
                bash "$DOTFILES/server/install-server.sh"
            else
                bash "$DOTFILES/arch/install-arch.sh"
            fi
            ;;
        ubuntu|debian)
            # The role pin used to be read on the arch branch only, so a pinned
            # server here silently got the full desktop stow set instead.
            if [ "$ROLE" = "server" ]; then
                echo "Role 'server' is only implemented for Arch." >&2
                echo "Remove ~/.dotfiles-role to install the $DISTRO desktop set." >&2
                exit 1
            fi
            bash "$DOTFILES/ubuntu/install-ubuntu.sh"
            ;;
        *)              echo "Unknown distro: $DISTRO" >&2; exit 1 ;;
    esac
else
    echo "Unknown OS: $OS"; exit 1
fi
