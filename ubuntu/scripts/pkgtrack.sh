#!/bin/bash
# Package tracking for Ubuntu/Debian - regenerates packages.txt from apt-mark
# showmanual, then pushes the snapshot to a per-machine branch and opens a PR if
# AUTO_PUSH=true.
# Invoked by /etc/apt/apt.conf.d/99dotfiles-autotrack via /usr/local/bin/dotfiles-pkgtrack-ubuntu symlink.

# No -e on purpose: merge-base --is-ancestor returns nonzero as normal control
# flow inside snapshot_push.
set -uo pipefail

# Handle SUDO_USER (apt runs as root - rebase HOME so config.sh and git work)
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
DPKG_LOG="${DPKG_LOG:-/var/log/dpkg.log}"

mkdir -p "$PACKAGES_DIR"

OLD_PACKAGES_FILE=$(mktemp)
cp "$PACKAGES_FILE" "$OLD_PACKAGES_FILE" 2>/dev/null || true

apt-mark showmanual 2>/dev/null | sort -u > "$PACKAGES_FILE"

NEW_PKGS=$(comm -13 <(sort "$OLD_PACKAGES_FILE") "$PACKAGES_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
REMOVED_PKGS=$(comm -23 <(sort "$OLD_PACKAGES_FILE") "$PACKAGES_FILE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

rm -f "$OLD_PACKAGES_FILE"

# apt-mark showmanual lists manually installed packages only, so an apt remove
# shows up as just the name that was typed and whatever apt pruned alongside it
# leaves no trace. dpkg appends its own log as it works, so the current run is
# already there when a DPkg::Post-Invoke hook runs; apt writes history.log only
# once it exits, too late to read here. Only the last dpkg invocation is read, so
# a run that apt splits into several removal passes records the last of them.
removed_by_dpkg() {
    [[ -r "$DPKG_LOG" ]] || return 0
    awk '$3 == "startup"                      { block = "" }
         $3 == "remove" || $3 == "purge"      { name = $4; sub(/:.*/, "", name); block = block name "\n" }
         END                                  { printf "%s", block }' "$DPKG_LOG"
}

PRUNED_DEPS=$(removed_by_dpkg | sort -u | awk -v explicit="$REMOVED_PKGS" '
    BEGIN { n = split(explicit, a, " "); for (i = 1; i <= n; i++) seen[a[i]] = 1 }
    !($0 in seen)' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

if [[ -z "$NEW_PKGS" && -z "$REMOVED_PKGS" ]]; then
    exit 0
fi

NEW_COUNT=$(wc -l < "$PACKAGES_FILE")

[[ -n "$NEW_PKGS" ]] && echo "[+] New packages: $NEW_PKGS"
[[ -n "$REMOVED_PKGS" ]] && echo "[-] Removed packages: $REMOVED_PKGS"
[[ -n "$PRUNED_DEPS" ]] && echo "[-] Pruned dependencies: $PRUNED_DEPS"

cd "$DOTFILES_DIR" || exit 1

parts=()
[[ -n "$NEW_PKGS" ]] && parts+=("+$(snapshot_summarize "$NEW_PKGS")")
[[ -n "$REMOVED_PKGS" ]] && parts+=("-$(snapshot_summarize "$REMOVED_PKGS")")

HOSTNAME=$(snapshot_host)
SUBJECT="[AUTO] [$(date '+%Y-%m-%d')] [$HOSTNAME:$(snapshot_machine)] APT $(IFS='|'; echo "${parts[*]}")"
COMMIT_MSG="$SUBJECT"
# The subject only ever names manual packages, so the pruned deps go in the body
[[ -n "$PRUNED_DEPS" ]] && COMMIT_MSG="$SUBJECT"$'\n\n'"pruned deps: $PRUNED_DEPS"

PR_BODY="Package snapshot from $HOSTNAME, committed by the apt hook."
[[ -n "$PRUNED_DEPS" ]] && PR_BODY="$PR_BODY"$'\n\n'"Pruned dependencies: $PRUNED_DEPS"

echo "Total packages: $NEW_COUNT"
echo "Commit message: $SUBJECT"

if [[ "$AUTO_PUSH" != "true" ]]; then
    echo "[pkgtrack] AUTO_PUSH=false - list rewritten, nothing committed or pushed"
    exit 0
fi

snapshot_push "$SUBJECT" "$COMMIT_MSG" "$PR_BODY" ubuntu/packages/packages.txt
