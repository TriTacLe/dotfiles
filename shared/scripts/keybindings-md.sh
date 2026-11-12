#!/bin/bash
# Renders KEYBINDINGS.md from the hl.bind lines in keybindings.lua, so the
# table cannot drift from the config. CI regenerates it and fails on a diff.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$DOTFILES/shared/stow/hypr/.config/hypr/keybindings.lua"
OUT="${1:-$DOTFILES/KEYBINDINGS.md}"

{
    echo "# Keybindings"
    echo
    echo "Generated from \`shared/stow/hypr/.config/hypr/keybindings.lua\` by"
    echo "\`shared/scripts/keybindings-md.sh\`. SUPER is the main modifier, MOD5 the right Alt."
    echo "Machine keys such as brightness live in each host overlay; personal binds in the"
    echo "profile's \`hypr.lua\`."
    echo
    echo "| Key | Action |"
    echo "| --- | --- |"
    awk '
        /^[[:space:]]*--/ { next }
        /hl\.bind\(/ {
            line = $0
            comment = ""
            if (match(line, /\)[[:space:]]*-- /)) {
                comment = substr(line, RSTART + RLENGTH)
                line = substr(line, 1, RSTART)
            }
            sub(/^[[:space:]]*hl\.bind\(/, "", line)
            sub(/,[[:space:]]+hl\./, ", hl.", line)
            split_at = index(line, ", hl.")
            key = substr(line, 1, split_at - 1)
            action = substr(line, split_at + 2)
            sub(/\)[[:space:]]*$/, "", action)

            gsub(/mod \.\. /, "SUPER", key)
            gsub(/alt \.\. /, "MOD5", key)
            gsub(/ \.\. key/, " 1..9, 0", key)
            gsub(/"/, "", key)
            gsub(/[[:space:]]+/, " ", key)

            if (comment == "") {
                gsub(/hl\.dsp\./, "", action)
                gsub(/exec_cmd\(app\(/, "run (", action)
                gsub(/exec_cmd\(/, "run (", action)
                gsub(/scripts \.\. "\//, "\"scripts/", action)
                gsub(/\|/, "\\|", action)
                action = "`" action "`"
            } else {
                action = comment
            }
            printf "| %s | %s |\n", key, action
        }
    ' "$SRC"
} > "$OUT"
