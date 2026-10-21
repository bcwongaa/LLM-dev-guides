#!/usr/bin/env bash
# Install the conflicting third-party skill where each tool looks for project skills.
# The user-global preference (user-global.md) is NOT installed: the runner never edits your home
# directory. See evals/README.md.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
for dir in .claude/skills/house-style .agents/skills/house-style; do
  mkdir -p "$dir"
  cp "$here/third-party-skill.md" "$dir/SKILL.md"
done
