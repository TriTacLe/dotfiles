#!/bin/bash
# Verify the dotfiles repo is in a healthy, portable state.
# Run before committing structural changes or before deploying to a fresh Arch machine.

set -uo pipefail

# Script lives at shared/scripts/verify-system.sh, repo root is two levels up
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$DOTFILES_DIR" || exit 1

PASS=0
FAIL=0

check() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "  ok   $name"
        PASS=$((PASS+1))
    else
        echo "  FAIL $name"
        FAIL=$((FAIL+1))
    fi
}

echo "=== Dotfiles verification ==="

echo ""
echo "[1] Hardcoded user paths"
# Scans every tracked file rather than a list of extensions, so new file types
# (.lua, .jsonc, .gitconfig, systemd units) are covered without touching this.
# Filtered out: the claude-config submodule entry, this script (which has to contain
# the pattern it searches for), and .p10k.zsh (wizard output, example paths in comments).
_hc_home_re='/home/[a-z_][a-z0-9_-]*/'
_hc_skip='^(claude-config|shared/scripts/verify-system\.sh|shared/stow/zsh/\.config/zsh/\.p10k\.zsh)$'
_hc_hits() {
    git ls-files -z | grep -zvE "$_hc_skip" \
        | xargs -0 grep -InsE "$_hc_home_re" 2>/dev/null
}
HARDCODES=$(_hc_hits | wc -l)
if [[ "$HARDCODES" -eq 0 ]]; then
    echo "  ok   no absolute /home/<user> paths in tracked files"
    PASS=$((PASS+1))
else
    echo "  FAIL $HARDCODES /home/<user> hardcode(s) found:"
    _hc_hits | sed 's/^/    /'
    FAIL=$((FAIL+1))
fi

echo ""
echo "[2] Hyprland active hardcodes (monitor names, resolutions)"
# Only the cross-machine config. The per-host hypr-host overlays exist precisely
# to hold connector names and resolutions, so they are exempt.
_hypr_dirs=(shared/stow/hypr/)
ACTIVE_MON=$(grep -rn "^[^#-]*monitor.*\(eDP-[0-9]\|DP-[0-9]\)" "${_hypr_dirs[@]}" 2>/dev/null | wc -l)
ACTIVE_RES=$(grep -rn "^[^#-]*\(1920x1200\|2560x1440\)" "${_hypr_dirs[@]}" 2>/dev/null | wc -l)
unset _hypr_dirs
[[ "$ACTIVE_MON" -eq 0 ]] && { echo "  ok   no active monitor hardcodes"; PASS=$((PASS+1)); } || { echo "  FAIL $ACTIVE_MON monitor hardcode(s)"; FAIL=$((FAIL+1)); }
[[ "$ACTIVE_RES" -eq 0 ]] && { echo "  ok   no active resolution hardcodes"; PASS=$((PASS+1)); } || { echo "  FAIL $ACTIVE_RES resolution hardcode(s)"; FAIL=$((FAIL+1)); }

echo ""
echo "[3] Shell script syntax"
SH_FAIL=0
while IFS= read -r f; do
    bash -n "$f" 2>/dev/null || { echo "    syntax error: $f"; SH_FAIL=$((SH_FAIL+1)); }
done < <(find . -name "*.sh" -not -path "./archived-scripts/*" -not -path "./claude-config/*" -not -path "./.git/*" -not -path "*/nvim/*")
if [[ "$SH_FAIL" -eq 0 ]]; then
    echo "  ok   all shell scripts parse"
    PASS=$((PASS+1))
else
    echo "  FAIL $SH_FAIL script(s) failed to parse"
    FAIL=$((FAIL+1))
fi

echo ""
echo "[4] zsh config syntax"
check "arch/stow/zsh/.zshrc parses" zsh -n arch/stow/zsh/.zshrc

echo ""
echo "[5] Required files exist"
check "shared/scripts/config.sh"              test -f shared/scripts/config.sh
check "arch/scripts/pkgtrack.sh"            test -f arch/scripts/pkgtrack.sh
check "install.sh"                          test -x install.sh
check "arch/install-hook.sh"               test -x arch/install-hook.sh
check "arch/pacman-hook-autotrack.hook"    test -f arch/pacman-hook-autotrack.hook
check "arch/packages/packages.txt"         test -f arch/packages/packages.txt
check "arch/packages/aur.txt"              test -f arch/packages/aur.txt
check "arch/templates/env.example"         test -f arch/templates/env.example

echo ""
echo "[6] Shared library is sourceable"
if bash -c "source shared/scripts/config.sh && [[ -n \$DOTFILES_DIR ]] && type log >/dev/null" 2>/dev/null; then
    echo "  ok   shared/scripts/config.sh exposes DOTFILES_DIR + logger"
    PASS=$((PASS+1))
else
    echo "  FAIL shared/scripts/config.sh broken or missing helpers"
    FAIL=$((FAIL+1))
fi

echo ""
echo "[7] Pacman hook points at the symlink (machine-agnostic)"
if grep -q "^Exec = /usr/local/bin/dotfiles-pkgtrack" arch/pacman-hook-autotrack.hook 2>/dev/null; then
    echo "  ok   hook uses /usr/local/bin/dotfiles-pkgtrack"
    PASS=$((PASS+1))
else
    echo "  FAIL hook does not point at the symlink"
    FAIL=$((FAIL+1))
fi

echo ""
echo "[8] install.sh is executable"
check "install.sh executable" test -x install.sh

echo ""
echo "=== Result ==="
echo "  passed: $PASS"
echo "  failed: $FAIL"
if [[ "$FAIL" -eq 0 ]]; then
    echo "ALL CHECKS PASSED"
    exit 0
else
    echo "$FAIL CHECK(S) FAILED"
    exit 1
fi
