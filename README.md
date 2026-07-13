# LLM Dev Guides

Agent-facing guides distilled from real codebase practice. Goal: generated code and
decisions match the author’s mental model, not generic “best practice.”

## Layers (L0–L10)

| Layer | File | Status |
|---|---|---|
| L0 | `L0_AGENT_PROTOCOL.md` | **v1** |
| L1 | `L1_CODING_STYLE.md` | **v1** |
| L2 | `L2_PROJECT_BOOTSTRAP.md` | planned |
| L3 | `L3_LANGUAGE_AND_FRAMEWORK.md` | **v1** |
| L4 | `L4_DATA_MODEL.md` | planned |
| L5 | `L5_API_AND_CONTRACTS.md` | planned |
| L6 | `L6_OBSERVABILITY.md` | planned |
| L7 | `L7_TESTING.md` | planned |
| L8 | `L8_SECURITY_AND_SECRETS.md` | planned |
| L9 | `L9_CHANGE_AND_RELEASE.md` | planned |
| L10 | `L10_DECISIONS/` | planned |
| Adapters | `adapters/{claude,codex,grok}/` | planned (thin entry templates) |

## Writing plan (temporary)

See [`GUIDE_PLAN.md`](./GUIDE_PLAN.md) for order of work, consult-then-draft workflow, and
per-layer notes. That file will be deleted when the suite is stable.

## How to use

- **How any agent should work (start, ask vs decide, done, handoff)** → `L0_AGENT_PROTOCOL.md`
- **Shaping code you already know where to put** → `L1_CODING_STYLE.md`
- **Language / framework / storage choice** → `L3_LANGUAGE_AND_FRAMEWORK.md`
- **Everything else** → not written yet; do not invent a second style system
- **Tool entry files** → thin `CLAUDE.md` / `AGENTS.md` (adapters planned under `adapters/`)
