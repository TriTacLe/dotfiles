#!/bin/bash
# Shared dotfiles library. Source this from any script that needs:
#   - DOTFILES_DIR resolution (env var > common locations)
#   - Per-person profile resolution and linking
#   - Color logger functions
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# DOTFILES_DIR resolution
# Priority:
#   1. $DOTFILES_DIR env var (if set and valid)
#   2. Search list of common clone locations

if [[ -z "${DOTFILES_DIR:-}" || ! -e "${DOTFILES_DIR:-}/.git" ]]; then
    for _path in \
        "$HOME/Desktop/dotfiles" \
        "$HOME/dotfiles" \
        "$HOME/.dotfiles" \
        "$HOME/Documents/dotfiles" \
        "$HOME/projects/dotfiles"; do
        if [[ -e "$_path/.git" ]]; then
            DOTFILES_DIR="$_path"
            break
        fi
    done
    unset _path
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

# Per-person profile. Selection order: DOTFILES_PROFILE env, ~/.dotfiles-profile,
# then the login name. profiles/example is the tracked template; real profiles
# are gitignored and stay on the machine.
DOTFILES_PROFILE="${DOTFILES_PROFILE:-}"
if [[ -z "$DOTFILES_PROFILE" && -r "$HOME/.dotfiles-profile" ]]; then
    DOTFILES_PROFILE="$(tr -d '[:space:]' <"$HOME/.dotfiles-profile")"
fi
DOTFILES_PROFILE="${DOTFILES_PROFILE:-${USER:-$(id -un)}}"
if [[ ! "$DOTFILES_PROFILE" =~ ^[A-Za-z0-9._-]+$ ]]; then
    err "invalid profile name '$DOTFILES_PROFILE'"
    return 1
fi
PROFILE_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/profiles/$DOTFILES_PROFILE}"
if [[ -r "$PROFILE_DIR/profile.env" ]]; then
    _profile_selection="$DOTFILES_PROFILE"
    _profile_dir="$PROFILE_DIR"
    set -a
    # shellcheck disable=SC1090
    source "$PROFILE_DIR/profile.env"
    set +a
    # The selection lives in ~/.dotfiles-profile, not in the profile itself.
    DOTFILES_PROFILE="$_profile_selection"
    PROFILE_DIR="$_profile_dir"
    unset _profile_selection _profile_dir
fi

# OS-aware packages dir: arch uses pacman, ubuntu/debian uses apt
if command -v pacman &>/dev/null; then
    PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/arch/packages}"
    PKG_MANAGER="pacman"
elif command -v apt &>/dev/null; then
    PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/ubuntu/packages}"
    PKG_MANAGER="apt"
fi

# Link a profile file into place. Real files are never clobbered.
link_profile_file() {
    local src="$1" dst="$2"
    [[ -e "$src" ]] || return 0
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        warn "$dst exists and is not a symlink, leaving it alone"
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    ok "$dst -> $src"
}

# Create the profile from profiles/example on first use, ask for the git
# identity, and link the local override files into place.
bootstrap_profile() {
    local dotfiles="$1"
    local example="$dotfiles/profiles/example"
    local created=0

    if [[ -z "${PROFILE_DIR:-}" ]]; then
        err "DOTFILES_DIR is not set, cannot resolve profile"
        return 1
    fi

    if [[ ! -d "$PROFILE_DIR" ]]; then
        if [[ ! -d "$example" ]]; then
            err "profile template missing at $example"
            return 1
        fi
        mkdir -p "$PROFILE_DIR"
        cp -R "$example/." "$PROFILE_DIR/"
        created=1
        log "created profile $DOTFILES_PROFILE at $PROFILE_DIR"
    fi

    local git_name git_email
    git_name="$(git config --file "$PROFILE_DIR/gitconfig.local" user.name 2>/dev/null || true)"
    git_email="$(git config --file "$PROFILE_DIR/gitconfig.local" user.email 2>/dev/null || true)"

    if command -v git &>/dev/null; then
        if [[ -t 0 && ( -z "$git_name" || "$git_name" == "Your Name" ) ]]; then
            read -r -p "Git name: " git_name
            [[ -n "$git_name" ]] && git config --file "$PROFILE_DIR/gitconfig.local" user.name "$git_name"
        fi
        if [[ -t 0 && ( -z "$git_email" || "$git_email" == "you@example.com" ) ]]; then
            read -r -p "Git email: " git_email
            [[ -n "$git_email" ]] && git config --file "$PROFILE_DIR/gitconfig.local" user.email "$git_email"
        fi
        if [[ -z "$git_name" || "$git_name" == "Your Name" || -z "$git_email" || "$git_email" == "you@example.com" ]]; then
            warn "git identity is incomplete in $PROFILE_DIR/gitconfig.local"
        fi
    else
        warn "git is not installed; edit $PROFILE_DIR/gitconfig.local manually"
    fi

    link_profile_file "$PROFILE_DIR/gitconfig.local" "$HOME/.gitconfig.local"
    link_profile_file "$PROFILE_DIR/zshrc.local" "$HOME/.zshrc.local"
    link_profile_file "$PROFILE_DIR/nvim.lua" "$HOME/.config/nvim/lua/config/local.lua"
    link_profile_file "$PROFILE_DIR/ghostty.conf" "$HOME/.config/ghostty/local"

    if [[ -e "$dotfiles/.env" && ! -L "$dotfiles/.env" ]]; then
        warn "$dotfiles/.env exists and is not a symlink, leaving it alone"
    else
        ln -sfn "$PROFILE_DIR/profile.env" "$dotfiles/.env"
        ok "$dotfiles/.env -> $PROFILE_DIR/profile.env"
    fi

    if [[ "$created" -eq 1 && ! -e "$HOME/.dotfiles-profile" ]]; then
        printf '%s\n' "$DOTFILES_PROFILE" >"$HOME/.dotfiles-profile"
    fi
    ok "profile $DOTFILES_PROFILE ready"
}

# Resolve the Claude config directory. A profile can point at an existing
# directory or at a repository to clone once. The bundled submodule is the
# fallback for this clone, but only when it actually contains a config.
resolve_claude_config() {
    local dotfiles="$1"

    if [[ -n "${CLAUDE_CONFIG_DIR:-}" ]]; then
        if [[ -d "$CLAUDE_CONFIG_DIR" ]]; then
            printf '%s\n' "$CLAUDE_CONFIG_DIR"
            return 0
        fi
        warn "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR does not exist"
    fi

    if [[ -n "${CLAUDE_CONFIG_REPO:-}" ]]; then
        local dest="${XDG_DATA_HOME:-$HOME/.local/share}/claude-config"
        if [[ ! -d "$dest/.git" ]]; then
            command -v git &>/dev/null || { err "git is required to clone $CLAUDE_CONFIG_REPO"; return 1; }
            mkdir -p "$(dirname "$dest")"
            git clone "$CLAUDE_CONFIG_REPO" "$dest" || return 1
        fi
        printf '%s\n' "$dest"
        return 0
    fi

    if [[ -f "$dotfiles/claude-config/settings.json" ]]; then
        printf '%s\n' "$dotfiles/claude-config"
        return 0
    fi
    return 1
}

# ~/.claude is one symlink to the resolved config, not a stow tree. Real
# directories are left alone, but still receive the profile's local overrides.
link_claude_config() {
    local dotfiles="$1"
    local target claude_dir

    target="$(resolve_claude_config "$dotfiles")" || {
        warn "no Claude config found; set CLAUDE_CONFIG_REPO or CLAUDE_CONFIG_DIR in $PROFILE_DIR/profile.env"
        return 0
    }

    if [[ "$target" == "$HOME/.claude" ]]; then
        claude_dir="$HOME/.claude"
    elif [[ -e "$HOME/.claude" ]]; then
        # An existing clone or symlink wins over the bundled fallback. This
        # keeps local Claude state and per-person checkouts intact.
        claude_dir="$HOME/.claude"
    else
        ln -sfn "$target" "$HOME/.claude"
        ok "$HOME/.claude -> $target"
        claude_dir="$HOME/.claude"
    fi

    link_profile_file "$PROFILE_DIR/CLAUDE.local.md" "$claude_dir/CLAUDE.local.md"
    link_profile_file "$PROFILE_DIR/settings.local.json" "$claude_dir/settings.local.json"
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
        if systemctl --user enable --now "$unit"; then
            ok "enabled $unit"
        else
            warn "could not enable $unit"
        fi
    done
}

# Settings (overridable via env)
MACHINE_TYPE="${MACHINE_TYPE:-auto}"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-master}"
AUTO_PUSH="${AUTO_PUSH:-true}"

export DOTFILES_DIR PACKAGES_DIR PKG_MANAGER MACHINE_TYPE GIT_REMOTE GIT_BRANCH AUTO_PUSH \
    DOTFILES_PROFILE PROFILE_DIR
