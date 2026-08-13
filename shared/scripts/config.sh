#!/bin/bash
# Shared dotfiles library. Source this from any script that needs:
#   - DOTFILES_DIR resolution (env var > common locations)
#   - Color logger functions
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# DOTFILES_DIR resolution
# Priority:
#   1. $DOTFILES_DIR env var (if set and valid)
#   2. Search list of common clone locations

if [[ -z "${DOTFILES_DIR:-}" || ! -d "${DOTFILES_DIR:-}/.git" ]]; then
    for _path in \
        "$HOME/Desktop/dotfiles" \
        "$HOME/dotfiles" \
        "$HOME/.dotfiles" \
        "$HOME/Documents/dotfiles" \
        "$HOME/projects/dotfiles"; do
        if [[ -d "$_path/.git" ]]; then
            DOTFILES_DIR="$_path"
            break
        fi
    done
    unset _path
fi

# OS-aware packages dir: arch uses pacman, ubuntu/debian uses apt
if command -v pacman &>/dev/null; then
    PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/arch/packages}"
    PKG_MANAGER="pacman"
elif command -v apt &>/dev/null; then
    PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/ubuntu/packages}"
    PKG_MANAGER="apt"
fi

# Color logger
_dotfiles_color() {
    if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
        printf "%s" "$2"
    else
        printf "\033[%sm%s\033[0m" "$1" "$2"
    fi
}

log()   { echo "$(_dotfiles_color '0;34' '[install]') $*"; }
ok()    { echo "$(_dotfiles_color '0;32' '[ok]') $*"; }
warn()  { echo "$(_dotfiles_color '1;33' '[warn]') $*"; }
err()   { echo "$(_dotfiles_color '0;31' '[error]') $*" >&2; }
info()  { echo "$(_dotfiles_color '0;36' '[info]') $*"; }

# ~/.claude is one symlink to the claude-config submodule, not a stow tree.
# Stowing into it would resolve the target back inside the package itself.
link_claude_config() {
    local dotfiles="$1"
    if [[ -d "$HOME/.claude" && ! -L "$HOME/.claude" ]]; then
        warn "$HOME/.claude is a real directory, leaving it alone"
        return 0
    fi
    ln -sfn "$dotfiles/claude-config" "$HOME/.claude"
    ok "$HOME/.claude -> $dotfiles/claude-config"
}

# Stow only links units into ~/.config/systemd/user; they stay inactive until enabled.
enable_user_units() {
    if ! systemctl --user show-environment &>/dev/null; then
        warn "no user systemd session, skipping unit enable"
        return 0
    fi
    systemctl --user daemon-reload
    local unit
    for unit in "$@"; do
        systemctl --user enable --now "$unit" && ok "enabled $unit"
    done
}

# Settings (overridable via env)
MACHINE_TYPE="${MACHINE_TYPE:-auto}"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-master}"
AUTO_PUSH="${AUTO_PUSH:-true}"

export DOTFILES_DIR PACKAGES_DIR PKG_MANAGER MACHINE_TYPE GIT_REMOTE GIT_BRANCH AUTO_PUSH
