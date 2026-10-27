#!/bin/bash
# Verify dotfiles integrity
# Checks that essential dotfiles exist and are properly configured

set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

echo "Verifying dotfiles..."

# Check essential dotfiles
for file in .zshrc .zshenv .gitconfig; do
    if [ -f "$HOME/$file" ]; then
        echo "  OK: $file exists"
        PASS=$((PASS + 1))
    else
        echo "  MISSING: $file"
        FAIL=$((FAIL + 1))
    fi
done

# Check claube-config submodule
if [ -d "$DOTFILES/claube-config" ]; then
    echo "  OK: claube-config submodule initialized"
    PASS=$((PASS + 1))
else
    echo "  MISSING: claube-config submodule"
    FAIL=$((FAIL + 1))
fi

# Check profiles directory
if [ -d "$DOTFILES/profiles/example" ]; then
    echo "  OK: profiles/example template exists"
    PASS=$((PASS + 1))
else
    echo "  MISSING: profiles/example template"
    FAIL=$((FAIL + 1))
fi

# Check justfile
if [ -f "$DOTFILES/justfile" ]; then
    echo "  OK: justfile exists"
    PASS=$((PASS + 1))
else
    echo "  MISSING: justfile"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -gt 0 ]; then
    exit 1
fi

exit 0