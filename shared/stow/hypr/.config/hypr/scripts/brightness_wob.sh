#!/bin/bash

# Brightness control - avizo-daemon auto-shows overlay via dbus
# Usage: brightness_wob.sh [up|down]

ACTION="$1"

if ! command -v brightnessctl &> /dev/null; then
  notify-send -u critical "Error" "brightnessctl not found"
  exit 1
fi

case "$ACTION" in
  up)
    brightnessctl set 5%+
    ;;
  down)
    brightnessctl set 5%-
    ;;
esac
