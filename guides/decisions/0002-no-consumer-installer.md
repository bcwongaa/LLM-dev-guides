# ADR-0002: No consumer installer, updater, or package

- **Status:** accepted
- **Date:** 2026-08-15
- **Scope:** suite-global

## Context

The suite ships templates that adopting repos copy (`adapters/`). `scripts/gen-adapters.py`
regenerates them inside this repository.

An installer would write into other people's repos and need its own upgrade logic for every
project layout. Copying keeps adoption a diff a human reviews, and the suite stays documents plus
checks.

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
