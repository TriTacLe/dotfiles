#!/usr/bin/env bash
# Garbage-collect old Claude logs/caches/telemetry.
# Called from n8n workflow `log-gc.json` weekly, or manually.
# Closes claude-config/known-issues.md #3 (unbounded log growth).
set -u

# Delete files older than 90d under telemetry + cache.
find "$HOME/.claude/telemetry" "$HOME/.claude/cache" \
  -type f -mtime +90 -delete 2>/dev/null || true

# Truncate (don't delete) the active claude-note log so the next entry has a place to land.
: > "$HOME/.claude/hooks/claude-note.log" 2>/dev/null || true

exit 0
