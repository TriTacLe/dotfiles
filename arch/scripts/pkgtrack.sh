#!/bin/bash
# Package tracking - regenerates packages.txt + aur.txt from pacman -Qqe, then
# pushes the snapshot to a per-machine branch and opens a PR if AUTO_PUSH=true.
# Invoked by /usr/share/libalpm/hooks/20-dotfiles-autotrack.hook
# via the /usr/local/bin/dotfiles-pkgtrack symlink.

# No -e on purpose: pacman -Qqme with no AUR packages and merge-base
# --is-ancestor both return nonzero as normal control flow further down.
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
source "$_repo/shared/scripts/pkgsnapshot.sh"
unset _self _repo

[[ -z "${DOTFILES_DIR:-}" ]] && { echo "[pkgtrack] dotfiles dir not found" >&2; exit 1; }
PACKAGES_FILE="$PACKAGES_DIR/packages.txt"
AUR_FILE="$PACKAGES_DIR/aur.txt"
PACMAN_LOG="${PACMAN_LOG:-/var/log/pacman.log}"

OLD_PACKAGES_FILE=$(mktemp)
cp "$PACKAGES_FILE" "$OLD_PACKAGES_FILE" 2>/dev/null || true

OLD_AUR_FILE=$(mktemp)
cp "$AUR_FILE" "$OLD_AUR_FILE" 2>/dev/null || true

AUR_PACKAGES=$(pacman -Qqme | sort)
ALL_PACKAGES=$(pacman -Qqe | sort)
OFFICIAL_PACKAGES=$(comm -23 <(echo "$ALL_PACKAGES") <(echo "$AUR_PACKAGES"))

# printf guarded on empty, not echo: echo of an empty variable still writes a
# newline, which on a box with no AUR packages left aur.txt holding a blank line
# and made the count report 1 instead of 0.
write_list() {
    if [[ -n "$2" ]]; then
        printf '%s\n' "$2" > "$1"
    else
        : > "$1"
    fi
}

write_list "$PACKAGES_FILE" "$OFFICIAL_PACKAGES"
write_list "$AUR_FILE" "$AUR_PACKAGES"

NEW_PKGS=$(comm -13 <(sort "$OLD_PACKAGES_FILE") "$PACKAGES_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
NEW_AUR=$(comm -13 <(sort "$OLD_AUR_FILE") "$AUR_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
DEL_PKGS=$(comm -23 <(sort "$OLD_PACKAGES_FILE") "$PACKAGES_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
DEL_AUR=$(comm -23 <(sort "$OLD_AUR_FILE") "$AUR_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

rm -f "$OLD_PACKAGES_FILE" "$OLD_AUR_FILE"

# pacman -Qqe lists explicit packages only, so an -Rns shows up as just the name
# that was typed and the dependencies it pruned leave no trace. Recover them from
# the transaction block pacman has already written: PostTransaction hooks run
# after "transaction completed" is logged.
removed_in_transaction() {
    [[ -r "$PACMAN_LOG" ]] || return 0
    awk '/\[ALPM\] transaction started/ { block = "" }
         /\[ALPM\] removed /            { sub(/.*\] removed /, ""); sub(/ .*/, ""); block = block $0 "\n" }
         END                            { printf "%s", block }' "$PACMAN_LOG"
}

PRUNED_DEPS=$(removed_in_transaction | sort -u | awk -v explicit="$DEL_PKGS $DEL_AUR" '
    BEGIN { n = split(explicit, a, " "); for (i = 1; i <= n; i++) seen[a[i]] = 1 }
    !($0 in seen)' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

NEW_COUNT=$(wc -l < "$PACKAGES_FILE")
AUR_COUNT=$(wc -l < "$AUR_FILE" 2>/dev/null || echo "0")

[[ -n "$NEW_PKGS" ]] && echo "[+] New official packages: $NEW_PKGS" || NEW_PKGS="none"
[[ -n "$NEW_AUR" ]] && echo "[+] New AUR packages: $NEW_AUR" || NEW_AUR="none"
[[ -n "$DEL_PKGS" ]] && echo "[-] Removed official packages: $DEL_PKGS" || DEL_PKGS="none"
[[ -n "$DEL_AUR" ]] && echo "[-] Removed AUR packages: $DEL_AUR" || DEL_AUR="none"
[[ -n "$PRUNED_DEPS" ]] && echo "[-] Pruned dependencies: $PRUNED_DEPS"

cd "$DOTFILES_DIR" || exit 1

if [[ "$NEW_PKGS" == "none" && "$NEW_AUR" == "none" && "$DEL_PKGS" == "none" && "$DEL_AUR" == "none" ]]; then
    exit 0
fi

parts=()
[[ "$NEW_PKGS" != "none" ]] && parts+=("+$(snapshot_summarize "$NEW_PKGS")")
[[ "$NEW_AUR" != "none" ]] && parts+=("+AUR $(snapshot_summarize "$NEW_AUR")")
[[ "$DEL_PKGS" != "none" ]] && parts+=("-$(snapshot_summarize "$DEL_PKGS")")
[[ "$DEL_AUR" != "none" ]] && parts+=("-AUR $(snapshot_summarize "$DEL_AUR")")

HOSTNAME=$(snapshot_host)
SUBJECT="[AUTO] [$(date '+%Y-%m-%d')] [$HOSTNAME:$(snapshot_machine)] $(IFS='|'; echo "${parts[*]}")"
COMMIT_MSG="$SUBJECT"
# The subject only ever names explicit packages, so the pruned deps go in the body
[[ -n "$PRUNED_DEPS" ]] && COMMIT_MSG="$SUBJECT"$'\n\n'"pruned deps: $PRUNED_DEPS"

PR_BODY="Package snapshot from $HOSTNAME, committed by the pacman hook."
[[ -n "$PRUNED_DEPS" ]] && PR_BODY="$PR_BODY"$'\n\n'"Pruned dependencies: $PRUNED_DEPS"

echo "Official packages: $NEW_COUNT"
echo "AUR packages: $AUR_COUNT"
echo "Commit message: $SUBJECT"

if [[ "$AUTO_PUSH" != "true" ]]; then
    echo "[pkgtrack] AUTO_PUSH=false - lists rewritten, nothing committed or pushed"
    exit 0
fi

snapshot_push "$SUBJECT" "$COMMIT_MSG" "$PR_BODY" \
    arch/packages/packages.txt arch/packages/aur.txt
