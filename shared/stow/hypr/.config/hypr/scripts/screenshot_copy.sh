#!/bin/bash
set -euo pipefail
REGION=$(slurp) || exit 0
grim -g "$REGION" - | wl-copy
notify-send -t 3000 "Screenshot" "Copied to clipboard"

