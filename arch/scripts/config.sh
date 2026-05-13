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

if [[ -z "$DOTFILES_DIR" || ! -d "$DOTFILES_DIR/.git" ]]; then
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

# In the unified layout, packages live under arch/packages/
PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/arch/packages}"

# Color logger
_dotfiles_color() {
    if [[ -n "$NO_COLOR" || ! -t 1 ]]; then
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

# Settings (overridable via env)
MACHINE_TYPE="${MACHINE_TYPE:-auto}"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-master}"
AUTO_PUSH="${AUTO_PUSH:-true}"

export DOTFILES_DIR PACKAGES_DIR MACHINE_TYPE GIT_REMOTE GIT_BRANCH AUTO_PUSH
