# Codex adapter — operator notes

Not loaded as project law. For humans wiring the tool.

## Permissionless

Author default: no interactive approval for tool runs (full auto / approval never — use your Codex version’s equivalent).

Does **not** skip L0 ask-list (stack, schema, security, scope).

## Install

```bash
# from consumer repo root
cp /path/to/LLM-dev-guides/adapters/codex/AGENTS.md ./AGENTS.md
# edit GUIDES_ROOT + Exact commands
```

If the repo also uses Grok Build, **one** root `AGENTS.md` serves both (do not fork).

## Optional personal layer

`~/.codex/AGENTS.md` (if you use it) = personal prefs only. Project stack/style stays in L\* + this repo’s `AGENTS.md`.
