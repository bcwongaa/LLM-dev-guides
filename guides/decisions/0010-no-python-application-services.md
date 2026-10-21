# ADR-0010: No Python application services

- **Status:** proposed
- **Date:** 2026-10-21
- **Scope:** suite-global

## Context

Stack REFERENCE §Python: for application services, "long-context readability for humans is poor;
conventions often fight clear structure."

## Decision

Python is allowed for scripting, machine learning, and bulk data work. It is never a long-lived
application service or API on greenfield. Existing Python services are continued, not rewritten.

## Consequences

- **Good:** services stay in languages the author reads well over long contexts.
- **Bad / tradeoffs:** ML-adjacent services need a boundary between Python jobs and the service.
- **Follow-ups:** none.
