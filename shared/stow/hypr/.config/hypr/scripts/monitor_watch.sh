#!/bin/bash
set -euo pipefail
# Listens for Hyprland monitor events and reassigns workspaces on change.
# Requires: jq

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# Reconnect forever. A dropped socket read would otherwise leave monitor
# hotplug unhandled for the rest of the session.
while true; do
    if [[ -S "$SOCKET" ]]; then
        nc -U "$SOCKET" | while IFS= read -r line; do
            case "$line" in
                monitoradded*|monitorremoved*)
                    sleep 0.5
                    "$SCRIPT_DIR/assign_workspaces.sh" || true
                    ;;
            esac
        done || true
    fi

    sleep 2
done
