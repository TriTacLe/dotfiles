#!/bin/bash
set -euo pipefail
# Keeps workspace labels alive.
#
# A rename is runtime-only state in Hyprland: it dies when the workspace is
# destroyed (last window moved away) and when the config is reloaded. Labels are
# therefore stored on disk and reapplied whenever a workspace comes back.
#
# State file format, one per line: <id>=<label>

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/workspace_names"
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

apply_one() {
    local id=$1 label=$2
    hyprctl dispatch \
        "hl.dsp.workspace.rename({ workspace = '$id', name = '$id${label:+: $label}' })" \
        >/dev/null 2>&1 || true
}

apply_all() {
    [[ -f "$STATE" ]] || return 0
    while IFS='=' read -r id label; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        apply_one "$id" "$label"
    done < "$STATE"
}

apply_id() {
    local want=$1 id label
    [[ -f "$STATE" ]] || return 0
    while IFS='=' read -r id label; do
        [[ "$id" == "$want" ]] || continue
        apply_one "$id" "$label"
        return 0
    done < "$STATE"
}

# Reconnect forever. A dropped socket read would otherwise kill the listener
# for the rest of the session, and labels would silently stop being restored.
while true; do
    apply_all

    if [[ -S "$SOCKET" ]]; then
        nc -U "$SOCKET" | while IFS= read -r line; do
            case "$line" in
                createworkspacev2\>\>*)
                    id=${line#createworkspacev2>>}
                    apply_id "${id%%,*}"
                    ;;
                configreloaded*)
                    apply_all
                    ;;
            esac
        done || true
    fi

    sleep 2
done
