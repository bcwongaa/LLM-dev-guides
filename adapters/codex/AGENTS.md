# AGENTS.md — project map (Codex + shared)

**This file is a MAP.** Law lives in the LLM Dev Guides. Do not invent a parallel style or stack system.

Codex loads this file automatically. **Grok Build** also reads `AGENTS.md` — keep one shared map when both tools are used on the same repo.

## GUIDES_ROOT

```text
GUIDES_ROOT={{GUIDES_ROOT}}
```

Replace `{{GUIDES_ROOT}}` with the path to the suite (example: `../LLM-dev-guides` or `docs/llm-dev-guides`).  
Inside the suite repo itself, use `.`

| Need | Open |
|---|---|
| Protocol (start, ask vs decide, done, handoff) | `GUIDES_ROOT/L0_AGENT_PROTOCOL.md` |
| Code shape / smells | `GUIDES_ROOT/L1_CODING_STYLE.md` |
| Language / framework / storage | `GUIDES_ROOT/L3_LANGUAGE_AND_FRAMEWORK.md` |
| Other domains | `GUIDES_ROOT/L{n}_*.md` or `L10_DECISIONS/` per L0 routing table |
| WIP multi-tool handoff | `docs/agent/STATUS.md` (if present) |

**Bootstrap (every task):** this file → L0 → only relevant L\* → STATUS if present → plan if non-trivial → edit.

**Conflict order:** local code > guides > third-party skills (except pure vendor API how-to) > model taste.

---

## Permissionless mode

This project is run with **full auto / no interactive approval** for tool execution.  
You may run commands and edit files freely **within L0 scope rules**.

Still **always ask** (L0) for: greenfield stack, new services, schema/API breaks, security/PII/secrets, ambiguous product intent, scope expansion.

Permissionless ≠ autonomous product or architecture decisions.

---

## Exact commands

<!-- Fill per consumer project. Examples only — replace. -->

| Action | Command |
|---|---|
| Test | `{{TEST_CMD}}` |
| Lint | `{{LINT_CMD}}` |
| Typecheck / build | `{{BUILD_CMD}}` |
| Dev (if needed) | `{{DEV_CMD}}` |

If a cell is unknown, discover from `package.json` / Makefile / README — do not invent a second toolchain.

---

## Codex-only notes

- Prefer repo-local skills under `.agents/skills/` only when task-relevant; they do not override L\*.
- Do not maintain a second long instruction file (`CODEX.md`, etc.) that restates this map.
- Personal `~/.codex` prefs are fine; **project law** is this file + guides.

---

## Hard bans (protocol)

- No drive-by refactors or out-of-scope file edits
- No inventing missing L-layer rules
- No restating L1/L3 in this file — link and open the guide
- Tests must not be worse; run lint/typecheck when the project has them

## Done

Follow **L0 definition of done** and post-task check. Summarize what changed and what you deliberately did not touch.
