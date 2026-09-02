#!/usr/bin/env bash
# Context-budget gate for root maps and normative RULES.md files.
# Claude's effective startup is CLAUDE.md plus the imported AGENTS.md.
set -uo pipefail
cd "$(dirname "$0")/.."

ROOT_MAX_BYTES=12288
RULES_MAX_BYTES=8192
SKILL_MAX_BYTES=1800
SKILL_DESC_MAX_BYTES=1400
BASELINE_FILE=scripts/size-baseline.tsv
fail=0

err() { printf 'FAIL: %s\n' "$*" >&2; fail=1; }
file_bytes() { wc -c < "$1" | tr -d ' '; }
file_lines() { wc -l < "$1" | tr -d ' '; }

printf '%-48s %10s %10s %10s\n' FILE BYTES LIMIT LINES

root_maps=(
  AGENTS.md
  CLAUDE.md
  adapters/claude/AGENTS.md
  adapters/claude/CLAUDE.md
  adapters/codex/AGENTS.md
  adapters/grok/AGENTS.md
)
for f in "${root_maps[@]}"; do
  [ -f "$f" ] || { err "$f: root map missing"; continue; }
  bytes="$(file_bytes "$f")"
  lines="$(file_lines "$f")"
  printf '%-48s %10s %10s %10s\n' "$f" "$bytes" "$ROOT_MAX_BYTES" "$lines"
  [ "$bytes" -le "$ROOT_MAX_BYTES" ] || err "$f: $bytes bytes exceeds root budget $ROOT_MAX_BYTES"
done

effective_claude() {
  local agents="$1" claude="$2" label="$3"
  [ -f "$agents" ] && [ -f "$claude" ] || { err "$label: missing $agents or $claude"; return; }
  if ! grep -qF '@AGENTS.md' "$claude"; then
    err "$claude: missing @AGENTS.md import (effective Claude startup undefined)"
    return
  fi
  local a c total
  a="$(file_bytes "$agents")"
  c="$(file_bytes "$claude")"
  total=$((a + c))
  printf '%-48s %10s %10s %10s\n' "$label" "$total" "$ROOT_MAX_BYTES" "-"
  [ "$total" -le "$ROOT_MAX_BYTES" ] || err "$label: $total bytes exceeds root budget $ROOT_MAX_BYTES"
}

effective_claude AGENTS.md CLAUDE.md "effective:suite-claude"
effective_claude adapters/claude/AGENTS.md adapters/claude/CLAUDE.md "effective:consumer-claude"

while IFS=$'\t' read -r path limit; do
  [[ -z "$path" || "$path" == \#* ]] && continue
  [ -f "$path" ] || continue
  bytes="$(file_bytes "$path")"
  lines="$(file_lines "$path")"
  printf '%-48s %10s %10s %10s\n' "$path" "$bytes" "$limit" "$lines"
  [ "$bytes" -le "$limit" ] || err "$path: $bytes bytes exceeds migration baseline $limit"
done < "$BASELINE_FILE"

while IFS= read -r f; do
  bytes="$(file_bytes "$f")"
  lines="$(file_lines "$f")"
  printf '%-48s %10s %10s %10s\n' "$f" "$bytes" "$RULES_MAX_BYTES" "$lines"
  [ "$bytes" -le "$RULES_MAX_BYTES" ] || err "$f: $bytes bytes exceeds RULES.md budget $RULES_MAX_BYTES"
done < <(find guides -type f -name RULES.md -print 2>/dev/null | sort)

# Pointer-skill bodies load on match; keep each one cheap.
while IFS= read -r f; do
  bytes="$(file_bytes "$f")"
  lines="$(file_lines "$f")"
  printf '%-48s %10s %10s %10s\n' "$f" "$bytes" "$SKILL_MAX_BYTES" "$lines"
  [ "$bytes" -le "$SKILL_MAX_BYTES" ] || err "$f: $bytes bytes exceeds SKILL.md budget $SKILL_MAX_BYTES"
done < <(find adapters/claude/skills -type f -name SKILL.md -print 2>/dev/null | sort)

# Descriptions sit in context for every session whether or not a skill fires.
desc_bytes="$(cat adapters/claude/skills/*/SKILL.md 2>/dev/null \
  | grep -E '^(name|description):' | wc -c | tr -d ' ')"
printf '%-48s %10s %10s %10s\n' "effective:skill-descriptions" "$desc_bytes" "$SKILL_DESC_MAX_BYTES" "-"
[ "$desc_bytes" -le "$SKILL_DESC_MAX_BYTES" ] \
  || err "skill descriptions: $desc_bytes bytes exceeds always-in-context budget $SKILL_DESC_MAX_BYTES"

if [ "$fail" -ne 0 ]; then
  echo 'check-size: FAILED' >&2
  exit 1
fi

echo 'check-size: OK'
