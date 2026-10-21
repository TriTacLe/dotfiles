#!/bin/bash
# Shared half of the package hooks. Source after config.sh, from a cwd of
# DOTFILES_DIR, and call snapshot_push once the package lists are rewritten.
#
# The hooks run as root out of pacman and apt, so every git call is handed back
# to the real user: the ssh key and the gh token live in their home, not root's.

# Host and machine as they appear in a commit subject
snapshot_host() { cat /etc/hostname 2>/dev/null || echo "unknown"; }

snapshot_machine() {
    local bat
    for bat in /sys/class/power_supply/BAT*; do
        [[ -d "$bat" ]] && { echo "laptop"; return; }
    done
    echo "desktop"
}

# One removal can touch 100+ packages, so keep the subject readable
snapshot_summarize() {
    local n
    n=$(wc -w <<< "$1")
    if (( n > 5 )); then
        echo "$(cut -d' ' -f1-5 <<< "$1") and $((n - 5)) more"
    else
        echo "$1"
    fi
}

# A desktop session keeps its key in an agent whose socket root cannot guess,
# so look for the usual two before falling back to a bare key on disk.
snapshot_git() {
    local -a pre=()
    if [[ -n "${SUDO_USER:-}" ]]; then
        local uid sock="" candidate
        uid=$(id -u "$SUDO_USER" 2>/dev/null)
        for candidate in \
            "${SSH_AUTH_SOCK:-}" \
            "/run/user/$uid/gcr/ssh" \
            "/run/user/$uid/keyring/ssh"; do
            if [[ -n "$candidate" && -S "$candidate" ]]; then
                sock="$candidate"
                break
            fi
        done
        pre=(sudo -u "$SUDO_USER" env)
        [[ -n "$sock" ]] && pre+=("SSH_AUTH_SOCK=$sock")
        [[ -n "${GIT_INDEX_FILE:-}" ]] && pre+=("GIT_INDEX_FILE=$GIT_INDEX_FILE")
    fi
    "${pre[@]}" git "$@"
}

snapshot_gh() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$SUDO_USER" gh "$@"
    else
        gh "$@"
    fi
}

snapshot_log_failure() {
    echo "[pkgtrack] $(date '+%Y-%m-%d %H:%M') $1: $2" >> "$DOTFILES_DIR/.pkgtrack.log"
}

# snapshot_push SUBJECT MESSAGE PR_BODY FILE...
#
# Pushes the listed files as one commit on a per-host branch and opens a PR for
# it. The branch is never checked out and HEAD never moves: the working tree is a
# field of stow symlinks that running programs read, so the commit is assembled
# in a throwaway index and sent straight to the remote ref.
snapshot_push() {
    local subject="$1" message="$2" pr_body="$3"
    shift 3

    local host branch
    host=$(snapshot_host)
    # One branch per host so each machine keeps a single PR that later
    # transactions add to, rather than a new PR per package.
    branch="pkgtrack/${host//[^a-zA-Z0-9._-]/-}"

    if ! snapshot_git fetch -q "$GIT_REMOTE" \
        "+refs/heads/$GIT_BRANCH:refs/remotes/$GIT_REMOTE/$GIT_BRANCH" 2>/dev/null; then
        echo "[pkgtrack] cannot reach $GIT_REMOTE - lists rewritten, nothing pushed"
        snapshot_log_failure "fetch failed" "$subject"
        return 0
    fi

    local base parent tip
    base=$(snapshot_git rev-parse "refs/remotes/$GIT_REMOTE/$GIT_BRANCH")
    # An already merged branch starts over from the base, an open one keeps its
    # history so earlier subjects are not lost from the PR.
    parent="$base"
    if snapshot_git fetch -q "$GIT_REMOTE" \
        "+refs/heads/$branch:refs/remotes/$GIT_REMOTE/$branch" 2>/dev/null; then
        tip=$(snapshot_git rev-parse "refs/remotes/$GIT_REMOTE/$branch")
        snapshot_git merge-base --is-ancestor "$tip" "$base" || parent="$tip"
    fi

    GIT_INDEX_FILE=$(mktemp)
    export GIT_INDEX_FILE
    [[ -n "${SUDO_USER:-}" ]] && chown "$SUDO_USER" "$GIT_INDEX_FILE"

    local tree sha file blob built=yes
    snapshot_git read-tree "$parent" || built=no
    for file in "$@"; do
        [[ "$built" == yes ]] || break
        blob=$(snapshot_git hash-object -w "$file") \
            && snapshot_git update-index --add --cacheinfo "100644,$blob,$file" \
            || built=no
    done
    if [[ "$built" != yes ]]; then
        echo "[pkgtrack] could not build the snapshot commit" >&2
        snapshot_log_failure "build failed" "$subject"
        rm -f "$GIT_INDEX_FILE"
        unset GIT_INDEX_FILE
        return 1
    fi

    tree=$(snapshot_git write-tree)
    rm -f "$GIT_INDEX_FILE"
    unset GIT_INDEX_FILE
    if [[ -z "$tree" ]]; then
        snapshot_log_failure "write-tree failed" "$subject"
        return 1
    fi
    if [[ "$tree" == "$(snapshot_git rev-parse "$parent^{tree}")" ]]; then
        echo "[pkgtrack] snapshot already matches $branch, nothing to push"
        return 0
    fi

    sha=$(snapshot_git commit-tree "$tree" -p "$parent" -m "$message")
    if [[ -z "$sha" ]]; then
        echo "[pkgtrack] commit-tree failed" >&2
        snapshot_log_failure "commit-tree failed" "$subject"
        return 1
    fi

    if ! snapshot_git push --force "$GIT_REMOTE" "$sha:refs/heads/$branch" 2>/dev/null; then
        echo "[pkgtrack] push to $branch failed"
        snapshot_log_failure "push failed" "$subject"
        return 1
    fi
    echo "[pkgtrack] pushed $sha to $branch"
    echo "[pkgtrack] the package lists stay modified locally until the PR merges and you pull"

    if ! command -v gh >/dev/null 2>&1; then
        echo "[pkgtrack] gh not installed - open a PR from $branch by hand"
        return 0
    fi
    if snapshot_gh pr create --base "$GIT_BRANCH" --head "$branch" \
        --title "$subject" --body "$pr_body" 2>/dev/null; then
        return 0
    fi

    # Already open from an earlier transaction, or gh is not authenticated here
    local existing
    existing=$(snapshot_gh pr list --head "$branch" --json url -q '.[0].url' 2>/dev/null)
    if [[ -n "$existing" ]]; then
        echo "[pkgtrack] added the commit to the open PR $existing"
    else
        echo "[pkgtrack] could not open a PR - branch $branch is pushed, open it by hand"
    fi
}
