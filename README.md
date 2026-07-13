# LLM Dev Guides

Agent-facing guides distilled from real codebase practice. Generated code and decisions
should match the author’s mental model, not generic “best practice.”

## Layers (L0–L10)

| Layer | File | Status |
|---|---|---|
| L0 | `L0_AGENT_PROTOCOL.md` | **v1** |
| L1 | `L1_CODING_STYLE.md` | **v1** |
| L2 | `L2_PROJECT_BOOTSTRAP.md` | **v1** |
| L3 | `L3_LANGUAGE_AND_FRAMEWORK.md` | **v1** |
| L4 | `L4_DATA_MODEL.md` | **v1** |
| L5 | `L5_API_AND_CONTRACTS.md` | **v1** |
| L6 | `L6_OBSERVABILITY.md` | **v1** |
| L7 | `L7_TESTING.md` | **v1** |
| L8 | `L8_SECURITY_AND_SECRETS.md` | **v1** |
| L9 | `L9_CHANGE_AND_RELEASE.md` | **v1** |
| L10 | `L10_DECISIONS/` | **v1 draft** (author review) |
| Adapters | `adapters/{claude,codex,grok}/` | **v1** |

This repo also has live entry maps: `CLAUDE.md`, `AGENTS.md` (`GUIDES_ROOT=.`).

## Writing plan (temporary)

See [`GUIDE_PLAN.md`](./GUIDE_PLAN.md) for consult history and remaining L10 work. Delete
that file when the suite is stable and this README is the only index.

## How to use

| Need | Open |
|---|---|
| How any agent should work (start, ask vs decide, done, handoff) | `L0_AGENT_PROTOCOL.md` |
| Code shape / smells | `L1_CODING_STYLE.md` |
| Greenfield layout / engines / domain split | `L2_PROJECT_BOOTSTRAP.md` |
| Language / framework / storage choice | `L3_LANGUAGE_AND_FRAMEWORK.md` |
| Schema, invariants, migrations, money/time | `L4_DATA_MODEL.md` |
| HTTP / events / DTOs / internal transport | `L5_API_AND_CONTRACTS.md` |
| Logs / metrics / traces / DB health | `L6_OBSERVABILITY.md` |
| Testing policy, TDD, pyramid, factories | `L7_TESTING.md` |
| Auth / PII / secrets / IDOR | `L8_SECURITY_AND_SECRETS.md` |
| Expand/contract, flags, rollback, deploy | `L9_CHANGE_AND_RELEASE.md` |
| Long-lived “why we chose X” (ADRs) | `L10_DECISIONS/README.md` + `TEMPLATE.md` |
| Tool entry templates | [`adapters/`](./adapters/) |

**Conflict order:** local code > these guides > third-party skills (except pure vendor API
how-to) > model taste.

**Bootstrap:** thin adapter (`CLAUDE.md` / `AGENTS.md`) → L0 → only the L\* files the task
needs → `docs/agent/STATUS.md` if present.
