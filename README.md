# LLM Dev Guides

Agent-facing guides distilled from real codebase practice. Goal: generated code and
decisions match the author’s mental model, not generic “best practice.”

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
| L8 | `L8_SECURITY_AND_SECRETS.md` | **v1 draft** (author review) |
| L9 | `L9_CHANGE_AND_RELEASE.md` | **v1** |
| L10 | `L10_DECISIONS/` | planned |
| Adapters | `adapters/{claude,codex,grok}/` | **v1** |

## Writing plan (temporary)

See [`GUIDE_PLAN.md`](./GUIDE_PLAN.md) for order of work, consult-then-draft workflow, and
per-layer notes. That file will be deleted when the suite is stable.

## How to use

| Need | Open |
|---|---|
| How any agent should work (start, ask vs decide, done, handoff) | `L0_AGENT_PROTOCOL.md` |
| Code shape / smells | `L1_CODING_STYLE.md` |
| Language / framework / storage choice | `L3_LANGUAGE_AND_FRAMEWORK.md` |
| Schema, invariants, migrations, money/time | `L4_DATA_MODEL.md` |
| Greenfield layout / engines / domain split | `L2_PROJECT_BOOTSTRAP.md` |
| Testing policy, TDD, pyramid, factories | `L7_TESTING.md` |
| HTTP / events / DTOs / contracts | `L5_API_AND_CONTRACTS.md` |
| Logs / metrics / traces / DB health | `L6_OBSERVABILITY.md` |
| Change / release / migrations rollout | `L9_CHANGE_AND_RELEASE.md` |
| Auth / PII / secrets (draft) | `L8_SECURITY_AND_SECRETS.md` |
| Long-lived decisions (ADRs) | L10 — not started |
| Tool entry templates | [`adapters/`](./adapters/) — this suite also has root `CLAUDE.md` / `AGENTS.md` |

**Conflict order (summary):** local code > these guides > third-party skills (except pure
vendor API how-to) > model taste.
