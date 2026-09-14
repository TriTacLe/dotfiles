#!/bin/bash
set -euo pipefail
# Screenshot triggered by the ASUS screenshot key (XF86Send)
grim -g "$(slurp)" - | wl-copy
notify-send -t 3000 "Screenshot" "Copied to clipboard"
