# Pointer-skills — routing, not law

One thin skill per domain, in the [Agent Skills](https://agentskills.io/specification) format
that Claude Code, Codex, and Grok Build all load. Each skill's only job: when the task matches
its description, hand the agent a **line-range index of that guide's sections**, so it reads the
two or three sections it needs instead of the whole file. No guide content is duplicated into
skills; the guide files stay the single canon.

Why: these tools load skills on task match by themselves. That replaces the unreliable
"remember to consult the protocol routing table" hop with the mechanism the tools actually use
for on-demand loading, without forking the law per tool. Without skills, an agent still has the
`AGENTS.md` routing table and `guides/<domain>/INDEX.tsv`.

## Granularity

The index is the retrieval mechanism. Sharding it per domain, rather than one global index,
means a session only loads the shard it matched, so adding guides never raises the cost of any
single lookup.

```
116-128  13. Errors where detected     →  lines 116 to 128 of RULES.md
```

Each skill shows both read forms: Claude's `Read(path, offset, limit)` and the shell's
`sed -n 'START,ENDp' path`. Line ranges are **generated** from each guide's `## ` headings by
`scripts/gen-adapters.py --write`. Never hand-edit a `SKILL.md`: edit the guide or
`adapters/manifest.json` and regenerate. `check-sync.sh` fails on drift, so a stale range cannot
survive a guide edit.

## Install (consumer repo)

| Tool | Loads project skills from |
|---|---|
| Claude Code | `.claude/skills/` |
| Grok Build | `.claude/skills/` (it reads Claude skill folders) or `.grok/skills/` |
| Codex | `.agents/skills/` |

```bash
# Claude Code and Grok Build
mkdir -p .claude/skills
find "$GUIDES_ROOT"/adapters/skills -mindepth 1 -maxdepth 1 -type d -exec cp -R {} .claude/skills/ \;
# Codex
mkdir -p .agents/skills
find "$GUIDES_ROOT"/adapters/skills -mindepth 1 -maxdepth 1 -type d -exec cp -R {} .agents/skills/ \;
```

The skill bodies reference `GUIDES_ROOT/...`; agents resolve it from the repo's `AGENTS.md`, so
no per-repo editing is needed as long as `GUIDES_ROOT` is set there.

## Size

`scripts/check-size.py` holds each description to the 1,024-character limit of the Agent Skills
spec, and `gen-adapters.py` holds each id to its name rule. Descriptions sit in context every
session whether or not a skill fires, so every new skill taxes every session and has to earn
its description.

## Rules

- Skills stay pointer-thin. If you are tempted to write a rule into a skill, it belongs in the
  domain guide (or your project's facts), not here.
- Skill ids are domain names matching `guides/<domain>/`.
- Protocol is deliberately **not** a skill: the adapter's bootstrap block already covers the
  every-task core, and skills load on match, not on every task.
