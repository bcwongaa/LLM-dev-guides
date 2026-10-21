# Changelog

Releases are marked by git tag (`v0.1`, `v0.2`, …). **Generation labels** (`v1`, `v2`) mark
law generations, and move only when shared law changes — a release may leave the generation
untouched. Shared-law changes, path migrations, and evaluation results are recorded here so an
agent or maintainer can tell which guide generation a project adopted.

## Unreleased (generation v2)

Governance and retrieval only; no shared law changed.

### Governance

- Replaced the fixed byte budgets with a size policy: a soft cap, an outlier bar at mean + 1.5 SD
  of the file's kind, and a hard cap: 40 KB, Codex's single-read window, and 1,600 lines as a
  brake on drift. The fixed caps had become targets: every `RULES.md` sat at 8191 B of
  8192 B. Stats come from the last release, not live, so splitting one file does not fail the
  next. Policy and reasons: `docs/MAINTAINING_GUIDES.md`. `check-size.sh` became
  `check-size.py`, and `scripts/size-baseline.tsv` now holds the per-kind stats.
- Dropped the per-section, `SKILL.md`, `INDEX.tsv`, and description-total budgets. The limits
  the tools enforce remain: 32 KiB per `AGENTS.md` (Codex) and 1,024 characters per skill
  description (Agent Skills).

### Retrieval

- The `INDEX.tsv` bytes column counted characters, not bytes. The guides are dense with 3-byte
  `✓ ✗ → —`, so 320 of 397 rows were low; one orchestration section was 6658 B, not 6502 B.
- Indexed the preamble before each file's first heading. Each guide's scope line lives there and
  was unreachable by range reads.
- `INDEX.tsv` headers show the shell read form (`sed -n 'START,ENDp'`) next to Claude's, and
  state that RULES wins over REFERENCE on any conflict. Skills say the same.
- `guides/data/RULES.md` "Complete" heading was glued to the end of the scope line, so the data
  done bar was missing from the index and the data skill. `check-index.py` now fails on a `## `
  heading glued to text.

### Claude hooks

- The branch guard checks the worktree that holds the edited file, not the session's cwd. It
  used to block edits to scratch, memory, and plan files outside the repo whenever the repo
  was on `main`.
- The Stop gate blocks only when tests got worse than the baseline recorded at session start
  (new `stop-test-gate.sh baseline` on SessionStart `startup`), matching protocol's "not worse"
  instead of "green". It skips runs on an unchanged tree, and treats an unfilled
  `{{TEST_CMD}}` as unset instead of blocking every stop with exit 127.
- Hook commands use `"$CLAUDE_PROJECT_DIR"`; relative paths broke once the session changed
  directory.
- Added `adapters/claude/hooks/test.sh`, run by `check-sync.sh`. CI runs with read-only
  repository permissions.

### Cleanup

- Retired the one-time v2 migration checks in `check-sync.sh` (each deleted L-file by name, the
  empty-baseline assertion, l*-skill ids, checks that `check-index.py` and `gen-adapters --check`
  already make). One glob still keeps v1 L-files out. About 330 lines became 160, verified by
  mutation tests.
- Consumer templates carry `LLM-dev-guides <version> (generation <gen>)` instead of "do not edit",
  which they must be. `adapters/manifest.json` holds `version` and `generation`;
  `docs/MAINTAINING_GUIDES.md` gains *Cutting a release*.
- The bootstrap line names `AGENTS.md` instead of "this file", which inside protocol pointed at
  protocol itself.
- The adoption smoke test expected the retired v1 `local code > guides` answer; it now expects
  both v2 precedence lines. Fixed dangling pointers to code-style §19/§20 and "protocol → Local
  convention". Dropped hard-coded counts from `MAINTAINING_GUIDES.md`.
- The suite `CLAUDE.md` called the hooks active; they are consumer templates, not installed here.

### Evaluations

- Added `evals/fixtures/billing/`, a Go module with customers, invoices, a public DTO, an authz
  boundary, and a `packages/billing/` with its own `AGENTS.md`, a local money convention, a float
  formatting bug, and a nearby never-list defect. `hard-escalation` and
  `contradictory-instructions` had no fixture before and could not run.
- Added `evals/run.sh`: fixture → fresh git repo → consumer adapters → scenario `setup.sh` →
  headless Claude Code, Codex, or Grok Build → transcript, diff, changed files, test output.
  `--no-suite` runs the ablation, and `EVAL_DRY_RUN=1` skips the agent. Workspaces live outside
  the suite, because Claude Code loads every parent `CLAUDE.md`.
- Added `evals/grade.py`. It checks scope against `allowed-paths.txt`, tests, whether a test ran
  before the first edit, and whether the final message asks; the verdict stays with the author.
  Scenarios gained `fixture`, `allowed-paths.txt`, and, where needed, `setup.sh`.
- `scope-guard` gained cleanup bait outside the allowed paths. CI tests every fixture.

### Guides

- Split code-style REFERENCE §7 Naming and §12 `get` / `ensureGet` into
  `guides/code-style/REFERENCE-naming.md`, by topic. The generator indexes `REFERENCE-*.md`.
- Strengthened the `naming-get` conservation needle from `ensureGet`, which the split's stub
  made too generic.

## v0.2.1 — 2026-09-02 (generation v2)

Retrieval and governance only; no shared law changed, so the generation stays v2.

### Contributor docs

- Added `docs/MAINTAINING_GUIDES.md`: what is generated, when to regenerate, the budgets and
  why the section ones matter, how to decide whether a section may be split, and the
  conservation-needle rules. Routed from `AGENTS.md`.
- `gen-adapters --check` and `check-index.py` now print the remedy in their failure output
  (`python3 scripts/gen-adapters.py --write`) instead of only reporting drift — editing a
  guide without regenerating was six cryptic errors and no stated fix.

### Retrieval

- Moved the generated section index out of the Claude adapter into `guides/<domain>/INDEX.tsv`,
  so Codex and Grok reach it too. Adapters carry no tool-neutral data (`AGENTS.md` hard ban).
- Indexed `REFERENCE.md` (221 KB, 213 sections) alongside `RULES.md`; skills route to it via
  `INDEX.tsv` instead of naming the whole file.
- Indexed `guides/protocol/` — the always-loaded, four-times-re-read file previously had no
  granular access despite being the largest per-task context cost.
- `[suite-default]` / `[common]` tags became a queryable `INDEX.tsv` column instead of prose
  metadata that nothing consumed.
- Made the heading parser fence-aware; 7 `## ` lines inside ```markdown template blocks in
  `REFERENCE.md` would otherwise have shifted every following range.
- Added `scripts/check-index.py`: verifies every claimed range against the guides with a
  parser independent of the generator (564 claims). `gen-adapters --check` alone only proves
  the generator agrees with itself.

### Guides

- Split `orchestration/REFERENCE.md` "Parent / subagent authority (detail)" (7761 B, 10x the
  median section) at its safety seam: the escalation chain stays one unit (5595 B) because
  partial reads of interlocking authority rules are worse than a long read, while the two
  parts with no safety coupling — brief/result templates (815 B) and orchestrator checklist
  (1347 B) — became addressable sections. Fetching the brief template no longer costs 7761 B.

- Split `observability/REFERENCE.md` §7 "Data observability" (7190 B, 5-10x its siblings) into
  five sections. Unlike the orchestration authority chain this is a taxonomy of independent
  capabilities, and each subsection already restates its own guard, so partial reads cost
  waste rather than a safety gap. The conditional gate ("do not require a five-signal platform
  for every CRUD table") stays attached to the definition; max section 7190 -> 2876.
- Promoted subsection titles carry the "Data observability:" topic prefix so they stay
  self-describing as index labels and do not collide with "Relationship to other layers".

### Governance

- Added per-section budgets (1900 B RULES, 6552 B REFERENCE) sourced from the verified
  `INDEX.tsv` byte column — the section is what a task reads, so the per-file 8 KB cap is now
  only a sprawl backstop.
- Added budgets for `SKILL.md` (1800 B), `INDEX.tsv` (4096 B), and skill descriptions
  (1400 B, the always-in-context cost).
- Added a conservation-needle strength ratchet: 38 of 290 needles are too generic to localize
  law ('Done', 'cannot'); the count may fall, never rise.

- Pointer-skills now route to guide **sections**, not whole files: each `SKILL.md` carries a
  generated line-range index of its guide's `## ` headings, read via `Read(offset, limit)`.
- Sharded the index per domain rather than one global index, so a session loads only the
  shard it matched and added guides never cost more per lookup.
- Renamed skill ids from the deleted `l1`–`l9` numbering to domain names matching
  `guides/<domain>/`; fixed the `skills/l*` install globs the rename broke.
- Added pointer-skills for `orchestration` and `decisions`, which previously had none.
- Added `check-size.sh` budgets: 1800 B per `SKILL.md`, 1400 B for all skill descriptions
  (the always-in-context cost).
- `check-sync.sh` now fails on stale line ranges, L-numbered skill ids, guides routed by
  zero or multiple skills, and install globs assuming the old prefix.

## v0.2 — 2026-09-02 (generation v2)

### Governance

- Added deterministic context-size measurement and migration baselines.
- Added public behavioral evaluation scenarios and a compiled fixture.
- Added CI for the repository's structural checks and fixture tests.
- Included the live root maps in bootstrap-drift detection.

### Guides

- Code-style §7 now binds local, field, and destructured names (named bindings): domain noun
  on live names, type sort on fields, spoken noun on locals, canonical-name handoff
  (`_user` → `user`, TS rendering).
- Migrated coding-style law from `L1_CODING_STYLE.md` to `guides/code-style/{RULES.md,REFERENCE.md}`.
- Relocated cache / bounded polling / async dispatch to `guides/architecture/`.
- Relocated two-tier data access to `guides/data/`.
- Relocated default log line shape to `guides/observability/`.
- Deleted `L1_CODING_STYLE.md` with no compatibility alias.
- Migrated protocol law from `L0_AGENT_PROTOCOL.md` to `guides/protocol/{RULES.md,REFERENCE.md}`.
- Migrated orchestration law from `L0_ORCHESTRATION.md` to `guides/orchestration/{RULES.md,REFERENCE.md}`.
- Split instruction authority from brownfield implementation convention.
- Deleted `L0_AGENT_PROTOCOL.md` and `L0_ORCHESTRATION.md` with no compatibility aliases.
- Migrated architecture law from `L2_PROJECT_BOOTSTRAP.md` to `guides/architecture/{RULES.md,REFERENCE.md}`.
- Migrated stack law from `L3_LANGUAGE_AND_FRAMEWORK.md` to `guides/stack/{RULES.md,REFERENCE.md}`.
- Migrated data law from `L4_DATA_MODEL.md` to `guides/data/{RULES.md,REFERENCE.md}`.
- Migrated contracts law from `L5_API_AND_CONTRACTS.md` to `guides/contracts/{RULES.md,REFERENCE.md}`.
- Migrated observability law from `L6_OBSERVABILITY.md` to `guides/observability/{RULES.md,REFERENCE.md}`.
- Migrated testing law from `L7_TESTING.md` to `guides/testing/{RULES.md,REFERENCE.md}`.
- Migrated security law from `L8_SECURITY_AND_SECRETS.md` to `guides/security/{RULES.md,REFERENCE.md}`.
- Migrated release law from `L9_CHANGE_AND_RELEASE.md` to `guides/release/{RULES.md,REFERENCE.md}`.
- Migrated standing-decision process from `L10_DECISIONS/` to `guides/decisions/`.
- Deleted `L2`–`L9` files and `L10_DECISIONS/` with no compatibility aliases.
- Emptied `scripts/size-baseline.tsv`; remaining files use the hard 12KB / 8KB budgets.

### Roots and adapters

- `AGENTS.md` is the canonical shared map. `CLAUDE.md` is `@AGENTS.md` plus Claude-only mechanics.
- Consumer `AGENTS.md` copies under `adapters/{claude,codex,grok}/` are generated and byte-identical.
- Pointer-skills are generated from `adapters/manifest.json` via `scripts/gen-adapters.py`.
- The generator updates this repository only. It is not a consumer installer. Hooks stay hand-authored.
- Moved `USING_IN_EXISTING_REPOS.md` to `docs/USING_IN_EXISTING_REPOS.md` with no root alias.

### Planned breaking changes

- Live behavioral evaluations on Claude Code, Codex, and Grok Build before the `v2` tag.
- Author verdict on public eval results and remaining author-voice review.

## v1 — 2026-08-13

Baseline generation at commit `0ce10bb94bc7f12ea00f0dc43872890dfda59ed4`.

- Shared L0–L10 engineering guidance.
- Thin Claude Code, Codex, and Grok Build adapters.
- Claude pointer skills and deterministic lifecycle hooks.
- Structural drift check through `bash scripts/check-sync.sh`.
