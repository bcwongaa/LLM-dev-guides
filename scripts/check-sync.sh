#!/usr/bin/env bash
# Drift check for the suite's entry maps, generated adapters, and routed guides.
# The suite has no test runner; this IS the Test command (root AGENTS.md).
#
# Checks:
#   1. Instruction-authority and implementation-convention lines match across maps
#   2. Bootstrap line is byte-identical across AGENTS.md maps (not Claude wrappers)
#   3. Hard-items list phrase matches across AGENTS.md maps and protocol/orchestration
#   4. Every file routed by the entry maps exists on disk
#   5. Hook scripts are executable and pass bash -n
#   6. v2 governance, size-budget, evaluation, fixture, and CI artifacts exist
#   7. Descriptive-guide cutover: new paths exist, old L0–L10 files are gone,
#      maps do not name deleted filenames, category ownership holds
#   8. Generated adapters/roots match scripts/gen-adapters.py --check
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "FAIL: $*" >&2; fail=1; }

# --- 1. two precedence systems -------------------------------------------
# Claude wrappers import AGENTS.md and must not restate these lines.
AUTH='org/platform policy > current-task human > project/path instructions > adopted suite > user-global > third-party skills (except vendor API how-to) > model taste'
IMPL='approved task design > nearest file > package > repository > suite default'
conflict_files=(
  README.md
  AGENTS.md
  adapters/claude/AGENTS.md
  adapters/codex/AGENTS.md
  adapters/grok/AGENTS.md
  docs/USING_IN_EXISTING_REPOS.md
  guides/protocol/RULES.md
)
for f in "${conflict_files[@]}"; do
  if ! grep -qF "$AUTH" "$f"; then
    err "$f: instruction-authority line missing or drifted"
  fi
  if ! grep -qF "$IMPL" "$f"; then
    err "$f: implementation-convention line missing or drifted"
  fi
done

# --- 2. bootstrap line across AGENTS.md maps -----------------------------
BOOT='**Bootstrap (every task):** this file → protocol → only relevant guides → STATUS if present → test/lint baseline → plan if non-trivial → edit.'
for f in AGENTS.md adapters/claude/AGENTS.md adapters/codex/AGENTS.md adapters/grok/AGENTS.md guides/protocol/RULES.md; do
  if ! grep -qF "$BOOT" "$f"; then
    err "$f: bootstrap line missing or drifted"
  fi
done

# --- 3. hard-items phrase --------------------------------------------------
HARD='destructive data, new auth, new deployable, true product ambiguity'
for f in AGENTS.md adapters/claude/AGENTS.md adapters/codex/AGENTS.md adapters/grok/AGENTS.md guides/protocol/RULES.md guides/orchestration/RULES.md; do
  if ! grep -qiF "$HARD" "$f"; then
    err "$f: hard-items list missing or drifted ('$HARD')"
  fi
done

# --- 3b. Claude wrappers import the shared map ---------------------------
for f in CLAUDE.md adapters/claude/CLAUDE.md; do
  if ! grep -qF '@AGENTS.md' "$f"; then
    err "$f: missing @AGENTS.md import"
  fi
done

# --- 3c. consumer AGENTS.md copies stay byte-identical -------------------
if ! cmp -s adapters/claude/AGENTS.md adapters/codex/AGENTS.md \
  || ! cmp -s adapters/claude/AGENTS.md adapters/grok/AGENTS.md; then
  err "consumer AGENTS.md copies are not byte-identical (claude/codex/grok)"
fi

# --- 4. routed files exist --------------------------------------------------
routed=(
  guides/protocol/RULES.md
  guides/protocol/REFERENCE.md
  guides/orchestration/RULES.md
  guides/orchestration/REFERENCE.md
  guides/code-style/RULES.md
  guides/code-style/REFERENCE.md
  guides/architecture/RULES.md
  guides/architecture/REFERENCE.md
  guides/stack/RULES.md
  guides/stack/REFERENCE.md
  guides/data/RULES.md
  guides/data/REFERENCE.md
  guides/contracts/RULES.md
  guides/contracts/REFERENCE.md
  guides/observability/RULES.md
  guides/observability/REFERENCE.md
  guides/testing/RULES.md
  guides/testing/REFERENCE.md
  guides/security/RULES.md
  guides/security/REFERENCE.md
  guides/release/RULES.md
  guides/release/REFERENCE.md
  guides/decisions/RULES.md
  guides/decisions/REFERENCE.md
  guides/decisions/TEMPLATE.md
  docs/USING_IN_EXISTING_REPOS.md
  adapters/README.md
  adapters/claude/AGENTS.md
  adapters/claude/CLAUDE.md
  adapters/codex/AGENTS.md
  adapters/grok/AGENTS.md
)
[ ! -e USING_IN_EXISTING_REPOS.md ] \
  || err "USING_IN_EXISTING_REPOS.md must live at docs/USING_IN_EXISTING_REPOS.md (no root alias)"
for f in "${routed[@]}"; do
  [ -f "$f" ] || err "routed file missing: $f"
done

# every skill points at a file that exists
for s in adapters/claude/skills/*/SKILL.md; do
  target="$(grep -oE 'GUIDES_ROOT/[A-Za-z0-9_./-]+\.md' "$s" | head -1 | sed 's|GUIDES_ROOT/||')"
  [ -n "$target" ] && [ -f "$target" ] || err "$s: routed guide '$target' missing"
done

# --- 5. hooks are sane -------------------------------------------------------
for h in adapters/claude/hooks/*.sh; do
  [ -x "$h" ] || err "$h: not executable"
  bash -n "$h" || err "$h: bash syntax error"
done

# --- 6. v2 governance baseline ----------------------------------------------
governance_files=(
  .gitignore
  CHANGELOG.md
  .github/workflows/checks.yml
  scripts/check-size.sh
  scripts/check-index.py
  scripts/conservation-baseline.txt
  guides/protocol/INDEX.tsv
  guides/code-style/INDEX.tsv
  scripts/size-baseline.tsv
  evals/README.md
  evals/fixtures/scope-guard/go.mod
  evals/fixtures/scope-guard/test.sh
  evals/results/TEMPLATE.md
  evals/scenarios/hard-escalation/prompt.md
  evals/scenarios/hard-escalation/setup.md
  evals/scenarios/hard-escalation/expected.md
  evals/scenarios/contradictory-instructions/prompt.md
  evals/scenarios/contradictory-instructions/setup.md
  evals/scenarios/contradictory-instructions/expected.md
  evals/scenarios/no-drive-bys/prompt.md
  evals/scenarios/no-drive-bys/setup.md
  evals/scenarios/no-drive-bys/expected.md
  evals/scenarios/no-drive-bys/allowed-paths.txt
  evals/scenarios/done-evidence/prompt.md
  evals/scenarios/done-evidence/setup.md
  evals/scenarios/done-evidence/expected.md
  evals/scenarios/live-code-task/prompt.md
  evals/scenarios/live-code-task/setup.md
  evals/scenarios/live-code-task/expected.md
  scripts/code-style-conservation.tsv
  scripts/protocol-conservation.tsv
  scripts/orchestration-conservation.tsv
  scripts/architecture-conservation.tsv
  scripts/stack-conservation.tsv
  scripts/data-conservation.tsv
  scripts/contracts-conservation.tsv
  scripts/observability-conservation.tsv
  scripts/testing-conservation.tsv
  scripts/security-conservation.tsv
  scripts/release-conservation.tsv
  scripts/decisions-conservation.tsv
  adapters/manifest.json
  scripts/gen-adapters.py
  adapters/claude/AGENTS.md
  docs/USING_IN_EXISTING_REPOS.md
)
for f in "${governance_files[@]}"; do
  [ -f "$f" ] || err "governance file missing: $f"
done

grep -qF '/temp/' .gitignore 2>/dev/null || err ".gitignore: /temp/ rule missing"

if [ -x scripts/check-size.sh ]; then
  bash scripts/check-size.sh || fail=1
else
  err "scripts/check-size.sh: missing or not executable"
fi

if [ -f scripts/gen-adapters.py ]; then
  python3 scripts/gen-adapters.py --check || fail=1
else
  err "scripts/gen-adapters.py: missing"
fi

[ -x evals/fixtures/scope-guard/test.sh ] || err "evals/fixtures/scope-guard/test.sh: not executable"

# --- 7. descriptive-guide cutover -------------------------------------------
[ ! -e L1_CODING_STYLE.md ] || err "L1_CODING_STYLE.md must be removed; law lives under guides/code-style/"
[ ! -e L0_AGENT_PROTOCOL.md ] || err "L0_AGENT_PROTOCOL.md must be removed; law lives under guides/protocol/"
[ ! -e L0_ORCHESTRATION.md ] || err "L0_ORCHESTRATION.md must be removed; law lives under guides/orchestration/"
[ ! -e L2_PROJECT_BOOTSTRAP.md ] || err "L2_PROJECT_BOOTSTRAP.md must be removed; law lives under guides/architecture/"
[ ! -e L3_LANGUAGE_AND_FRAMEWORK.md ] || err "L3_LANGUAGE_AND_FRAMEWORK.md must be removed; law lives under guides/stack/"
[ ! -e L4_DATA_MODEL.md ] || err "L4_DATA_MODEL.md must be removed; law lives under guides/data/"
[ ! -e L5_API_AND_CONTRACTS.md ] || err "L5_API_AND_CONTRACTS.md must be removed; law lives under guides/contracts/"
[ ! -e L6_OBSERVABILITY.md ] || err "L6_OBSERVABILITY.md must be removed; law lives under guides/observability/"
[ ! -e L7_TESTING.md ] || err "L7_TESTING.md must be removed; law lives under guides/testing/"
[ ! -e L8_SECURITY_AND_SECRETS.md ] || err "L8_SECURITY_AND_SECRETS.md must be removed; law lives under guides/security/"
[ ! -e L9_CHANGE_AND_RELEASE.md ] || err "L9_CHANGE_AND_RELEASE.md must be removed; law lives under guides/release/"
[ ! -e L10_DECISIONS ] || err "L10_DECISIONS/ must be removed; law lives under guides/decisions/"
if grep -v '^#' scripts/size-baseline.tsv | grep -q .; then
  err "scripts/size-baseline.tsv: migration baseline must be empty after L2–L10 cutover"
fi

route_files=(
  AGENTS.md
  README.md
  adapters/claude/AGENTS.md
  adapters/codex/AGENTS.md
  adapters/grok/AGENTS.md
  adapters/claude/skills/code-style/SKILL.md
)
for f in "${route_files[@]}"; do
  grep -qF 'guides/code-style/RULES.md' "$f" || err "$f: missing route to guides/code-style/RULES.md"
  if grep -qF 'L1_CODING_STYLE.md' "$f"; then
    err "$f: still names L1_CODING_STYLE.md"
  fi
done

for f in AGENTS.md README.md adapters/claude/AGENTS.md adapters/codex/AGENTS.md adapters/grok/AGENTS.md; do
  grep -qF 'guides/protocol/RULES.md' "$f" || err "$f: missing route to guides/protocol/RULES.md"
  grep -qF 'guides/orchestration/RULES.md' "$f" || err "$f: missing route to guides/orchestration/RULES.md"
  grep -qF 'guides/stack/RULES.md' "$f" || err "$f: missing route to guides/stack/RULES.md"
  grep -qF 'guides/decisions/' "$f" || err "$f: missing route to guides/decisions/"
  if grep -qE 'L0_AGENT_PROTOCOL\.md|L0_ORCHESTRATION\.md|L2_PROJECT_BOOTSTRAP\.md|L3_LANGUAGE_AND_FRAMEWORK\.md|L4_DATA_MODEL\.md|L5_API_AND_CONTRACTS\.md|L6_OBSERVABILITY\.md|L7_TESTING\.md|L8_SECURITY_AND_SECRETS\.md|L9_CHANGE_AND_RELEASE\.md|L10_DECISIONS' "$f"; then
    err "$f: still names a deleted L-path"
  fi
done

for tsv in scripts/*-conservation.tsv; do
  [ -f "$tsv" ] || continue
  while IFS=$'\t' read -r heading owner needle; do
    [[ -z "$heading" || "$heading" == \#* ]] && continue
    if [ ! -f "$owner" ]; then
      err "conservation $heading: owner missing: $owner"
      continue
    fi
    grep -qF "$needle" "$owner" || err "conservation $heading: '$needle' not in $owner"
  done < "$tsv"
done

if [ -f guides/code-style/RULES.md ]; then
  while IFS= read -r banned; do
    [ -z "$banned" ] && continue
    if grep -qF "$banned" guides/code-style/RULES.md; then
      err "guides/code-style/RULES.md restates relocated law: $banned"
    fi
  done <<'EOF'
On miss: compute, store, return
MAX_ATTEMPTS
Wrapper methods for common CRUD
millisecond-precision UTC
EOF
fi

# --- 9. granular pointer-skills ---------------------------------------------
# Skills are domain-named and carry a line-range index so Claude reads sections,
# not whole guides. The deleted L0-L10 numbering must not come back.
for d in adapters/claude/skills/*/; do
  base="$(basename "$d")"
  case "$base" in
    l[0-9]*) err "$d: outdated L-numbered skill id; skills are domain-named" ;;
  esac
done

for s in adapters/claude/skills/*/SKILL.md; do
  grep -qE '^[0-9]+-[0-9]+[[:space:]]' "$s" \
    || err "$s: missing section line-range index (granular routing)"
done

for g in guides/*/RULES.md; do
  d="$(dirname "$g")"
  [ -f "$d/INDEX.tsv" ] || err "$d: missing generated INDEX.tsv (tool-neutral section index)"
done

# Every claimed range must actually point at the section it names. Independent of
# the generator on purpose: gen-adapters --check only proves the generator agrees
# with itself, this proves the shipped numbers are true.
if [ -f scripts/check-index.py ]; then
  python3 scripts/check-index.py || fail=1
else
  err "scripts/check-index.py: missing"
fi

# Every non-protocol guide is reachable from exactly one skill.
for g in guides/*/RULES.md; do
  domain="$(basename "$(dirname "$g")")"
  [ "$domain" = protocol ] && continue
  hits="$(grep -lF "guides/$domain/RULES.md" adapters/claude/skills/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
  [ "$hits" = 1 ] || err "guides/$domain/RULES.md: routed by $hits skills (want exactly 1)"
done

# Install globs must not assume the old l* prefix.
for f in adapters/claude/skills/README.md adapters/claude/NOTES.md; do
  if grep -qF 'skills/l*' "$f"; then
    err "$f: install glob still assumes deleted l* skill prefix"
  fi
done

# --- 10. conservation needle strength (ratchet) ------------------------------
# A needle that appears all over the corpus ('Done', 'cannot') passes trivially and
# proves nothing about where the law lives. Existing ones are baselined; new ones fail.
weak="$(python3 - <<'EOF'
from pathlib import Path
rows=[]
for tsv in sorted(Path('scripts').glob('*-conservation.tsv')):
    for line in tsv.read_text().splitlines():
        if line.strip() and not line.startswith('#'):
            p=line.split('\t')
            if len(p)==3: rows.append(tuple(p))
allg=[p.read_text() for p in Path('guides').rglob('*.md')]
print(sum(1 for r in rows if sum(1 for t in allg if r[2] in t) > 3))
EOF
)"
baseline="$(grep -v '^#' scripts/conservation-baseline.txt | tr -d '[:space:]')"
if [ "$weak" -gt "$baseline" ]; then
  err "conservation: $weak needles too generic to localize law, baseline is $baseline (strengthen the new one)"
elif [ "$weak" -lt "$baseline" ]; then
  echo "note: conservation weak-needle count improved ($baseline -> $weak); lower scripts/conservation-baseline.txt"
fi

if [ "$fail" -ne 0 ]; then
  echo "check-sync: FAILED" >&2
  exit 1
fi
echo "check-sync: OK (${#conflict_files[@]} conflict-order copies, 3 adapters, ${#routed[@]} routed files, hooks clean)"
