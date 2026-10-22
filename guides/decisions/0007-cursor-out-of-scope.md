# ADR-0007: Cursor is out of scope

- **Status:** accepted
- **Date:** 2026-08-15
- **Scope:** suite-global

## Context

Settled in the v2 author survey, and still in force in v3.

## Decision

No Cursor adapter, and Cursor is not evaluated. The consumer `AGENTS.md` still works with any
tool that reads it, Cursor included, without an adapter (README).

## Consequences

- **Good:** effort stays on the three evaluated tools.
- **Bad / tradeoffs:** Cursor users get the shared map but no tool-specific mechanics.
- **Follow-ups:** none.
