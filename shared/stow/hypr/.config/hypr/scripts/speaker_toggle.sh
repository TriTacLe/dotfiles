#!/bin/bash
set -euo pipefail

# Two hardware models. Some cards expose headphones and speakers as ports on a
# single sink; the UCM profile on this laptop gives each output its own sink.
# Handle both, and never hardcode a card address: it changes between machines.

sink=$(pactl get-default-sink)

read -r head_port line_port < <(
    SINK="$sink" python3 - <<'PY'
import json, os, subprocess
want = os.environ["SINK"]
sinks = json.loads(subprocess.run(
    ["pactl", "--format=json", "list", "sinks"], capture_output=True, text=True, check=True).stdout)
head = line = "-"
for s in sinks:
    if s["name"] != want:
        continue
    for p in s.get("ports") or []:
        name = p["name"] if isinstance(p, dict) else str(p)
        low = name.lower()
        if "headphone" in low:
            head = name
        elif "lineout" in low or "speaker" in low:
            line = name
print(head, line)
PY
)

if [[ "$head_port" != "-" && "$line_port" != "-" ]]; then
    active=$(pactl --format=json list sinks \
        | SINK="$sink" python3 -c 'import json,os,sys; print(next((s.get("active_port") or "") for s in json.load(sys.stdin) if s["name"]==os.environ["SINK"]), end="")')
    if [[ "$active" == *"$head_port"* ]]; then
        pactl set-sink-port "$sink" "$line_port"
        notify-send "Audio: Speakers"
    else
        pactl set-sink-port "$sink" "$head_port"
        notify-send "Audio: Headphones"
    fi
    exit 0
fi

# One sink per output: move the default to the next output instead. Skip sinks
# whose port reports "not available", which is how unplugged HDMI shows up.
mapfile -t sinks < <(pactl --format=json list sinks | python3 -c '
import json, sys
for s in json.load(sys.stdin):
    ports = s.get("ports") or []
    if any((p.get("availability") if isinstance(p, dict) else "") == "not available" for p in ports):
        continue
    print(s["name"])
')

if (( ${#sinks[@]} < 2 )); then
    notify-send -u critical "Audio" "Only one output available, nothing to toggle"
    exit 1
fi

next=""
for i in "${!sinks[@]}"; do
    if [[ "${sinks[i]}" == "$sink" ]]; then
        next="${sinks[(i + 1) % ${#sinks[@]}]}"
        break
    fi
done
[[ -n "$next" ]] || next="${sinks[0]}"

pactl set-default-sink "$next"
notify-send "Audio" "$(pactl --format=json list sinks \
    | SINK="$next" python3 -c 'import json,os,sys; print(next((s.get("description") or s["name"]) for s in json.load(sys.stdin) if s["name"]==os.environ["SINK"]), end="")')"
