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

Does **not** skip L0 ask-list (stack, schema, security, scope).

## Install

```bash
# from consumer repo root — same AGENTS.md as Codex
cp /path/to/LLM-dev-guides/adapters/grok/AGENTS.md ./AGENTS.md
# or copy adapters/codex/AGENTS.md — content is intentionally aligned
# edit GUIDES_ROOT + Exact commands
```

Grok also loads `CLAUDE.md` if present. If you install the Claude adapter too, keep both files in sync (same GUIDES_ROOT and commands).

## Discovery reminder

Grok project rules (priority includes): `AGENTS.md`, `CLAUDE.md`, `.grok/rules/`, and Claude-compat paths when enabled. Do not scatter conflicting maps.
