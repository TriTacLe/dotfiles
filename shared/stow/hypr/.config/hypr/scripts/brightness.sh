#!/bin/bash
# Brightness keys. swayosd-client changes the backlight and shows the overlay.
# Usage: brightness.sh [up|down]

set -euo pipefail

case "${1:-}" in
  up)   swayosd-client --brightness raise ;;
  down) swayosd-client --brightness lower ;;
  *)    echo "usage: brightness.sh up|down" >&2; exit 1 ;;
esac
