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
| Git flow / parallel agents / subagent briefs | `L0_ORCHESTRATION.md` (only when orchestrating) |
| Code shape / smells | `L1_CODING_STYLE.md` |
| Language / framework / storage | `L3_LANGUAGE_AND_FRAMEWORK.md` |
| Other domains | `L{n}_*.md` / `L10_DECISIONS/` per L0 routing table |
| Adapter templates | `adapters/` |
| Adopt suite in existing apps | `USING_IN_EXISTING_REPOS.md` |
| ADRs | `L10_DECISIONS/` |
| WIP multi-tool handoff | `docs/agent/STATUS.md` (if present) |

**Bootstrap (every task):** this file → L0 → only relevant L\* → STATUS if present → plan if non-trivial → edit.

**Conflict order:** local code > guides > user-global tool files > third-party skills (except pure vendor API how-to) > model taste.

---

## Permissionless mode

This project is run with **always-approve / full auto** permissions. You may run commands and edit files freely **within L0 scope rules**.

Still **always ask** for: greenfield stack, new services, schema/API breaks, security/PII/secrets, ambiguous product intent, scope expansion — and before rewriting author-native guide voice without review — **if you are the root session**.

**If you are a subagent:** escalate always-ask items to your **parent** (you cannot ask the human). See L0.

---

## Exact commands

| Action | Command |
|---|---|
| Test | `bash scripts/check-sync.sh` (entry-file drift + routing-target check) |
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
