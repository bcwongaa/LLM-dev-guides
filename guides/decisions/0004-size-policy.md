# ADR-0004: Size policy instead of fixed budgets

- **Status:** proposed
- **Date:** 2026-10-21
- **Scope:** suite-global
- **Supersedes:** the v2 "budgets" decision (fixed byte caps per file and per section)

## Context

Fixed byte caps became targets. Under an 8192 B cap every `RULES.md` ended at 8191 B, squeezed to
fit instead of written to be read. Any measurable counter turns into something the LLM optimizes
toward. The goal is files that are cheap to read and understandable, not files under a number.

## Decision

`scripts/check-size.py`, files only, bytes and lines, per kind:

- over the soft cap only: tolerated outlier, reported;
- over the soft cap and over mean + 1.5 SD of its kind: fails; split by topic or ask the author;
- over the hard cap (1,000 lines / 40 KB; RULES 16 KB): fails as a repo-wide refactor signal.

Mean and SD come from the last release, not live, because live stats drop the bar every time a
big file is split. Hard caps are the smallest single-read window of the three tools. 1.5 SD is
used because it is simple to explain. Always-loaded files keep only tool-enforced limits.

## Consequences

- **Good:** no fixed target to squeeze toward; the fix a failure asks for is a topic split.
- **Bad / tradeoffs:** stats must be recalculated at each release, and a new baseline can fail a
  file that passed before.
- **Follow-ups:** policy text in `docs/MAINTAINING_GUIDES.md`.
