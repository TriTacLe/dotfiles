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
DOTFILES_PROFILE="${DOTFILES_PROFILE:-${USER:-$(id -un 2>/dev/null || true)}}"
# An unusable name leaves the profile unset instead of failing the source. The
# pacman hook sources this as root with no login name and must still run.
if [[ -n "$DOTFILES_PROFILE" && ! "$DOTFILES_PROFILE" =~ ^[A-Za-z0-9._-]+$ ]]; then
    err "invalid profile name '$DOTFILES_PROFILE', ignoring it"
    DOTFILES_PROFILE=""
fi
PROFILE_DIR=""
if [[ -n "$DOTFILES_PROFILE" && -n "${DOTFILES_DIR:-}" ]]; then
    PROFILE_DIR="$DOTFILES_DIR/profiles/$DOTFILES_PROFILE"
fi
if [[ -r "$PROFILE_DIR/profile.env" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$PROFILE_DIR/profile.env"
    set +a
fi

# OS-aware packages dir: arch uses pacman, ubuntu/debian uses apt.
# An explicit PKG_MANAGER wins over detection, which is how the tests reach the
# apt path from an Arch box. A profile can pin it the same way.
case "${PKG_MANAGER:-}" in
    pacman) PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/arch/packages}" ;;
    apt)    PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/ubuntu/packages}" ;;
    brew)   PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/macos}" ;;
    *)
        if command -v pacman &>/dev/null; then
            PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/arch/packages}"
            PKG_MANAGER="pacman"
        elif command -v apt &>/dev/null; then
            PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/ubuntu/packages}"
            PKG_MANAGER="apt"
        elif command -v brew &>/dev/null; then
            PACKAGES_DIR="${DOTFILES_DIR:+$DOTFILES_DIR/macos}"
            PKG_MANAGER="brew"
        else
            # Leaving these unset makes any set -u consumer die on an unbound variable
            PACKAGES_DIR=""
            PKG_MANAGER=""
        fi
        ;;
esac

# Stow refuses to link over a real file, which aborts the whole install on a
# machine that already has a ~/.zshrc. Dry-run the same stow command, move every
# conflicting target into a dated backup dir and say so. Takes the full stow
# argument list; nothing moves when the dry run is clean.
backup_conflicts() {
    local out backup p
    local -a paths
    out="$(stow -n "$@" 2>&1 || true)"
    # while-read instead of mapfile: macOS ships bash 3.2.
    paths=()
    while IFS= read -r p; do
        [[ -n "$p" ]] && paths+=("$p")
    done < <(printf '%s\n' "$out" \
        | sed -nE 's/.*over existing target ([^ ]+) since neither a link nor a directory.*/\1/p; s/.*existing target is not owned by stow: ([^ ]+).*/\1/p' \
        | sort -u)
    [[ ${#paths[@]} -eq 0 ]] && return 0
    # One dir per run, however many stow passes call this.
    : "${DOTFILES_BACKUP_DIR:=$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"
    backup="$DOTFILES_BACKUP_DIR"
    for p in "${paths[@]}"; do
        [[ -e "$HOME/$p" || -L "$HOME/$p" ]] || continue
        mkdir -p "$backup/$(dirname "$p")"
        mv "$HOME/$p" "$backup/$p"
        warn "moved existing $p to $backup/"
    done
}

# Package names from a manifest: one per line, # comments and blank lines skipped.
pkgs_from() { sed -e 's/#.*//' "$1" | awk 'NF { print $1 }'; }

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
    link_profile_file "$PROFILE_DIR/hypr.lua" "$HOME/.config/hypr/host_local.lua"

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

    if [[ -n "${DOTFILES_CLAUDE_DIR:-}" ]]; then
        if [[ -d "$DOTFILES_CLAUDE_DIR" ]]; then
            printf '%s\n' "$DOTFILES_CLAUDE_DIR"
            return 0
        fi
        warn "DOTFILES_CLAUDE_DIR=$DOTFILES_CLAUDE_DIR does not exist"
    fi

    if [[ -n "${DOTFILES_CLAUDE_REPO:-}" ]]; then
        local dest="${XDG_DATA_HOME:-$HOME/.local/share}/claude-config"
        if [[ ! -d "$dest/.git" ]]; then
            command -v git &>/dev/null || { err "git is required to clone $DOTFILES_CLAUDE_REPO"; return 1; }
            mkdir -p "$(dirname "$dest")"
            git clone "$DOTFILES_CLAUDE_REPO" "$dest" || return 1
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
        warn "no Claude config found; set DOTFILES_CLAUDE_REPO or DOTFILES_CLAUDE_DIR in ${PROFILE_DIR:-your profile}/profile.env"
        return 0
    }

    if [[ "$target" == "$HOME/.claude" ]]; then
        claude_dir="$HOME/.claude"
    elif [[ -d "$HOME/.claude" && ! -L "$HOME/.claude" ]]; then
        warn "$HOME/.claude is a real directory, leaving it alone"
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
