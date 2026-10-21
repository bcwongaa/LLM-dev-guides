# ADR-0011: TypeScript uses npm and Node.js

- **Status:** proposed
- **Date:** 2026-10-21
- **Scope:** suite-global

## Context

Stack REFERENCE: "TypeScript uses npm and runs on Node.js (not 'whatever package manager is
trendy')."

## Decision

TypeScript projects use npm as the package manager and Node.js as the runtime, with strict mode,
a formatter, and a linter. Yarn and pnpm are not used on greenfield.

## Consequences

- **Good:** one toolchain across repos; no lockfile format churn.
- **Bad / tradeoffs:** gives up features specific to other package managers and runtimes.
- **Follow-ups:** none.
