# Grok Build adapter — operator notes

Not loaded as project law. For humans wiring the tool.

## Permissionless

Author default: always-approve tool execution.

```toml
# ~/.grok/config.toml (example)
[ui]
permission_mode = "always-approve"
```

CLI equivalents if used: `--always-approve` / permission mode flags per your Grok version.

Does **not** skip the protocol ask-list (stack, schema, security, scope).

## Install

```bash
# from consumer repo root — same AGENTS.md as Codex
cp /path/to/LLM-dev-guides/adapters/grok/AGENTS.md ./AGENTS.md
# or copy adapters/claude/AGENTS.md / adapters/codex/AGENTS.md — they are byte-identical
# edit GUIDES_ROOT + Exact commands
```

Grok also loads `CLAUDE.md` if present. That file is now Claude-only mechanics plus
`@AGENTS.md` (an import Grok does not expand). Follow `AGENTS.md`. Do not copy suite
law into `CLAUDE.md` to “keep them in sync.”
`python3 scripts/gen-adapters.py` is suite-maintainer tooling, not this install step.

## Discovery reminder

Grok project rules (priority includes): `AGENTS.md`, `CLAUDE.md`, `.grok/rules/`, and Claude-compat paths when enabled. Do not scatter conflicting maps.
