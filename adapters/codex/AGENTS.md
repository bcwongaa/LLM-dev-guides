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
| Git flow / parallel agents / subagent briefs (only when orchestrating) | `GUIDES_ROOT/L0_ORCHESTRATION.md` |
| Code shape / smells | `GUIDES_ROOT/L1_CODING_STYLE.md` |
| Bugfix | `GUIDES_ROOT/L1` + `L7` (repro test) |
| Greenfield layout / engines / new deployable | `GUIDES_ROOT/L2_PROJECT_BOOTSTRAP.md` |
| Language / framework / storage | `GUIDES_ROOT/L3_LANGUAGE_AND_FRAMEWORK.md` |
| Schema / migrations / money / time | `GUIDES_ROOT/L4_DATA_MODEL.md` |
| HTTP / events / DTOs / versioning | `GUIDES_ROOT/L5_API_AND_CONTRACTS.md` |
| Logs / metrics / traces | `GUIDES_ROOT/L6_OBSERVABILITY.md` |
| Testing / TDD / factories / legacy pins | `GUIDES_ROOT/L7_TESTING.md` |
| Auth / PII / secrets / IDOR | `GUIDES_ROOT/L8_SECURITY_AND_SECRETS.md` |
| Flags / expand-contract / deploy | `GUIDES_ROOT/L9_CHANGE_AND_RELEASE.md` |
| Standing decisions (ADRs) | `GUIDES_ROOT/L10_DECISIONS/` |
| WIP multi-tool handoff | `docs/agent/STATUS.md` (if present) |

**Bootstrap (every task):** this file → L0 → only relevant L\* → STATUS if present → test/lint baseline → plan if non-trivial → edit.

**Conflict order:** local code > guides > user-global tool files > third-party skills (except pure vendor API how-to) > model taste.

---

## Permissionless mode

This project is run with **full auto / no interactive approval** for tool execution.  
You may run commands and edit files freely **within L0 scope rules**.

Still **always ask** (L0) for: greenfield stack, new services, schema/API breaks, security/PII/secrets, ambiguous product intent, scope expansion — **if you are the root session talking to the human**.

**If you are a subagent:** you **cannot** ask the human. Escalate always-ask items to your **parent** (options + recommendation). Parent decides or escalates; hard items (destructive data, new auth, new deployable, true product ambiguity) go human via root. See L0 parent/subagent rules.

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
