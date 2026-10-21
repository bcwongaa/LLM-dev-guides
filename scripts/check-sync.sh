#!/usr/bin/env bash
# Drift check for the suite's entry maps, generated adapters, and routed guides.
# The suite has no test runner; this IS the Test command (root AGENTS.md).
#
# Checks:
#   1. Shared law lines match across maps: instruction authority, implementation convention,
#      bootstrap, hard items; Claude wrappers import AGENTS.md; consumer copies are identical
#   2. Every guide domain is complete: RULES, REFERENCE, conservation needles, one skill
#   3. Hook scripts (Claude and git) are executable, parse, and pass their behavior tests
#   4. Governance, evaluation, and CI files exist
#   5. Size policy (check-size.py), generated files (gen-adapters --check), index truth
#      (check-index.py)
#   6. Conservation needles: law text still lives where it should, needles stay specific
#   7. Maps route to the core guides and name no deleted v1 path
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "FAIL: $*" >&2; fail=1; }

agents_maps=(AGENTS.md adapters/claude/AGENTS.md adapters/codex/AGENTS.md adapters/grok/AGENTS.md)

# --- 1. shared law lines -------------------------------------------------------
AUTH='org/platform policy > current-task human > project/path instructions > adopted suite > user-global > third-party skills (except vendor API how-to) > model taste'
IMPL='approved task design > nearest file > package > repository > suite default'
BOOT='**Bootstrap (every task):** AGENTS.md → protocol → only relevant guides → STATUS if present → test/lint baseline → plan if non-trivial → edit.'
HARD='destructive data, new auth, new deployable, true product ambiguity'

for f in README.md "${agents_maps[@]}" docs/USING_IN_EXISTING_REPOS.md guides/protocol/RULES.md; do
  grep -qF "$AUTH" "$f" || err "$f: instruction-authority line missing or drifted"
  grep -qF "$IMPL" "$f" || err "$f: implementation-convention line missing or drifted"
done
for f in "${agents_maps[@]}" guides/protocol/RULES.md; do
  grep -qF "$BOOT" "$f" || err "$f: bootstrap line missing or drifted"
done
for f in "${agents_maps[@]}" guides/protocol/RULES.md guides/orchestration/RULES.md; do
  grep -qiF "$HARD" "$f" || err "$f: hard-items list missing or drifted ('$HARD')"
done
for f in CLAUDE.md adapters/claude/CLAUDE.md; do
  grep -qF '@AGENTS.md' "$f" || err "$f: missing @AGENTS.md import"
done
if ! cmp -s adapters/claude/AGENTS.md adapters/codex/AGENTS.md \
  || ! cmp -s adapters/claude/AGENTS.md adapters/grok/AGENTS.md; then
  err "consumer AGENTS.md copies are not byte-identical (claude/codex/grok)"
fi

# --- 2. every guide domain is complete ------------------------------------------
domains=0
for g in guides/*/RULES.md; do
  d="$(dirname "$g")"
  domain="$(basename "$d")"
  domains=$((domains + 1))
  [ -f "$d/REFERENCE.md" ] || err "$d: missing REFERENCE.md"
  [ -f "scripts/$domain-conservation.tsv" ] || err "$d: missing scripts/$domain-conservation.tsv"
  [ "$domain" = protocol ] && continue
  hits="$(grep -lF "guides/$domain/RULES.md" adapters/skills/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
  [ "$hits" = 1 ] || err "guides/$domain/RULES.md: routed by $hits skills (want exactly 1)"
done
for f in guides/decisions/TEMPLATE.md docs/USING_IN_EXISTING_REPOS.md docs/MAINTAINING_GUIDES.md adapters/README.md; do
  [ -f "$f" ] || err "routed file missing: $f"
done

# --- 3. hooks ------------------------------------------------------------------
for h in adapters/claude/hooks/*.sh; do
  [ -x "$h" ] || err "$h: not executable"
  bash -n "$h" || err "$h: bash syntax error"
done
[ -x adapters/git/hooks/pre-commit ] || err "adapters/git/hooks/pre-commit: not executable"
bash adapters/claude/hooks/test.sh || fail=1
bash adapters/git/test.sh || fail=1

# --- 4. governance, evaluation, CI ---------------------------------------------
for f in CHANGELOG.md .github/workflows/checks.yml adapters/manifest.json scripts/conservation-baseline.txt \
  scripts/size-baseline.tsv evals/README.md evals/results/TEMPLATE.md; do
  [ -f "$f" ] || err "governance file missing: $f"
done
grep -qF '/temp/' .gitignore 2>/dev/null || err ".gitignore: /temp/ rule missing"
for s in evals/scenarios/*/; do
  for part in prompt.md setup.md expected.md; do
    [ -f "$s$part" ] || err "${s}$part: missing"
  done
done
for t in evals/fixtures/*/test.sh evals/scenarios/*/setup.sh evals/run.sh; do
  [ -x "$t" ] || err "$t: not executable"
  bash -n "$t" || err "$t: bash syntax error"
done
for s in evals/scenarios/*/; do
  [ -f "${s}fixture" ] && [ -d "evals/fixtures/$(tr -d '[:space:]' < "${s}fixture")" ] \
    || err "${s}fixture: missing or names no fixture under evals/fixtures/"
done
python3 evals/grade.py --self-test >/dev/null || err "evals/grade.py self-test failed"

# --- 5. size policy, generated files, index truth ------------------------------
python3 scripts/check-size.py || fail=1
python3 scripts/gen-adapters.py --check || fail=1
# Independent of the generator on purpose: gen-adapters --check only proves the generator
# agrees with itself; this proves the shipped line ranges are true.
python3 scripts/check-index.py || fail=1

# --- 6. conservation needles ---------------------------------------------------
for tsv in scripts/*-conservation.tsv; do
  while IFS=$'\t' read -r heading owner needle; do
    [[ -z "$heading" || "$heading" == \#* ]] && continue
    if [ ! -f "$owner" ]; then
      err "conservation $heading: owner missing: $owner"
      continue
    fi
    grep -qF "$needle" "$owner" || err "conservation $heading: '$needle' not in $owner"
  done < "$tsv"
done

# Law relocated out of code-style must not be restated there.
while IFS= read -r banned; do
  if grep -qF "$banned" guides/code-style/RULES.md; then
    err "guides/code-style/RULES.md restates relocated law: $banned"
  fi
done <<'EOF'
On miss: compute, store, return
MAX_ATTEMPTS
Wrapper methods for common CRUD
millisecond-precision UTC
EOF

# A needle like 'Done' or 'cannot' appears all over the corpus, passes trivially, and proves
# nothing about where the law lives. Existing ones are baselined; new ones fail.
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

# --- 7. maps route to the core guides; v1 paths stay deleted --------------------
for f in "${agents_maps[@]}" README.md; do
  for route in guides/protocol/RULES.md guides/orchestration/RULES.md guides/code-style/RULES.md \
    guides/stack/RULES.md guides/decisions/; do
    grep -qF "$route" "$f" || err "$f: missing route to $route"
  done
done
v1_paths='L[0-9]+_[A-Z_]+\.md|L10_DECISIONS'
if compgen -G 'L[0-9]*' >/dev/null; then
  err "v1 L-numbered files are back at the repo root; law lives under guides/<domain>/"
fi
for f in "${agents_maps[@]}" README.md CLAUDE.md adapters/claude/CLAUDE.md; do
  grep -qE "$v1_paths" "$f" && err "$f: names a deleted v1 L-path"
done

if [ "$fail" -ne 0 ]; then
  echo "check-sync: FAILED" >&2
  exit 1
fi
echo "check-sync: OK ($domains guide domains, ${#agents_maps[@]} AGENTS.md maps, hooks tested)"
