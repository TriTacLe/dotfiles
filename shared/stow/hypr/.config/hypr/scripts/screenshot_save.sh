#!/bin/bash
set -euo pipefail
grim -g "$(slurp)" "$HOME/Pictures/Screenshots/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"

