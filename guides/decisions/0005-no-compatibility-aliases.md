# ADR-0005: Destructive deprecation, no compatibility aliases

- **Status:** proposed
- **Date:** 2026-10-21
- **Scope:** suite-global

## Context

v2 moved every guide from `L0`–`L10` files to `guides/<domain>/` and moved
`USING_IN_EXISTING_REPOS.md` under `docs/`. The rationale was recorded in the v2 author survey, which was kept in the git-ignored `temp/` folder and no longer exists. **Author: restate the reason here before accepting.**

## Decision

A moved or renamed file leaves no alias, stub, or redirect at its old path. Deleted v1 paths stay
deleted; `check-sync.sh` fails if one comes back.

## Consequences

- **Good:** one location per file; no stale copy for an agent to read.
- **Bad / tradeoffs:** a consumer pointing at an old path breaks loudly until it re-copies.
- **Follow-ups:** `adapters/claude/skills/` moved to `adapters/skills/` the same way.
