# ADR-0012: No business logic in the database

- **Status:** proposed
- **Date:** 2026-10-21
- **Scope:** suite-global

## Context

Stack REFERENCE: "Application code owns behavior. The database stores and protects data."
Generation v3 aligned stack with the data guide's list of allowed database logic.

## Decision

No stored procedures, triggers, or mutating SQL implementing workflows, pricing or eligibility,
state machines, authorization, external calls, or orchestration. Allowed: constraints, indexes,
foreign keys, read-only views, side-effect-free projections, and generated columns that are a
pure derivation (data RULES §3).

## Consequences

- **Good:** behavior is testable and reviewable in application code.
- **Bad / tradeoffs:** some logic that would be fast in SQL runs in the app.
- **Follow-ups:** existing database routines are preserved, but not extended with new domain
  behavior.
