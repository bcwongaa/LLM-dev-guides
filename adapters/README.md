# Tool adapters

Thin entry files so **Claude Code**, **Codex**, and **Grok Build** load the same law
(protocol → relevant guides). `AGENTS.md` is the **map**. `CLAUDE.md` is Claude-only
mechanics plus `@AGENTS.md`. Neither restates code-style / stack law.

For full brownfield adoption (paths, merge with existing files, checklists), see
**[`../docs/USING_IN_EXISTING_REPOS.md`](../docs/USING_IN_EXISTING_REPOS.md)**.

## Install into a consumer repo

Copy templates by hand. `python3 scripts/gen-adapters.py` only updates **this**
repository. It is not a consumer installer.

1. Always copy the shared map into the **repo root** as `AGENTS.md`. The three
   copies below are byte-identical — pick any one.

| Tool | Template | Install as |
|---|---|---|
| All tools | `claude/AGENTS.md` (or `codex/` / `grok/`) | `AGENTS.md` |
| Claude Code | `claude/CLAUDE.md` | `CLAUDE.md` (`@AGENTS.md` + Claude mechanics) |

2. Set **`GUIDES_ROOT`** inside the copied `AGENTS.md` — path to this suite (or a vendored copy):

```text
# examples
GUIDES_ROOT=../LLM-dev-guides
GUIDES_ROOT=docs/llm-dev-guides
GUIDES_ROOT=.          # when working inside this suite repo
```

3. Fill the **Exact commands** table in `AGENTS.md` with that project’s real `test` / `lint` / `build` commands.

4. Optional: create `docs/agent/STATUS.md` when work spans tools or sessions (see protocol).

## Rules (do not break)

- **No code-style / stack law restated** in `AGENTS.md` or `CLAUDE.md` — open the guide files.
- **No shared law in `CLAUDE.md`** — import `AGENTS.md`; keep only Claude mechanics.
- **Tool-only mechanics** (hooks, MCP, permission flags) stay in the adapter or NOTES.
- When guides change, update adapters only if entrypoints or ritual change.

## Permissionless mode

Author runs **permissionless / always-approve** on all three tools. Adapters assume the agent
may run commands and edit files without interactive permission prompts. That does **not**
relax protocol: root sessions still ask on greenfield stack, schema breaks, security, and scope
expansion. **Subagents** escalate those items to the **parent** (see protocol) — they do not ask
the human directly.

See each adapter’s `NOTES.md` for tool-specific flags.

## Shared vs per-tool files

| File | Shared? |
|---|---|
| `AGENTS.md` | Yes — Codex + Grok + Claude (via `@AGENTS.md`) read the same map |
| `CLAUDE.md` | Claude-native import wrapper; not a second map |
| `claude/skills/` | Claude-native pointer-skills (route tasks to domain guides; no law inside) |
| `claude/hooks/` | Claude-native enforcement hooks (STATUS inject, branch guard, test gate) |
| `.claude/rules/` | Optional Claude path-scoped stubs — project-specific, not required by this suite |

Skills/hooks are **Claude-only leverage on shared law**: the guide files remain the single
canon; Codex and Grok read the same files via `AGENTS.md`. Parity applies to the law's
content, not to tool mechanics.

Grok also loads `CLAUDE.md` if present. Treat that file as Claude mechanics. Grok’s law
is `AGENTS.md`.

## Generating adapters (this repo only)

```bash
python3 scripts/gen-adapters.py --write   # regenerate files in this repository
python3 scripts/gen-adapters.py --check   # fail if generated files drifted
```

Source of truth: `adapters/manifest.json`. Hooks under `claude/hooks/` are hand-authored
and are not generated.
