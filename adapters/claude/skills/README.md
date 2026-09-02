# Claude Code pointer-skills — routing, not law

One thin skill per domain. Each skill's only job: when the task matches its
description, hand Claude a **line-range index of that guide's sections** so it reads
the two or three sections it needs instead of the whole file. No guide content is
duplicated into skills — files stay the single canon for all tools (Claude, Codex, Grok).

Why: Claude Code invokes skills on task match automatically. That replaces the unreliable
"remember to consult the protocol routing table" hop with the mechanism the tool actually uses
for on-demand loading — without forking the law per tool.

## Granularity

The index is the retrieval mechanism. Sharding it per domain — rather than one global
index — means a session only ever loads the shard it matched, so adding guides never
raises the cost of any single lookup.

```
116-128  13. Errors where detected     →  Read(RULES.md, offset=116, limit=13)
```

Line ranges are **generated** from each guide's `## ` headings by
`scripts/gen-adapters.py --write`. Never hand-edit a `SKILL.md`: edit the guide or
`adapters/manifest.json` and regenerate. `check-sync.sh` fails on drift, so a stale
range cannot survive a guide edit.

## Install (consumer repo)

```bash
mkdir -p .claude/skills
find "$GUIDES_ROOT"/adapters/claude/skills -mindepth 1 -maxdepth 1 -type d \
  -exec cp -R {} .claude/skills/ \;
```

The skill bodies reference `GUIDES_ROOT/...` — they resolve it from the repo's
`AGENTS.md` (Claude loads that file via `@AGENTS.md`), so no per-repo editing is
needed as long as `GUIDES_ROOT` is set there.

## Budgets

`check-size.sh` gates two separate costs:

| Budget | Limit | Why |
|---|---|---|
| Each `SKILL.md` | 1800 B | loads on match |
| All `name:` + `description:` lines | 1400 B | in context every session, match or not |

The second is the one that scales badly — every new skill taxes every session, so a
new skill has to earn its description.

## Rules

- Skills stay pointer-thin. If you are tempted to write a rule into a skill, it belongs
  in the domain guide (or your project CLAUDE.md facts), not here.
- Skill ids are domain names matching `guides/<domain>/`. The old L0–L10 numbering is gone.
- Protocol is deliberately **not** a skill: the adapter's bootstrap block already covers the
  every-task core, and skills load on match, not on every task.
