#!/usr/bin/env bash
set -euo pipefail
# Label the active workspace so waybar shows what it is instead of a bare number.
# Empty input clears the label back to the plain workspace number.
#
# The label is written to disk so workspace_names.sh can restore it after the
# workspace is destroyed or the config is reloaded.

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/workspace_names"

ws=$(hyprctl activeworkspace -j)
id=$(jq -r '.id' <<<"$ws")
current=$(jq -r '.name' <<<"$ws")

# Strip the "3: " prefix so the prompt prefills with just the label.
label=${current#"$id"}
label=${label#": "}
[[ "$label" == "$id" ]] && label=""

new=$(wofi \
    --dmenu \
    --prompt "Name workspace $id" \
    --search "$label" \
    --style ~/.config/wofi/rename.css \
    --width 460 \
    --height 110 \
    --exec-search \
    --cache-file /dev/null \
    < /dev/null | tr -d "'\"=" | tr -d '\n' || true)

mkdir -p "$(dirname "$STATE")"
touch "$STATE"
tmp=$(mktemp)
grep -v "^$id=" "$STATE" > "$tmp" || true
[[ -n "$new" ]] && printf '%s=%s\n' "$id" "$new" >> "$tmp"
sort -n -t= -k1 "$tmp" -o "$STATE"
rm -f "$tmp"

hyprctl dispatch "hl.dsp.workspace.rename({ workspace = '$id', name = '$id${new:+: $new}' })"
