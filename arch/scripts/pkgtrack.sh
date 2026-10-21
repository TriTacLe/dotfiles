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

SUBJECT="[AUTO] [$DATE] [$HOSTNAME:$MACHINE] $(IFS='|'; echo "${parts[*]}")"
COMMIT_MSG="$SUBJECT"
# The subject only ever names explicit packages, so the pruned deps go in the body
[[ -n "$PRUNED_DEPS" ]] && COMMIT_MSG="$SUBJECT"$'\n\n'"pruned deps: $PRUNED_DEPS"

echo "Official packages: $NEW_COUNT"
echo "AUR packages: $AUR_COUNT"
echo "Commit message: $SUBJECT"

log_failure() {
    echo "[pkgtrack] $(date '+%Y-%m-%d %H:%M') $1: $SUBJECT" >> "$DOTFILES_DIR/.pkgtrack.log"
}

if [[ "$AUTO_PUSH" != "true" ]]; then
    echo "[pkgtrack] AUTO_PUSH=false - lists rewritten, nothing committed or pushed"
    exit 0
fi

git_as_user() {
    local -a pre=()
    if [[ -n "${SUDO_USER:-}" ]]; then
        pre=(sudo -u "$SUDO_USER" env)
        [[ -n "${GIT_INDEX_FILE:-}" ]] && pre+=("GIT_INDEX_FILE=$GIT_INDEX_FILE")
    fi
    "${pre[@]}" git "$@"
}

gh_as_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$SUDO_USER" gh "$@"
    else
        gh "$@"
    fi
}

# One branch per host so each machine keeps a single PR that later transactions
# add to, rather than a new PR per package.
BRANCH="pkgtrack/${HOSTNAME//[^a-zA-Z0-9._-]/-}"

if ! git_as_user fetch -q "$GIT_REMOTE" "+refs/heads/$GIT_BRANCH:refs/remotes/$GIT_REMOTE/$GIT_BRANCH" 2>/dev/null; then
    echo "[pkgtrack] cannot reach $GIT_REMOTE - lists rewritten, nothing pushed"
    log_failure "fetch failed"
    exit 0
fi
BASE=$(git_as_user rev-parse "refs/remotes/$GIT_REMOTE/$GIT_BRANCH")

# An already merged branch starts over from the base, an open one keeps its
# history so earlier subjects are not lost from the PR.
PARENT="$BASE"
if git_as_user fetch -q "$GIT_REMOTE" "+refs/heads/$BRANCH:refs/remotes/$GIT_REMOTE/$BRANCH" 2>/dev/null; then
    TIP=$(git_as_user rev-parse "refs/remotes/$GIT_REMOTE/$BRANCH")
    git_as_user merge-base --is-ancestor "$TIP" "$BASE" || PARENT="$TIP"
fi

# The working tree is a field of stow symlinks that running programs read, so the
# branch is never checked out and HEAD is never moved. The commit is assembled in
# a throwaway index and pushed straight to the remote ref.
GIT_INDEX_FILE=$(mktemp)
export GIT_INDEX_FILE
[[ -n "${SUDO_USER:-}" ]] && chown "$SUDO_USER" "$GIT_INDEX_FILE"
trap 'rm -f "$GIT_INDEX_FILE"' EXIT

build_commit() {
    git_as_user read-tree "$PARENT" || return 1
    local file blob
    for file in arch/packages/packages.txt arch/packages/aur.txt; do
        blob=$(git_as_user hash-object -w "$file") || return 1
        git_as_user update-index --add --cacheinfo "100644,$blob,$file" || return 1
    done
}

if ! build_commit; then
    echo "[pkgtrack] could not build the snapshot commit" >&2
    log_failure "build failed"
    exit 1
fi

TREE=$(git_as_user write-tree) || { log_failure "write-tree failed"; exit 1; }
if [[ "$TREE" == "$(git_as_user rev-parse "$PARENT^{tree}")" ]]; then
    echo "[pkgtrack] snapshot already matches $BRANCH, nothing to push"
    exit 0
fi

SHA=$(git_as_user commit-tree "$TREE" -p "$PARENT" -m "$COMMIT_MSG") || {
    echo "[pkgtrack] commit-tree failed" >&2
    log_failure "commit-tree failed"
    exit 1
}

if ! git_as_user push --force "$GIT_REMOTE" "$SHA:refs/heads/$BRANCH" 2>/dev/null; then
    echo "[pkgtrack] push to $BRANCH failed"
    log_failure "push failed"
    exit 1
fi
echo "[pkgtrack] pushed $SHA to $BRANCH"
echo "[pkgtrack] arch/packages stays modified locally until the PR merges and you pull"

PR_BODY="Package snapshot from $HOSTNAME, committed by the pacman hook."
[[ -n "$PRUNED_DEPS" ]] && PR_BODY="$PR_BODY"$'\n\n'"Pruned dependencies: $PRUNED_DEPS"

if ! command -v gh >/dev/null 2>&1; then
    echo "[pkgtrack] gh not installed - open a PR from $BRANCH by hand"
    exit 0
fi

if gh_as_user pr create --base "$GIT_BRANCH" --head "$BRANCH" \
    --title "$SUBJECT" --body "$PR_BODY" 2>/dev/null; then
    exit 0
fi

# Already open from an earlier transaction, or gh is not authenticated here
EXISTING=$(gh_as_user pr list --head "$BRANCH" --json url -q '.[0].url' 2>/dev/null)
if [[ -n "$EXISTING" ]]; then
    echo "[pkgtrack] added the commit to the open PR $EXISTING"
else
    echo "[pkgtrack] could not open a PR - branch $BRANCH is pushed, open it by hand"
fi

exit 0
