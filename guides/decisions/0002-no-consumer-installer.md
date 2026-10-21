# ADR-0002: No consumer installer, updater, or package

- **Status:** proposed
- **Date:** 2026-10-21
- **Scope:** suite-global

## Context

The suite ships templates that adopting repos copy (`adapters/`). `scripts/gen-adapters.py`
regenerates them inside this repository. The rationale was recorded in the v2 author survey, which was kept in the git-ignored `temp/` folder and no longer exists. **Author: restate the reason here before accepting.**

## Decision

No installer, updater, or package for consumer repos. `gen-adapters.py` updates this repository
only (`adapters/manifest.json`: "Not a consumer installer, package, or updater"). Consumers copy
templates by hand and re-copy to upgrade.

## Consequences

- **Good:** nothing from the suite runs inside a consumer repo; adoption stays a reviewable diff.
- **Bad / tradeoffs:** upgrades are manual. Since generation v3 the templates carry
  `LLM-dev-guides <version> (generation <gen>)`, so a repo can tell what it copied.
- **Follow-ups:** a Claude Code plugin marketplace would be an installer in all but name and
  would need an ADR superseding this one.
