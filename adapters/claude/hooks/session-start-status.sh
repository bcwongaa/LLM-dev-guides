#!/usr/bin/env bash
# SessionStart hook: inject docs/agent/STATUS.md (and per-workstream STATUS files)
# into context so WIP handoff is never silently skipped (L0 bootstrap step 4).
set -euo pipefail

dir="docs/agent"
[ -d "$dir" ] || exit 0

found=0
for f in "$dir"/STATUS.md "$dir"/STATUS-*.md; do
  [ -f "$f" ] || continue
  if [ "$found" -eq 0 ]; then
    echo "=== Agent handoff (auto-injected by session-start-status.sh; L0 requires reading STATUS) ==="
    found=1
  fi
  echo
  echo "--- $f ---"
  cat "$f"
done

exit 0
