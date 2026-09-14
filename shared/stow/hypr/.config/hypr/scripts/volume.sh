#!/bin/bash
# Volume keys. swayosd-client changes the sink and shows the overlay.
# Usage: volume.sh [up|down|mute]

set -euo pipefail

case "${1:-}" in
  up)   swayosd-client --output-volume raise ;;
  down) swayosd-client --output-volume lower ;;
  mute) swayosd-client --output-volume mute-toggle ;;
  *)    echo "usage: volume.sh up|down|mute" >&2; exit 1 ;;
esac
