# ADR-0007: Cursor is out of scope for v2

- **Status:** proposed
- **Date:** 2026-10-21
- **Scope:** suite-global

## Context

Recorded as settled in the v2 author survey. The rationale was recorded in the v2 author survey, which was kept in the git-ignored `temp/` folder and no longer exists. **Author: restate the reason here before accepting.**

## Decision

No Cursor adapter, and Cursor is not evaluated. The consumer `AGENTS.md` still works with any
tool that reads it, Cursor included, without an adapter (README).

## Consequences

- **Good:** effort stays on the three evaluated tools.
- **Bad / tradeoffs:** Cursor users get the shared map but no tool-specific mechanics.
- **Follow-ups:** **Author: the law generation is now v3. Confirm whether this holds for v3.**
