#!/bin/bash
# Verify the dotfiles repo is in a healthy, portable state.
# Run before committing structural changes or before deploying to a fresh Arch machine.

set -uo pipefail

# Script lives at arch/verify-system.sh, repo root is one level up
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR"

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
_hc_args=(
    --include="*.sh" --include="*.hook" --include=".zshrc" --include="Makefile"
    --include="*.conf" --include="*.toml" --include="*.json"
    --exclude-dir=archived-scripts --exclude-dir=claude-config --exclude-dir=.claude --exclude-dir=.git
    --exclude=verify-system.sh
)
HARDCODES=$(grep -rn "/home/tri" "${_hc_args[@]}" . 2>/dev/null | wc -l)
if [[ "$HARDCODES" -eq 0 ]]; then
    echo "  ok   no /home/tri hardcodes"
    PASS=$((PASS+1))
else
    echo "  FAIL $HARDCODES /home/tri hardcode(s) found:"
    grep -rn "/home/tri" "${_hc_args[@]}" . 2>/dev/null | sed 's/^/    /'
    FAIL=$((FAIL+1))
fi
unset _hc_args

echo ""
echo "[2] Hyprland active hardcodes (monitor names, resolutions)"
ACTIVE_MON=$(grep -rn "^[^#]*monitor.*=.*\(eDP-[0-9]\|DP-[0-9]\)" arch/stow/hypr/ --include="*.conf" 2>/dev/null | wc -l)
ACTIVE_RES=$(grep -rn "^[^#]*\(1920x1200\|2560x1440\)" arch/stow/hypr/ --include="*.conf" 2>/dev/null | wc -l)
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
check "arch/scripts/config.sh"              test -f arch/scripts/config.sh
check "arch/scripts/pkgtrack.sh"            test -f arch/scripts/pkgtrack.sh
check "install.sh"                          test -x install.sh
check "arch/install-hook.sh"               test -x arch/install-hook.sh
check "arch/pacman-hook-autotrack.hook"    test -f arch/pacman-hook-autotrack.hook
check "arch/packages/packages.txt"         test -f arch/packages/packages.txt
check "arch/packages/aur.txt"              test -f arch/packages/aur.txt
check "arch/templates/env.example"         test -f arch/templates/env.example

echo ""
echo "[6] Shared library is sourceable"
if bash -c "source arch/scripts/config.sh && [[ -n \$DOTFILES_DIR ]] && type log >/dev/null" 2>/dev/null; then
    echo "  ok   arch/scripts/config.sh exposes DOTFILES_DIR + logger"
    PASS=$((PASS+1))
else
    echo "  FAIL arch/scripts/config.sh broken or missing helpers"
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
