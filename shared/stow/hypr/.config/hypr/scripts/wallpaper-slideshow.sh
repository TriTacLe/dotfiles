#!/bin/bash
# Wallpaper slideshow - steps through the wallpapers in order every 30 minutes.
# "wallpaper-slideshow.sh next" or "prev" switches once and exits.

set -euo pipefail

WALLPAPER_DIR="$HOME/.config/backgrounds"
INTERVAL=1800

# Build list of wallpapers
WALLPAPERS=()
for wp in "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.webp; do
    [[ -f "$wp" ]] && WALLPAPERS+=("$wp")
done

# Check if we have wallpapers
if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    echo "No wallpapers found"
    exit 1
fi

# Get monitors
get_monitors() {
    hyprctl monitors | grep "Monitor" | awk '{print $2}'
}

# Pick the wallpaper $1 steps from the one shown now. hyprpaper reports the resolved
# path, so match on file name.
next_wallpaper() {
    local step=$1 current i n=${#WALLPAPERS[@]}
    current=$(hyprctl hyprpaper listactive 2>/dev/null | head -n1 | awk '{print $2}')
    current=$(basename "${current:-none}")
    for i in "${!WALLPAPERS[@]}"; do
        if [[ $(basename "${WALLPAPERS[$i]}") == "$current" ]]; then
            echo "${WALLPAPERS[$(( (i + step + n) % n ))]}"
            return
        fi
    done
    echo "${WALLPAPERS[0]}"
}

# Set wallpapers
set_wallpapers() {
    local step=${1:-1}
    mapfile -t monitors < <(get_monitors)

    [[ ${#monitors[@]} -eq 0 ]] && return

    wallpaper=$(next_wallpaper "$step")
    hyprctl hyprpaper unload all >/dev/null 2>&1 || true

    for monitor in "${monitors[@]}"; do
        hyprctl hyprpaper wallpaper "$monitor,$wallpaper" 2>/dev/null || true
    done
}

case ${1:-} in
    next) set_wallpapers 1; exit 0 ;;
    prev) set_wallpapers -1; exit 0 ;;
esac

# Wait for hyprpaper to be ready
sleep 2

# Set immediately
set_wallpapers

# Loop
while true; do
    sleep $INTERVAL
    set_wallpapers
done
