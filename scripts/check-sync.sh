#!/usr/bin/env bash
# Drift check for the suite's hand-duplicated entry-file fragments.
# The suite has no test runner; this IS the Test command (root CLAUDE.md / AGENTS.md).
#
# Checks:
#   1. Conflict-order one-liner is byte-identical everywhere it appears
#   2. Bootstrap line is byte-identical across the three adapter templates
#   3. Hard-items list phrase matches across adapters and L0_ORCHESTRATION
#   4. Every file routed by the entry maps exists on disk
#   5. Hook scripts are executable and pass bash -n
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "FAIL: $*" >&2; fail=1; }

# --- 1. conflict order ---------------------------------------------------
CANON='local code > guides > user-global tool files > third-party skills (except pure vendor API how-to) > model taste'
conflict_files=(
  README.md
  CLAUDE.md
  AGENTS.md
  adapters/claude/CLAUDE.md
  adapters/codex/AGENTS.md
  adapters/grok/AGENTS.md
  USING_IN_EXISTING_REPOS.md
  L0_AGENT_PROTOCOL.md
)
for f in "${conflict_files[@]}"; do
  if ! grep -qF "$CANON" "$f"; then
    err "$f: conflict-order line missing or drifted from canonical string"
  fi
done

# --- 2. bootstrap line across adapters -----------------------------------
BOOT='**Bootstrap (every task):** this file → L0 → only relevant L\* → STATUS if present → test/lint baseline → plan if non-trivial → edit.'
for f in adapters/claude/CLAUDE.md adapters/codex/AGENTS.md adapters/grok/AGENTS.md; do
  if ! grep -qF "$BOOT" "$f"; then
    err "$f: bootstrap line missing or drifted"
  fi
done

# --- 3. hard-items phrase --------------------------------------------------
HARD='destructive data, new auth, new deployable, true product ambiguity'
for f in adapters/claude/CLAUDE.md adapters/codex/AGENTS.md adapters/grok/AGENTS.md L0_ORCHESTRATION.md; do
  if ! grep -qiF "$HARD" "$f"; then
    err "$f: hard-items list missing or drifted ('$HARD')"
  fi
done

# --- 4. routed files exist --------------------------------------------------
routed=(
  L0_AGENT_PROTOCOL.md
  L0_ORCHESTRATION.md
  L1_CODING_STYLE.md
  L2_PROJECT_BOOTSTRAP.md
  L3_LANGUAGE_AND_FRAMEWORK.md
  L4_DATA_MODEL.md
  L5_API_AND_CONTRACTS.md
  L6_OBSERVABILITY.md
  L7_TESTING.md
  L8_SECURITY_AND_SECRETS.md
  L9_CHANGE_AND_RELEASE.md
  L10_DECISIONS/README.md
  L10_DECISIONS/TEMPLATE.md
  USING_IN_EXISTING_REPOS.md
  adapters/README.md
  adapters/claude/CLAUDE.md
  adapters/codex/AGENTS.md
  adapters/grok/AGENTS.md
)
for f in "${routed[@]}"; do
  [ -f "$f" ] || err "routed file missing: $f"
done

# every skill points at a file that exists
for s in adapters/claude/skills/l*/SKILL.md; do
  target="$(grep -o 'GUIDES_ROOT/L[0-9A-Z_]*\.md' "$s" | head -1 | sed 's|GUIDES_ROOT/||')"
  [ -n "$target" ] && [ -f "$target" ] || err "$s: routed guide '$target' missing"
done

# --- 5. hooks are sane -------------------------------------------------------
for h in adapters/claude/hooks/*.sh; do
  [ -x "$h" ] || err "$h: not executable"
  bash -n "$h" || err "$h: bash syntax error"
done

if [ "$fail" -ne 0 ]; then
  echo "check-sync: FAILED" >&2
  exit 1
fi
echo "check-sync: OK (${#conflict_files[@]} conflict-order copies, 3 adapters, ${#routed[@]} routed files, hooks clean)"
