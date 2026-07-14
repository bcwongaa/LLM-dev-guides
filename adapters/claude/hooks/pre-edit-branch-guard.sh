#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit|NotebookEdit): block file edits while
# HEAD is on a protected base branch — enforces L0 "feature branch off the integration
# base" mechanically instead of as prose.
#
# Escape hatches:
#   - GUIDES_ALLOW_BASE_EDITS=1  (env, e.g. via .claude/settings.json "env")
#   - not a git repo, or detached HEAD → allow
set -euo pipefail

[ "${GUIDES_ALLOW_BASE_EDITS:-0}" = "1" ] && exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
branch="$(git branch --show-current 2>/dev/null || true)"
[ -n "$branch" ] || exit 0   # detached HEAD (worktree/CI) — allow

protected="${GUIDES_PROTECTED_BRANCHES:-main master develop dev}"
for p in $protected; do
  if [ "$branch" = "$p" ]; then
    echo "Blocked by pre-edit-branch-guard.sh: HEAD is on protected base branch '$branch'." >&2
    echo "L0 protocol: feature work happens on a branch off the integration base." >&2
    echo "Create one first (see L0_ORCHESTRATION.md), e.g.: git checkout -b feat/short-name" >&2
    echo "Human override for a deliberate trunk-only/hotfix flow: set GUIDES_ALLOW_BASE_EDITS=1." >&2
    exit 2
  fi
done

exit 0
