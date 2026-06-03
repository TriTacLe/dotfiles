#!/bin/bash
# Package tracking for Ubuntu/Debian - regenerates packages.txt from apt-mark showmanual,
# then commits/pushes only if AUTO_PUSH=true (default).
# Invoked by /etc/apt/apt.conf.d/99dotfiles-autotrack via /usr/local/bin/dotfiles-pkgtrack-ubuntu symlink.

# Handle SUDO_USER (apt runs as root - rebase HOME so config.sh and git work)
if [[ -n "$SUDO_USER" ]]; then
    HOME="/home/$SUDO_USER"
elif [[ "$(id -u)" -eq 0 ]]; then
    _real_user=$(logname 2>/dev/null || true)
    if [[ -n "$_real_user" && "$_real_user" != "root" ]]; then
        HOME="/home/$_real_user"
        SUDO_USER="$_real_user"
    else
        echo "[pkgtrack] cannot determine real user, skipping" >&2
        exit 0
    fi
    unset _real_user
fi

# Source shared library
_self="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
_repo="$(cd "$(dirname "$_self")/../.." && pwd)"
source "$_repo/shared/scripts/config.sh"
unset _self _repo

[[ -z "$DOTFILES_DIR" ]] && { echo "[pkgtrack] dotfiles dir not found" >&2; exit 1; }
PACKAGES_FILE="$PACKAGES_DIR/packages.txt"

mkdir -p "$PACKAGES_DIR"

OLD_PACKAGES_FILE=$(mktemp)
cp "$PACKAGES_FILE" "$OLD_PACKAGES_FILE" 2>/dev/null || true

apt-mark showmanual 2>/dev/null | sort -u > "$PACKAGES_FILE"

NEW_PKGS=$(comm -13 <(sort "$OLD_PACKAGES_FILE") "$PACKAGES_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
REMOVED_PKGS=$(comm -23 <(sort "$OLD_PACKAGES_FILE") "$PACKAGES_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

rm -f "$OLD_PACKAGES_FILE"

if [[ -z "$NEW_PKGS" && -z "$REMOVED_PKGS" ]]; then
    exit 0
fi

NEW_COUNT=$(wc -l < "$PACKAGES_FILE")

[[ -n "$NEW_PKGS" ]] && echo "[+] New packages: $NEW_PKGS"
[[ -n "$REMOVED_PKGS" ]] && echo "[-] Removed packages: $REMOVED_PKGS"

cd "$DOTFILES_DIR" || exit 1

HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "unknown")
DATE=$(date '+%Y-%m-%d')
[[ -d /sys/class/power_supply/BAT* ]] && MACHINE="laptop" || MACHINE="desktop"

if [[ -n "$NEW_PKGS" && -n "$REMOVED_PKGS" ]]; then
    COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] APT +$NEW_PKGS | -$REMOVED_PKGS"
elif [[ -n "$NEW_PKGS" ]]; then
    COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] APT packages: $NEW_PKGS"
else
    COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] APT removed: $REMOVED_PKGS"
fi

echo "Committing package changes..."
echo "Total packages: $NEW_COUNT"
echo "Commit message: $COMMIT_MSG"

git_as_user() {
    if [[ -n "$SUDO_USER" ]]; then
        local _uid _sock="" _candidate
        _uid=$(id -u "$SUDO_USER" 2>/dev/null)
        for _candidate in \
            "${SSH_AUTH_SOCK:-}" \
            "/run/user/${_uid}/gcr/ssh" \
            "/run/user/${_uid}/keyring/ssh"; do
            if [[ -n "$_candidate" && -S "$_candidate" ]]; then
                _sock="$_candidate"
                break
            fi
        done
        if [[ -n "$_sock" ]]; then
            sudo -u "$SUDO_USER" SSH_AUTH_SOCK="$_sock" git "$@"
        else
            sudo -u "$SUDO_USER" git "$@"
        fi
    else
        git "$@"
    fi
}

git_as_user add ubuntu/packages/packages.txt
git_as_user diff --cached --quiet && { echo "[pkgtrack] file unchanged after add, skipping commit"; exit 0; }
if ! git_as_user commit -m "$COMMIT_MSG"; then
    echo "[pkgtrack] commit failed" >&2
    echo "[pkgtrack] $(date '+%Y-%m-%d %H:%M') commit failed: $COMMIT_MSG" >> "$DOTFILES_DIR/.pkgtrack.log"
    exit 1
fi

if [[ "$AUTO_PUSH" == "true" ]]; then
    if git_as_user push 2>/dev/null; then
        echo "Pushed successfully"
    else
        echo "[pkgtrack] push failed (offline or no remote) - committed locally"
    fi
else
    echo "[pkgtrack] AUTO_PUSH=false - committed locally, skipping push"
fi

exit 0
