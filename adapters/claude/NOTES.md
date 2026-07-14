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

## Optional Claude-native pack (skills + hooks)

Files stay the canon; these add on-demand routing and enforcement:

```bash
# pointer-skills: auto-route tasks to the right L* guide (see skills/README.md)
mkdir -p .claude/skills
cp -R /path/to/LLM-dev-guides/adapters/claude/skills/l* .claude/skills/

# hooks: STATUS injection, protected-branch edit guard, stop-time test gate
# (see hooks/README.md for settings.fragment.json merge + env vars)
mkdir -p .claude/hooks
cp /path/to/LLM-dev-guides/adapters/claude/hooks/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
```

Trunk-only repos: keep the branch-guard hook but set `GUIDES_ALLOW_BASE_EDITS=1`.

## Optional `.claude/rules/`

Use only for **path-scoped project facts** (e.g. “prices are USD points”), never for coding style or stack defaults (those are L1/L3).
