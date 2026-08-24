# Changelog

This repository uses generation labels rather than semantic versioning. Shared-law changes,
path migrations, and evaluation results are recorded here so an agent or maintainer can tell
which guide generation a project adopted.

## Unreleased — v2

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
