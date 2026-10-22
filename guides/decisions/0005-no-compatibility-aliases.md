# ADR-0005: Destructive deprecation, no compatibility aliases

- **Status:** accepted
- **Date:** 2026-08-15
- **Scope:** suite-global

## Context

v2 moved every guide from `L0`–`L10` files to `guides/<domain>/` and moved
`USING_IN_EXISTING_REPOS.md` under `docs/`.

An alias leaves two paths to the same law. An agent can land on the old one, and aliases pile up
because no one knows when it is safe to delete them. A clean break fails loudly once, and
adopting repos update.

## Decision

A moved or renamed file leaves no alias, stub, or redirect at its old path. Deleted v1 paths stay
deleted; `check-sync.sh` fails if one comes back.

## Consequences

- **Good:** one location per file; no stale copy for an agent to read.
- **Bad / tradeoffs:** a consumer pointing at an old path breaks loudly until it re-copies.
- **Follow-ups:** `adapters/claude/skills/` moved to `adapters/skills/` the same way.
