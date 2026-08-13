#!/bin/bash
# Package tracking - regenerates packages.txt + aur.txt from pacman -Qqe,
# then commits/pushes only if AUTO_PUSH=true (default).
# Invoked by /usr/share/libalpm/hooks/20-dotfiles-autotrack.hook
# via the /usr/local/bin/dotfiles-pkgtrack symlink.

# No -e on purpose: pacman -Qqme with no AUR packages and git diff --cached --quiet
# both return nonzero as normal control flow further down.
set -uo pipefail

# Handle SUDO_USER (pacman runs as root - rebase HOME so config.sh and git work)
if [[ -n "${SUDO_USER:-}" ]]; then
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

[[ -z "${DOTFILES_DIR:-}" ]] && { echo "[pkgtrack] dotfiles dir not found" >&2; exit 1; }
PACKAGES_FILE="$PACKAGES_DIR/packages.txt"
AUR_FILE="$PACKAGES_DIR/aur.txt"

OLD_PACKAGES_FILE=$(mktemp)
cp "$PACKAGES_FILE" "$OLD_PACKAGES_FILE" 2>/dev/null || true

OLD_AUR_FILE=$(mktemp)
cp "$AUR_FILE" "$OLD_AUR_FILE" 2>/dev/null || true

AUR_PACKAGES=$(pacman -Qqme | sort)
ALL_PACKAGES=$(pacman -Qqe | sort)
OFFICIAL_PACKAGES=$(comm -23 <(echo "$ALL_PACKAGES") <(echo "$AUR_PACKAGES"))

echo "$OFFICIAL_PACKAGES" > "$PACKAGES_FILE"
echo "$AUR_PACKAGES" > "$AUR_FILE"

NEW_PKGS=$(comm -13 <(sort "$OLD_PACKAGES_FILE") "$PACKAGES_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
NEW_AUR=$(comm -13 <(sort "$OLD_AUR_FILE") "$AUR_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
DEL_PKGS=$(comm -23 <(sort "$OLD_PACKAGES_FILE") "$PACKAGES_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
DEL_AUR=$(comm -23 <(sort "$OLD_AUR_FILE") "$AUR_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

rm -f "$OLD_PACKAGES_FILE" "$OLD_AUR_FILE"

NEW_COUNT=$(wc -l < "$PACKAGES_FILE")
AUR_COUNT=$(wc -l < "$AUR_FILE" 2>/dev/null || echo "0")

[[ -n "$NEW_PKGS" ]] && echo "[+] New official packages: $NEW_PKGS" || NEW_PKGS="none"
[[ -n "$NEW_AUR" ]] && echo "[+] New AUR packages: $NEW_AUR" || NEW_AUR="none"
[[ -n "$DEL_PKGS" ]] && echo "[-] Removed official packages: $DEL_PKGS" || DEL_PKGS="none"
[[ -n "$DEL_AUR" ]] && echo "[-] Removed AUR packages: $DEL_AUR" || DEL_AUR="none"

cd "$DOTFILES_DIR" || exit 1

HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "unknown")
DATE=$(date '+%Y-%m-%d')
MACHINE="desktop"
for bat in /sys/class/power_supply/BAT*; do
    [[ -d "$bat" ]] && { MACHINE="laptop"; break; }
done

if [[ "$NEW_PKGS" == "none" && "$NEW_AUR" == "none" && "$DEL_PKGS" == "none" && "$DEL_AUR" == "none" ]]; then
    exit 0
fi

# A single pacman -Rns can touch 100+ packages, so keep the subject readable
summarize() {
    local n
    n=$(wc -w <<< "$1")
    if (( n > 5 )); then
        echo "$(cut -d' ' -f1-5 <<< "$1") and $((n - 5)) more"
    else
        echo "$1"
    fi
}

parts=()
[[ "$NEW_PKGS" != "none" ]] && parts+=("+$(summarize "$NEW_PKGS")")
[[ "$NEW_AUR" != "none" ]] && parts+=("+AUR $(summarize "$NEW_AUR")")
[[ "$DEL_PKGS" != "none" ]] && parts+=("-$(summarize "$DEL_PKGS")")
[[ "$DEL_AUR" != "none" ]] && parts+=("-AUR $(summarize "$DEL_AUR")")

COMMIT_MSG="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] $(IFS='|'; echo "${parts[*]}")"

echo "Committing package changes..."
echo "Official packages: $NEW_COUNT"
echo "AUR packages: $AUR_COUNT"
echo "Commit message: $COMMIT_MSG"

git_as_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$SUDO_USER" git "$@"
    else
        git "$@"
    fi
}

git_as_user add arch/packages/packages.txt arch/packages/aur.txt
git_as_user diff --cached --quiet && { echo "[pkgtrack] files unchanged after add, skipping commit"; exit 0; }
if ! git_as_user commit -m "$COMMIT_MSG" -- arch/packages/packages.txt arch/packages/aur.txt; then
    echo "[pkgtrack] commit failed" >&2
    echo "[pkgtrack] $(date '+%Y-%m-%d %H:%M') commit failed: $COMMIT_MSG" >> "$DOTFILES_DIR/.pkgtrack.log"
    exit 1
fi

if [[ "$AUTO_PUSH" == "true" ]]; then
    git_as_user pull --rebase 2>/dev/null || true
    if git_as_user push 2>/dev/null; then
        echo "Pushed successfully"
    else
        echo "[pkgtrack] push failed (offline or no remote) - committed locally"
    fi
else
    echo "[pkgtrack] AUTO_PUSH=false - committed locally, skipping push"
fi

exit 0
