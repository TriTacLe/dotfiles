#!/bin/bash
# Remove Hyprland / desktop / GUI packages from a server host.
#
# Idempotent: pacman -Rns skips packages that aren't installed, so re-running
# is safe. Safe to run on a fresh server (no-op) or a desktop-converted server
# (full strip). Bluetooth + fastfetch intentionally kept.
#
# Needs sudo.
# Usage: sudo bash strip-desktop.sh

set -e

# Lists are split so it's obvious what each group is. pacman handles a single
# -Rns invocation just fine, but the grouping aids review.

HYPRLAND=(
    hyprland hyprcursor hyprgraphics hyprland-guiutils hyprlang hyprpaper
    hyprtoolkit hyprutils hyprwayland-scanner hyprwire
)

PANEL_LAUNCHER_NOTIFICATIONS=(
    waybar wofi swaync avizo avizo-debug
)

TERMINAL_EMULATORS=(
    alacritty
    ghostty ghostty-shell-integration ghostty-terminfo
    kitty kitty-shell-integration kitty-terminfo
)

GUI_APPS=(
    thunar firefox obsidian
)

DISPLAY_MANAGER=(
    sddm
)

WAYLAND_TOOLS=(
    grim slurp
    xdg-desktop-portal xdg-desktop-portal-hyprland
)

FANCY_FETCH=(
    neofetch-git
)

# Audio: handled in pass 2 (orphan cleanup). pipewire is required by GUI
# apps (Obsidian, Firefox, qt6-multimedia, gst-plugin-pipewire, ffmpeg via
# jack, portaudio, etc.) — once those GUI apps are gone, the audio stack
# becomes orphaned and pacman -Qtdq finds it.

ALL=(
    "${HYPRLAND[@]}"
    "${PANEL_LAUNCHER_NOTIFICATIONS[@]}"
    "${TERMINAL_EMULATORS[@]}"
    "${GUI_APPS[@]}"
    "${DISPLAY_MANAGER[@]}"
    "${WAYLAND_TOOLS[@]}"
    "${FANCY_FETCH[@]}"
)

# Filter to only currently-installed packages so pacman doesn't error on
# missing ones. (A pristine server install would have none of these.)
INSTALLED=()
for pkg in "${ALL[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        INSTALLED+=("$pkg")
    fi
done

if [ ${#INSTALLED[@]} -eq 0 ]; then
    echo "Nothing to remove — server already clean."
    exit 0
fi

echo "Pass 1: Removing ${#INSTALLED[@]} package(s):"
printf '  %s\n' "${INSTALLED[@]}"
echo

# -R remove, -n no save (.pacsave), -s remove unneeded deps too.
pacman -Rns --noconfirm "${INSTALLED[@]}"

echo
echo "Pass 2: Orphan cleanup (picks up audio stack + any other now-unused deps)"
ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    echo "Orphans to remove:"
    echo "$ORPHANS" | sed 's/^/  /'
    echo "$ORPHANS" | pacman -Rns --noconfirm -
else
    echo "(no orphans)"
fi

# Pass 2 may itself create new orphans (transitively). Run once more.
ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    echo
    echo "Pass 3: Transitive orphans"
    echo "$ORPHANS" | sed 's/^/  /'
    echo "$ORPHANS" | pacman -Rns --noconfirm -
fi

echo
echo "Strip complete."
