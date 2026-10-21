#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit|NotebookEdit): block file edits while the edited
# file's git worktree is on a protected base branch — enforces protocol "feature branch off the
# integration base" mechanically instead of as prose.
#
# The branch checked is the one holding the edited file, not the session's cwd: a scratch file,
# memory note, or plan outside any repo is not feature work, and a file in a feature-branch
# worktree is fine even if the session started on main.
#
# Escape hatches:
#   - GUIDES_ALLOW_BASE_EDITS=1  (env, e.g. via .claude/settings.json "env")
#   - file outside any git worktree, or detached HEAD → allow
set -uo pipefail

[ "${GUIDES_ALLOW_BASE_EDITS:-0}" = "1" ] && exit 0

input="$(cat 2>/dev/null || true)"
path="$(printf '%s' "$input" | sed -nE 's/.*"(file_path|notebook_path)"[[:space:]]*:[[:space:]]*"([^"]*)".*/\2/p' | head -n 1)"
if [ -n "$path" ]; then
  dir="$(dirname "$path")"
else
  dir="${CLAUDE_PROJECT_DIR:-.}"
fi
# A new file's directory may not exist yet; its nearest existing ancestor decides.
while [ ! -d "$dir" ] && [ "$dir" != "/" ] && [ "$dir" != "." ]; do dir="$(dirname "$dir")"; done

git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
branch="$(git -C "$dir" branch --show-current 2>/dev/null || true)"
[ -n "$branch" ] || exit 0   # detached HEAD (worktree/CI) — allow

protected="${GUIDES_PROTECTED_BRANCHES:-main master develop dev}"
for p in $protected; do
  if [ "$branch" = "$p" ]; then
    echo "Blocked by pre-edit-branch-guard.sh: ${path:-this edit} is in a worktree on protected base branch '$branch'." >&2
    echo "Protocol: feature work happens on a branch off the integration base." >&2
    echo "Create one first (see guides/orchestration/RULES.md), e.g.: git checkout -b feat/short-name" >&2
    echo "Human override for a deliberate trunk-only/hotfix flow: set GUIDES_ALLOW_BASE_EDITS=1." >&2
    exit 2
  fi
done

exit 0
