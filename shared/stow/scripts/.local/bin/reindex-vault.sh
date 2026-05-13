#!/usr/bin/env bash
# Re-index Obsidian vault for the Claude RAG pipeline.
# Called from n8n workflow `vault-reindex.json` on a daily cron, or manually.
set -eu
exec python3 "$HOME/.claude/rag/index_vault.py"
