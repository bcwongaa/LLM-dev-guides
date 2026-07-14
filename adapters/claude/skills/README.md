# Claude Code pointer-skills — routing, not law

One thin skill per domain layer (L1–L9). Each skill's only job: when the task matches its
description, tell Claude to **Read the actual guide file** before working. No guide
content is duplicated into skills — files stay the single canon for all tools
(Claude, Codex, Grok).

Why: Claude Code invokes skills on task match automatically. That replaces the unreliable
"remember to consult L0's routing table" hop with the mechanism the tool actually uses
for on-demand loading — without forking the law per tool.

## Install (consumer repo)

```bash
mkdir -p .claude/skills
cp -R "$GUIDES_ROOT"/adapters/claude/skills/l* .claude/skills/
```

The skill bodies reference `GUIDES_ROOT/...` — they resolve it from the repo's
`CLAUDE.md`, so no per-repo editing is needed as long as `GUIDES_ROOT` is set there.

## Rules

- Skills stay pointer-thin. If you are tempted to write a rule into a skill, it belongs
  in the L\* guide (or your project CLAUDE.md facts), not here.
- L0 is deliberately **not** a skill: the adapter's bootstrap block already covers the
  every-task core, and skills load on match, not on every task.
