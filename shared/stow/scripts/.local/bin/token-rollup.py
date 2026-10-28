#!/usr/bin/env python3
import json
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

JSONL = Path.home() / ".claude/cache/token-cost.jsonl"
PRICES = Path.home() / ".claude/cache/model-prices.json"

def main():
    if not JSONL.exists():
        print("No token-cost.jsonl yet. Run a Claude session first.")
        return

    try:
        prices = json.loads(PRICES.read_text()) if PRICES.exists() else {}
    except Exception:
        prices = {}

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    rows = []
    estimated_count = 0
    with JSONL.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except Exception:
                continue
            if r.get("ts", "").startswith(today):
                rows.append(r)
                if r.get("tokens_estimated"):
                    estimated_count += 1

    if not rows:
        print(f"No rows for today ({today}).")
        return

    by_model = defaultdict(lambda: {"prompt": 0, "completion": 0, "cost": 0.0, "calls": 0})
    for r in rows:
        m = r.get("model", "unknown")
        by_model[m]["prompt"] += r.get("prompt_tokens", 0)
        by_model[m]["completion"] += r.get("completion_tokens", 0)
        by_model[m]["cost"] += r.get("cost_usd", 0.0)
        by_model[m]["calls"] += 1

    total_cost = sum(v["cost"] for v in by_model.values())

    print(f"Token spend - {today}")
    print(f"  Total: ${total_cost:.4f} USD  ({len(rows)} tool calls)")
    if estimated_count:
        print(f"  Note: {estimated_count}/{len(rows)} rows used bytes/4 token estimate")
    print()
    for model, v in sorted(by_model.items(), key=lambda x: -x[1]["cost"]):
        p = prices.get(model, {})
        rate = f"${p.get('prompt', 0):.2f}/${p.get('completion', 0):.2f} per 1M" if p else "no price data"
        print(f"  {model}")
        print(f"    {v['calls']} calls  {v['prompt']:,} prompt + {v['completion']:,} completion tokens")
        print(f"    ${v['cost']:.4f}  ({rate})")

if __name__ == "__main__":
    main()
