#!/bin/bash
set -euo pipefail
# Listens for Hyprland monitor events and reassigns workspaces on change.
# Requires: jq

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
# uwsm app with UWSM_APP_UNIT_TYPE=service runs from the systemd activation
# environment, which need not carry the compositor's signature. Deriving it from
# the newest instance directory keeps this working there; dying on an unbound
# variable meant the reconnect loop below never started and the feature silently
# stopped for the rest of the session.
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
SIG="${HYPRLAND_INSTANCE_SIGNATURE:-}"
if [[ -z "$SIG" ]]; then
    SIG=$(ls -t "$RUNTIME/hypr" 2>/dev/null | head -n1 || true)
fi
if [[ -z "$SIG" ]]; then
    echo "no Hyprland instance under $RUNTIME/hypr" >&2
    exit 1
fi
SOCKET="$RUNTIME/hypr/$SIG/.socket2.sock"

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
