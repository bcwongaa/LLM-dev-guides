# Claude Code adapter — operator notes

Not loaded as project law. For humans wiring the tool.

## Permissionless

Author default: skip interactive permissions.

```bash
# common patterns (use whatever your Claude Code version supports)
claude --dangerously-skip-permissions
# or settings: permissionMode / bypassPermissions equivalent
```

Does **not** skip L0 ask-list (stack, schema, security, scope).

## Install

```bash
# from consumer repo root
cp /path/to/LLM-dev-guides/adapters/claude/CLAUDE.md ./CLAUDE.md
# edit GUIDES_ROOT + Exact commands
```

## Optional `.claude/rules/`

Use only for **path-scoped project facts** (e.g. “prices are USD points”), never for coding style or stack defaults (those are L1/L3).
