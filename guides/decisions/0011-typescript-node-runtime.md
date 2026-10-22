# ADR-0011: TypeScript runs on Node.js; npm on greenfield

- **Status:** accepted
- **Date:** 2026-10-22 (npm and Node.js since 2026-07-11)
- **Scope:** suite-global

## Context

TypeScript needs one default runtime that will still be developed years from now.

- Node.js was, is, and is expected to remain the most widely used server-side JavaScript runtime
  (author's judgment).
- Deno's team joined Cloudflare on 2026-10-09. The Deno runtime gets bug-fix and security
  releases for one more year, then its development ends, around October 2027; Deno Deploy shuts
  down within about six months (deno.com/blog/cloudflare).
- Bun has been owned by Anthropic since 2025-12-02 (bun.com/blog/bun-joins-anthropic).

Stack REFERENCE already said "TypeScript uses npm and runs on Node.js (not 'whatever package
manager is trendy')."

## Decision

- **Runtime:** Node.js wherever possible. Greenfield TypeScript runs on Node.js, not Bun or Deno.
- **Package manager:** npm on greenfield. An existing repo keeps its package manager.
- **Existing Bun repo:** keep Bun. Do not migrate it.
- **Existing Deno repo:** ask the author about moving to Node.js before building further on it.
  Do not migrate it unasked; a runtime change is a stack decision.

## Consequences

- **Good:** the default runtime does not depend on one company's plans.
- **Bad / tradeoffs:** greenfield gives up Bun's speed and Deno's built-in tooling; Deno repos
  face a migration decision before October 2027.
- **Follow-ups:** the rule lives in `guides/stack/RULES.md` *Tooling*.
