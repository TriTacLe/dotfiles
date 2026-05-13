#!/bin/bash

WALLPAPER_DIR="$HOME/.config/backgrounds"
INTERVAL=30  # 30 sekunder

# Finn alle bildefiler
get_wallpapers() {
    find -L "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort
}

# Sett bakgrunn basert på desktop-miljø
set_wallpaper() {
    local wallpaper="$1"
    
    if command -v gsettings &> /dev/null && [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
        # GNOME
        gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$wallpaper"
    elif command -v swaybg &> /dev/null; then
        # Sway/Wayland
        pkill swaybg 2>/dev/null
        swaybg -i "$wallpaper" -m fill &
    elif command -v feh &> /dev/null; then
        # i3/X11
        feh --bg-fill "$wallpaper"
    elif command -v nitrogen &> /dev/null; then
        # Nitrogen
        nitrogen --set-auto "$wallpaper"
    fi
}

# Hovedløkke
wallpapers=($(get_wallpapers))
index=0

if [ ${#wallpapers[@]} -eq 0 ]; then
    echo "Ingen wallpapers funnet i $WALLPAPER_DIR"
    exit 1
fi

echo "Fant ${#wallpapers[@]} wallpapers"
echo "Roterer hvert $INTERVAL sekund"

while true; do
    wallpaper="${wallpapers[$index]}"
    echo "Setter bakgrunn: $(basename "$wallpaper")"
    set_wallpaper "$wallpaper"
    
    index=$(( (index + 1) % ${#wallpapers[@]} ))
    sleep $INTERVAL
done
