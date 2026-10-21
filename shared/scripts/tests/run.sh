#!/usr/bin/env bash
# Tests for pkgtrack.sh. Never touches real pacman, the real repo or the network:
# pacman is a stub on PATH, DOTFILES_DIR points at a throwaway git repo and
# AUTO_PUSH is false so no push is attempted.
# Usage: shared/scripts/tests/run.sh   (exit 0 = all passed)
#        SHOW=1 shared/scripts/tests/run.sh   (also print each run's output)
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here/../../.." && pwd)"
pkgtrack="$repo_root/arch/scripts/pkgtrack.sh"
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
export PATH="$work/bin:$PATH"
export PKGSTUB_ALL="$work/all.txt" PKGSTUB_AUR="$work/aur.txt"

# fresh_repo: throwaway dotfiles clone with empty package lists
fresh_repo() {
    rm -rf "$work/repo" "$work/remote"
    mkdir -p "$work/repo/arch/packages"
    git -C "$work/repo" init -q -b master
    git -C "$work/repo" config user.email test@example.com
    git -C "$work/repo" config user.name Test
    : > "$work/repo/arch/packages/packages.txt"
    : > "$work/repo/arch/packages/aur.txt"
    git -C "$work/repo" add -A
    git -C "$work/repo" commit -qm init
}

# run_pkgtrack OFFICIAL AUR: set the stub's package sets, then run the script
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
    out="$(env -u SUDO_USER DOTFILES_DIR="$work/repo" AUTO_PUSH=false bash "$pkgtrack" 2>&1)"
    rc=$?
    [[ -n "${SHOW:-}" ]] && printf '%s\n' "$out"
    return $rc
}

subject() { git -C "$work/repo" log -1 --pretty=%s; }
commits() { git -C "$work/repo" rev-list --count HEAD; }

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
echo "[1] a new official package is tracked and committed"
fresh_repo
run_pkgtrack "bat eza fd" ""
check "packages.txt is sorted" "bat
eza
fd" "$(cat "$work/repo/arch/packages/packages.txt")"
check "one commit on top of init" "2" "$(commits)"
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
echo "[3] a second run with no change makes no commit"
fresh_repo
run_pkgtrack "bat eza" ""
before="$(commits)"
run_pkgtrack "bat eza" ""
check "commit count unchanged" "$before" "$(commits)"

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
echo "[7] a push master cannot take becomes a branch and a PR"
# Stands in for GitHub's branch protection: a bare remote whose pre-receive
# hook refuses refs/heads/master and accepts everything else.
fresh_repo
git init -q --bare "$work/remote"
git -C "$work/remote" config core.hooksPath "$work/remote/hooks"
git -C "$work/repo" remote add origin "$work/remote"
git -C "$work/repo" push -q -u origin master
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

master_before="$(git -C "$work/remote" rev-parse refs/heads/master)"
printf '%s\n' bat eza > "$PKGSTUB_ALL"
: > "$PKGSTUB_AUR"
out="$(env -u SUDO_USER DOTFILES_DIR="$work/repo" AUTO_PUSH=true bash "$pkgtrack" 2>&1)"
[[ -n "${SHOW:-}" ]] && printf '%s\n' "$out"

host="$(cat /etc/hostname 2>/dev/null || echo unknown)"
host="${host//[^a-zA-Z0-9._-]/-}"
check "the commit landed on the per-host branch" "yes" \
    "$(git -C "$work/remote" rev-parse --verify -q "refs/heads/pkgtrack/$host" >/dev/null && echo yes || echo no)"
check "protected master was not moved" "$master_before" \
    "$(git -C "$work/remote" rev-parse refs/heads/master)"
check "a PR was opened against master" "yes" \
    "$(grep -q "^pr create --base master --head pkgtrack/$host" "$GHSTUB_LOG" && echo yes || echo no)"
check "local branch was never switched" "master" "$(git -C "$work/repo" branch --show-current)"

rm -f "$work/bin/gh"

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
