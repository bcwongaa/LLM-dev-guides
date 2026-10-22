# ADR-0009: Postgres is the default relational store

- **Status:** accepted
- **Date:** 2026-07-11
- **Scope:** suite-global

## Context

Agents pick storage from fashion or the last framework demo they saw. The stack guide picks from
the nature of the data.

## Decision

Postgres is the default relational store and "almost always wins unless a rare niche forbids it"
(stack REFERENCE §Storage). MongoDB only for truly document-oriented data. Redis for cache and
coordination, never the system of record. SQLite only for localhost-only or single-process tools.

## Consequences

- **Good:** one boring, well-understood default; schema law (data guide) assumes it.
- **Bad / tradeoffs:** a niche that really needs another store must argue for it.
- **Follow-ups:** none.
