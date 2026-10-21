# ADR-0003: AGENTS.md is the canonical thin map; maps are generated

- **Status:** proposed
- **Date:** 2026-10-21
- **Scope:** suite-global

## Context

Three tools must load the same law. Codex and Grok Build read `AGENTS.md` natively; Claude Code
reads `CLAUDE.md`, and reads `AGENTS.md` itself only when no `CLAUDE.md` exists (2.1.277+).
Hand-maintained maps drifted in v1 (CHANGELOG v0.2).

## Decision

- `AGENTS.md` is the canonical shared map. It routes to the guides and restates no law beyond
  the shared lines (precedence, bootstrap, hard items).
- `CLAUDE.md` is `@AGENTS.md` plus Claude-only mechanics, never a second map.
- Both are generated from `adapters/manifest.json`. The three consumer `AGENTS.md` copies are
  byte-identical.

## Consequences

- **Good:** one source; `check-sync.sh` fails on drift.
- **Bad / tradeoffs:** a wording change to a shared line touches every map at once.
- **Follow-ups:** none.
