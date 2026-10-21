#!/usr/bin/env bash
# Tests for both pkgtrack.sh hooks. Never touches real pacman or apt, the real
# repo, the real logs or the network: the package managers are stubs on PATH,
# DOTFILES_DIR points at a throwaway git repo, the log paths default to /dev/null
# and the push tests talk to a bare remote on disk.
# Usage: shared/scripts/tests/run.sh   (exit 0 = all passed)
#        SHOW=1 shared/scripts/tests/run.sh   (also print each run's output)
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here/../../.." && pwd)"
pkgtrack="$repo_root/arch/scripts/pkgtrack.sh"
apttrack="$repo_root/ubuntu/scripts/pkgtrack.sh"
export NO_COLOR=1
# Hermetic: without this the real ~/.gitconfig applies, and its
# core.hooksPath sends every repo here, bare remotes included, off to
# ~/.git-hooks instead of its own hooks dir.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

passed=0
failed=0

# pacman stub. Mirrors the real exit codes: -Qqme fails when nothing is installed
# from the AUR, which is why pkgtrack.sh runs without -e.
mkdir -p "$work/bin"
cat > "$work/bin/pacman" <<'STUB'
#!/usr/bin/env bash
case "$1" in
    -Qqe)  cat "$PKGSTUB_ALL" ;;
    -Qqme) [[ -s "$PKGSTUB_AUR" ]] || exit 1; cat "$PKGSTUB_AUR" ;;
    *) echo "unexpected pacman call: $*" >&2; exit 1 ;;
esac
STUB
chmod +x "$work/bin/pacman"

cat > "$work/bin/apt-mark" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == "showmanual" ]] || { echo "unexpected apt-mark call: $*" >&2; exit 1; }
cat "$PKGSTUB_MANUAL"
STUB
chmod +x "$work/bin/apt-mark"
export PATH="$work/bin:$PATH"
export PKGSTUB_ALL="$work/all.txt" PKGSTUB_AUR="$work/aur.txt"
export PKGSTUB_MANUAL="$work/manual.txt"

host="$(cat /etc/hostname 2>/dev/null || echo unknown)"
host="${host//[^a-zA-Z0-9._-]/-}"
branch="pkgtrack/$host"

# fresh_repo: throwaway dotfiles clone with empty package lists
fresh_repo() {
    rm -rf "$work/repo" "$work/remote"
    mkdir -p "$work/repo/arch/packages" "$work/repo/ubuntu/packages"
    git -C "$work/repo" init -q -b master
    git -C "$work/repo" config user.email test@example.com
    git -C "$work/repo" config user.name Test
    : > "$work/repo/arch/packages/packages.txt"
    : > "$work/repo/arch/packages/aur.txt"
    : > "$work/repo/ubuntu/packages/packages.txt"
    git -C "$work/repo" add -A
    git -C "$work/repo" commit -qm init
}

# add_remote: bare remote on disk that refuses refs/heads/master, standing in for
# GitHub branch protection. Nothing in pkgtrack.sh may push there any more.
add_remote() {
    git init -q --bare "$work/remote"
    git -C "$work/remote" config core.hooksPath "$work/remote/hooks"
    mkdir -p "$work/remote/hooks"
    git -C "$work/repo" remote add origin "$work/remote"
    git -C "$work/repo" push -q origin master
    # installed only after master is seeded, so it guards pkgtrack and nothing else
    cat > "$work/remote/hooks/pre-receive" <<'HOOK'
#!/usr/bin/env bash
while read -r _old _new ref; do
    if [[ "$ref" == "refs/heads/master" ]]; then
        echo "remote: error: GH006: Protected branch update failed" >&2
        exit 1
    fi
done
exit 0
HOOK
    chmod +x "$work/remote/hooks/pre-receive"
}

# gh stub, logging its arguments so the PR call can be asserted on
install_gh_stub() {
    export GHSTUB_LOG="$work/gh.log"
    : > "$GHSTUB_LOG"
    cat > "$work/bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$GHSTUB_LOG"
# pr list must return nothing so the caller takes the "created" path
[[ "$1 $2" == "pr list" ]] && exit 0
exit 0
STUB
    chmod +x "$work/bin/gh"
}

# run_pkgtrack OFFICIAL AUR: set the stub's package sets, then run the script.
# AUTO_PUSH stays false unless PUSH=1, so most cases need no remote at all.
run_pkgtrack() {
    local -a official aur
    read -ra official <<< "$1"
    read -ra aur <<< "$2"
    # -Qqe reports both sets, -Qqme only the AUR half, same as the real pacman
    printf '%s\n' "${official[@]}" > "$PKGSTUB_ALL"
    if (( ${#aur[@]} )); then
        printf '%s\n' "${aur[@]}" >> "$PKGSTUB_ALL"
        printf '%s\n' "${aur[@]}" > "$PKGSTUB_AUR"
    else
        : > "$PKGSTUB_AUR"
    fi
    local push=false
    [[ -n "${PUSH:-}" ]] && push=true
    out="$(env -u SUDO_USER DOTFILES_DIR="$work/repo" \
        PACMAN_LOG="${LOGSTUB:-/dev/null}" \
        AUTO_PUSH="$push" bash "$pkgtrack" 2>&1)"
    rc=$?
    [[ -n "${SHOW:-}" ]] && printf '%s\n' "$out"
    return $rc
}

# run_apttrack MANUAL: same contract as run_pkgtrack for the apt hook. PKG_MANAGER
# is explicit because this box has pacman, so detection would pick the arch dir.
run_apttrack() {
    local -a manual
    read -ra manual <<< "$1"
    printf '%s\n' "${manual[@]}" > "$PKGSTUB_MANUAL"
    local push=false
    [[ -n "${PUSH:-}" ]] && push=true
    out="$(env -u SUDO_USER DOTFILES_DIR="$work/repo" PKG_MANAGER=apt \
        DPKG_LOG="${LOGSTUB:-/dev/null}" \
        AUTO_PUSH="$push" bash "$apttrack" 2>&1)"
    rc=$?
    [[ -n "${SHOW:-}" ]] && printf '%s\n' "$out"
    return $rc
}

# what the run would commit, read off the script's own report
subject() { sed -n 's/^Commit message: //p' <<< "$out"; }
commits() { git -C "$work/repo" rev-list --count HEAD; }
# the snapshot the run actually pushed
pushed()  { git -C "$work/remote" log -1 --pretty="$1" "refs/heads/$branch" 2>/dev/null; }

check() {
    local name="$1" want="$2" got="$3"
    if [[ "$want" == "$got" ]]; then
        echo "  ok   $name"
        passed=$((passed+1))
    else
        echo "  FAIL $name"
        echo "         want: $want"
        echo "         got:  $got"
        failed=$((failed+1))
    fi
}

echo "=== pkgtrack ==="

echo ""
echo "[1] a new official package is tracked and reported"
fresh_repo
run_pkgtrack "bat eza fd" ""
check "packages.txt is sorted" "bat
eza
fd" "$(cat "$work/repo/arch/packages/packages.txt")"
check "subject names the additions" "+bat eza fd" "$(subject | sed 's/.*\] //')"

echo ""
echo "[2] AUR packages go to aur.txt only, never packages.txt"
fresh_repo
run_pkgtrack "bat eza" "yay spotify"
check "official list excludes AUR" "bat
eza" "$(cat "$work/repo/arch/packages/packages.txt")"
check "aur list holds only AUR" "spotify
yay" "$(cat "$work/repo/arch/packages/aur.txt")"

echo ""
echo "[3] a second run with no change reports nothing"
fresh_repo
run_pkgtrack "bat eza" ""
run_pkgtrack "bat eza" ""
check "no commit message on the second run" "" "$(subject)"

echo ""
echo "[4] a removed package is recorded as a removal"
fresh_repo
run_pkgtrack "bat eza fd" ""
run_pkgtrack "bat fd" ""
check "subject names the removal" "-eza" "$(subject | sed 's/.*\] //')"

echo ""
echo "[5] more than five additions are summarized"
fresh_repo
run_pkgtrack "a b c d e f g" ""
check "subject truncates after five" "+a b c d e and 2 more" "$(subject | sed 's/.*\] //')"

echo ""
echo "[6] additions and removals share one subject"
fresh_repo
run_pkgtrack "bat eza" ""
run_pkgtrack "bat fd" ""
check "both parts present, pipe separated" "+fd|-eza" "$(subject | sed 's/.*\] //')"

echo ""
echo "[7] no AUR packages leaves aur.txt empty, not one blank line"
fresh_repo
run_pkgtrack "bat eza" ""
check "aur.txt is zero bytes" "0" "$(wc -c < "$work/repo/arch/packages/aur.txt" | tr -d ' ')"
check "the count reported is zero" "AUR packages: 0" "$(grep '^AUR packages:' <<< "$out")"

echo ""
echo "[8] the snapshot is pushed to a per-host branch, never to master"
fresh_repo
add_remote
install_gh_stub
master_before="$(git -C "$work/remote" rev-parse refs/heads/master)"
PUSH=1 run_pkgtrack "bat eza" ""
check "the snapshot landed on the per-host branch" "yes" \
    "$(git -C "$work/remote" rev-parse --verify -q "refs/heads/$branch" >/dev/null && echo yes || echo no)"
check "protected master was not moved" "$master_before" \
    "$(git -C "$work/remote" rev-parse refs/heads/master)"
check "a PR was opened against master" "yes" \
    "$(grep -q "^pr create --base master --head $branch" "$GHSTUB_LOG" && echo yes || echo no)"
check "the pushed subject matches the report" "$(subject)" "$(pushed %s)"
check "the pushed commit sits on origin/master" "$master_before" "$(pushed %P)"

echo ""
echo "[9] nothing is committed locally and no branch is switched"
check "HEAD did not move" "1" "$(commits)"
check "local branch unchanged" "master" "$(git -C "$work/repo" branch --show-current)"
check "the lists stay modified until the PR merges" "yes" \
    "$(test -n "$(git -C "$work/repo" status --porcelain arch/packages)" && echo yes || echo no)"

echo ""
echo "[10] a package install on a feature branch still targets master"
fresh_repo
add_remote
install_gh_stub
git -C "$work/repo" checkout -q -b feature/unrelated
git -C "$work/repo" commit -q --allow-empty -m "unrelated work"
feature_head="$(git -C "$work/repo" rev-parse HEAD)"
master_before="$(git -C "$work/remote" rev-parse refs/heads/master)"
PUSH=1 run_pkgtrack "bat eza" ""
check "the parent is origin/master, not the feature branch" "$master_before" "$(pushed %P)"
check "the feature branch did not gain a commit" "$feature_head" \
    "$(git -C "$work/repo" rev-parse HEAD)"
check "still on the feature branch" "feature/unrelated" \
    "$(git -C "$work/repo" branch --show-current)"

echo ""
echo "[11] deps pruned by -Rns are recorded in the commit body"
fresh_repo
add_remote
install_gh_stub
LOGSTUB="$work/pacman.log"
cat > "$LOGSTUB" <<'LOG'
[2026-10-20T10:00:00+0200] [ALPM] transaction started
[2026-10-20T10:00:00+0200] [ALPM] removed stale-from-last-time (1.0-1)
[2026-10-20T10:00:00+0200] [ALPM] transaction completed
[2026-10-21T15:00:00+0200] [ALPM] transaction started
[2026-10-21T15:00:00+0200] [ALPM] removed eza (0.21.0-1)
[2026-10-21T15:00:00+0200] [ALPM] removed libgit2 (1.9.0-2)
[2026-10-21T15:00:00+0200] [ALPM] removed terminfo (6.5-1)
[2026-10-21T15:00:00+0200] [ALPM] transaction completed
LOG
export LOGSTUB
PUSH=1 run_pkgtrack "bat eza" ""
PUSH=1 run_pkgtrack "bat" ""
check "pruned deps are reported" "[-] Pruned dependencies: libgit2 terminfo" \
    "$(grep '^\[-\] Pruned dependencies:' <<< "$out")"
check "the subject still names only the explicit package" "-eza" \
    "$(subject | sed 's/.*\] //')"
check "the body lists the pruned deps" "pruned deps: libgit2 terminfo" "$(pushed %b)"
check "an earlier transaction block is not read" "yes" \
    "$(pushed %B | grep -q stale-from-last-time && echo no || echo yes)"
check "the PR title stays a single line" "yes" \
    "$(grep -qF -- "--title $(subject) --body" "$GHSTUB_LOG" && echo yes || echo no)"
unset LOGSTUB

echo ""
echo "[12] a per-host branch already merged into master starts over from master"
fresh_repo
add_remote
install_gh_stub
PUSH=1 run_pkgtrack "bat eza" ""
first="$(pushed %H)"
git -C "$work/remote" update-ref refs/heads/master "$first"
master_after_merge="$(git -C "$work/remote" rev-parse refs/heads/master)"
PUSH=1 run_pkgtrack "bat eza fd" ""
check "the new snapshot parents on master, not the merged tip" "$master_after_merge" "$(pushed %P)"
check "exactly one commit sits above master" "1" \
    "$(git -C "$work/remote" rev-list --count "refs/heads/master..refs/heads/$branch")"

echo ""
echo "[13] an unreachable remote leaves the lists written and logs the miss"
fresh_repo
git -C "$work/repo" remote add origin "$work/nonexistent-remote"
PUSH=1 run_pkgtrack "bat eza" ""
check "the run still exits clean" "0" "$rc"
check "the miss is reported" "yes" \
    "$(grep -q 'cannot reach origin' <<< "$out" && echo yes || echo no)"
check "the failure is logged" "yes" \
    "$(grep -q 'fetch failed' "$work/repo/.pkgtrack.log" && echo yes || echo no)"
check "the lists were still rewritten" "bat
eza" "$(cat "$work/repo/arch/packages/packages.txt")"

rm -f "$work/bin/gh"

echo ""
echo "=== apt hook ==="

echo ""
echo "[14] a manually installed package is tracked and reported"
fresh_repo
run_apttrack "curl git tmux"
check "packages.txt is sorted" "curl
git
tmux" "$(cat "$work/repo/ubuntu/packages/packages.txt")"
check "subject names the additions" "APT +curl git tmux" "$(subject | sed 's/.*\] //')"

echo ""
echo "[15] more than five additions are summarized here too"
fresh_repo
run_apttrack "a b c d e f g"
check "subject truncates after five" "APT +a b c d e and 2 more" "$(subject | sed 's/.*\] //')"

echo ""
echo "[16] deps pruned by apt remove are read from dpkg.log"
fresh_repo
add_remote
install_gh_stub
LOGSTUB="$work/dpkg.log"
cat > "$LOGSTUB" <<'LOG'
2026-10-20 10:00:00 startup packages remove
2026-10-20 10:00:00 remove stale-from-last-time:amd64 1.0-1 <none>
2026-10-21 15:00:00 startup packages remove
2026-10-21 15:00:00 remove tmux:amd64 3.4-1 <none>
2026-10-21 15:00:01 status half-configured libevent:amd64 2.1.12-1
2026-10-21 15:00:01 remove libevent:amd64 2.1.12-1 <none>
2026-10-21 15:00:02 purge libutempter:amd64 1.2.1-3 <none>
LOG
export LOGSTUB
PUSH=1 run_apttrack "curl tmux"
PUSH=1 run_apttrack "curl"
check "pruned deps are reported" "[-] Pruned dependencies: libevent libutempter" \
    "$(grep '^\[-\] Pruned dependencies:' <<< "$out")"
check "the subject names only the manual package" "APT -tmux" "$(subject | sed 's/.*\] //')"
check "the body lists the pruned deps" "pruned deps: libevent libutempter" "$(pushed %b)"
check "an earlier dpkg run is not read" "yes" \
    "$(pushed %B | grep -q stale-from-last-time && echo no || echo yes)"
check "a status line is not mistaken for a removal" "yes" \
    "$(pushed %B | grep -q half-configured && echo no || echo yes)"
unset LOGSTUB

echo ""
echo "[17] the apt snapshot goes to the same per-host branch, never to master"
fresh_repo
add_remote
install_gh_stub
master_before="$(git -C "$work/remote" rev-parse refs/heads/master)"
PUSH=1 run_apttrack "curl git"
check "the snapshot landed on the per-host branch" "yes" \
    "$(git -C "$work/remote" rev-parse --verify -q "refs/heads/$branch" >/dev/null && echo yes || echo no)"
check "protected master was not moved" "$master_before" \
    "$(git -C "$work/remote" rev-parse refs/heads/master)"
check "the pushed commit sits on origin/master" "$master_before" "$(pushed %P)"
check "only the ubuntu list is in the commit" "ubuntu/packages/packages.txt" \
    "$(git -C "$work/remote" diff --name-only "refs/heads/master" "refs/heads/$branch")"
check "nothing was committed locally" "1" "$(commits)"


echo ""
echo "=== Result ==="
echo "  passed: $passed"
echo "  failed: $failed"
if [[ "$failed" -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$failed TEST(S) FAILED"
exit 1
