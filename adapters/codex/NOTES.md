# Codex adapter — operator notes

Not loaded as project law. For humans wiring the tool.

## Permissionless

Author default: no interactive approval for tool runs (full auto / approval never — use your Codex version’s equivalent).

Does **not** skip the protocol ask-list (stack, schema, security, scope).

## Install

```bash
# from consumer repo root
cp /path/to/LLM-dev-guides/adapters/codex/AGENTS.md ./AGENTS.md
# edit GUIDES_ROOT + Exact commands
```

If the repo also uses Grok Build, **one** root `AGENTS.md` serves both (do not fork).
The `claude/`, `codex/`, and `grok/` `AGENTS.md` copies are byte-identical.
`python3 scripts/gen-adapters.py` is suite-maintainer tooling, not this install step.

## Skills

Codex loads project skills from `.agents/skills/`. Install the suite's pointer-skills there:

```bash
mkdir -p .agents/skills
find /path/to/LLM-dev-guides/adapters/skills -mindepth 1 -maxdepth 1 -type d -exec cp -R {} .agents/skills/ \;
```

## Sandbox and git

Codex's default `workspace-write` sandbox keeps `.git` read-only, so branching and committing,
which the orchestration guide requires for feature work, may need an approval or a looser
sandbox. Untested in this suite's evaluations; Codex is not the author's daily tool.

## Optional personal layer

`~/.codex/AGENTS.md` (if you use it) = personal prefs only. Project stack/style stays in the suite guides + this repo’s `AGENTS.md`.
