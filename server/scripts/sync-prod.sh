#!/usr/bin/env bash
# Bring the server's Claude setup in line with this laptop.
# Dotfiles and claude-config come from GitHub master, the vault and Claude
# state are mirrored from here. Run from the laptop: bash server/scripts/sync-prod.sh [host]
set -euo pipefail

HOST="${1:-prod}"
VAULT="${VAULT:-$HOME/vault}"
DOTFILES="$(cd "$(dirname "$0")/../.." && pwd)"

if [ -n "$(git -C "$DOTFILES" status --porcelain --untracked-files=no)" ]; then
    echo "note: local dotfiles has uncommitted changes, server gets origin/master" >&2
fi

remote() {
    set -euo pipefail
    if [ ! -d ~/dotfiles ]; then
        git clone --recurse-submodules git@github.com:TriTacLe/dotfiles.git ~/dotfiles
    fi
    git -C ~/dotfiles checkout -q master
    git -C ~/dotfiles pull -q --ff-only
    git -C ~/dotfiles submodule update --init --recursive
    # Track claude-config master, not the pin, so the server never lags the laptop.
    git -C ~/dotfiles/claude-config checkout -q master
    git -C ~/dotfiles/claude-config pull -q --ff-only

    echo server > ~/.dotfiles-role
    bash ~/dotfiles/install.sh

    if ! command -v claude >/dev/null 2>&1 && [ ! -x ~/.local/bin/claude ]; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi
    export PATH="$HOME/.local/bin:$PATH"

    if [ ! -f ~/.claude/settings.local.json ]; then
        cat > ~/.claude/settings.local.json <<'JSON'
{
  "additionalDirectories": [
    "~/dotfiles",
    "~/vault",
    "~/srv"
  ]
}
JSON
    fi
}

# -A forwards the laptop's ssh agent so the clones and pulls use its GitHub key.
ssh -A -t "$HOST" "$(declare -f remote); remote"

RSYNC=(rsync -a --info=stats1)
"${RSYNC[@]}" --delete \
    --exclude '.obsidian/workspace*' --exclude '.obsidian/cache/' \
    --exclude '.trash/' --exclude '.obsidian/.trash/' \
    "$VAULT/" "$HOST:vault/"

"${RSYNC[@]}" --delete "$HOME/.claude/lessons/" "$HOST:.claude/lessons/"
(cd "$HOME/.claude" && "${RSYNC[@]}" -R projects/*/memory/ "$HOST:.claude/")

if [ -f "$DOTFILES/claude-config/scripts/.env" ]; then
    "${RSYNC[@]}" "$DOTFILES/claude-config/scripts/.env" "$HOST:dotfiles/claude-config/scripts/.env"
fi

ssh -t "$HOST" 'PATH="$HOME/.local/bin:$PATH" bash ~/dotfiles/claude-config/scripts/bootstrap.sh'
echo "synced $HOST"
