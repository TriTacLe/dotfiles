#!/bin/bash

# Volume control - avizo-daemon auto-shows overlay via pulseaudio dbus
# Usage: volume_wob.sh [up|down|mute]

set -euo pipefail

ACTION="${1:-}"

case "$ACTION" in
  up)
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
    ;;
  down)
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-
    ;;
  mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    ;;
esac
