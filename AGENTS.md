# AGENTS.md — project map (Codex + Grok Build)

**This file is a MAP.** Law lives in the LLM Dev Guides at repo root. Do not invent a parallel style or stack system.

This file is the shared entry for **Codex** and **Grok Build**. Keep it aligned with `CLAUDE.md`.

## GUIDES_ROOT

```text
GUIDES_ROOT=.
```

| Need | Open |
|---|---|
| Protocol (start, ask vs decide, done, handoff) | `L0_AGENT_PROTOCOL.md` |
| Code shape / smells | `L1_CODING_STYLE.md` |
| Language / framework / storage | `L3_LANGUAGE_AND_FRAMEWORK.md` |
| Other domains | `L{n}_*.md` / `L10_DECISIONS/` per L0 routing table |
| Adapter templates | `adapters/` |
| WIP multi-tool handoff | `docs/agent/STATUS.md` (if present) |
| Writing plan (temporary) | `GUIDE_PLAN.md` |

**Bootstrap (every task):** this file → L0 → only relevant L\* → STATUS if present → plan if non-trivial → edit.

**Conflict order:** local code > guides > third-party skills (except pure vendor API how-to) > model taste.

---

## Permissionless mode

This project is run with **always-approve / full auto** permissions. You may run commands and edit files freely **within L0 scope rules**.

Still **always ask** for: greenfield stack, new services, schema/API breaks, security/PII/secrets, ambiguous product intent, scope expansion — and before rewriting author-native guide voice without review.

---

## Exact commands

| Action | Command |
|---|---|
| Test | _(none — markdown suite; no test runner)_ |
| Lint | _(none required)_ |
| Build | _(none required)_ |
| Preview guides | read the target `L*.md` / `adapters/**` files |

When editing guides: match L1 density (decision trees, ✓/✗, anti-patterns, when to break). Consult author before inventing new layers or changing settled L0/L1/L3 law.

---

## Hard bans

- No drive-by refactors of unrelated guides
- No restating L1/L3 inside adapters
- No inventing missing L-layer rules as if they were v1
- Adapters stay thin maps only

## Done

Follow L0 definition of done. Summarize what changed; note open questions for author voice review when the text must “sound like me.”
