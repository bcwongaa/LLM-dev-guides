# Tool adapters

Thin entry files so **Claude Code**, **Codex**, and **Grok Build** load the same law
(`L0` → relevant `L*`). Adapters are **maps**, not a second style guide.

For full brownfield adoption (paths, merge with existing CLAUDE.md, checklists), see
**[`../USING_IN_EXISTING_REPOS.md`](../USING_IN_EXISTING_REPOS.md)**.

## Install into a consumer repo

1. Copy (or symlink) the template for each tool you use into the **repo root**:

| Tool | Template | Install as |
|---|---|---|
| Claude Code | `claude/CLAUDE.md` | `CLAUDE.md` |
| Codex | `codex/AGENTS.md` | `AGENTS.md` |
| Grok Build | `grok/AGENTS.md` | `AGENTS.md` (shared with Codex) + optional notes |

2. Set **`GUIDES_ROOT`** inside the copied file — path to this suite (or a vendored copy):

```text
# examples
GUIDES_ROOT=../LLM-dev-guides
GUIDES_ROOT=docs/llm-dev-guides
GUIDES_ROOT=.          # when working inside this suite repo
```

3. Fill the **Exact commands** table with that project’s real `test` / `lint` / `build` commands.

4. Optional: create `docs/agent/STATUS.md` when work spans tools or sessions (see L0).

## Rules (do not break)

- **No L1/L3 restated** here — open the guide files.
- **Tool-only mechanics** (hooks, MCP, permission flags) stay in the adapter or NOTES.
- When guides change, update adapters only if entrypoints or ritual change.

## Permissionless mode

Author runs **permissionless / always-approve** on all three tools. Adapters assume the agent
may run commands and edit files without interactive permission prompts. That does **not**
relax L0: still ask on greenfield stack, schema breaks, security, and scope expansion.

See each adapter’s `NOTES.md` for tool-specific flags.

## Shared vs per-tool files

| File | Shared? |
|---|---|
| `AGENTS.md` | Yes — Codex + Grok both read it; keep one file |
| `CLAUDE.md` | Claude-native; keep content aligned with `AGENTS.md` |
| `.claude/rules/` | Optional Claude path-scoped stubs — project-specific, not required by this suite |

When both `AGENTS.md` and `CLAUDE.md` exist, keep them **equivalent maps** (same GUIDES_ROOT,
same commands, same “read L0 first”). Drift = two laws.
