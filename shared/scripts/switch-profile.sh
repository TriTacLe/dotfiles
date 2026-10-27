#!/bin/bash
# Profile management script
# Switch between different per-person profiles

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE_FILE="$HOME/.dotfiles-person"

if [ ! -f "$PROFILE_FILE" ]; then
    echo "No profile selected. Please set \$HOME/.dotfiles-person"
    exit 1
fi

SELECTED_PROFILE="$(cat "$PROFILE_FILE")"

case "$SELECTED_PROFILE" in
    "tri")
        echo "Using Tri's profile"
        # Source tri's profile settings
        [ -f "$DOTFILES/profiles/tri/profile.env" ] && source "$DOTFILES/profiles/tri/profile.env"
        ;;
    "saikou")
        echo "Using Saikou's profile"
        [ -f "$DOTFILES/profiles/saikou/profile.env" ] && source "$DOTFILES/profiles/saikou/profile.env"
        ;;
    *)
        echo "Unknown profile: $SELECTED_PROFILE"
        exit 1
        ;;
esac

echo "Profile switched to: $SELECTED_PROFILE"