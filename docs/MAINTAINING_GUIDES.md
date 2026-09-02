# Maintaining the guides

For people **changing this suite**. Adopting it in an app instead? See
[`USING_IN_EXISTING_REPOS.md`](USING_IN_EXISTING_REPOS.md).

## The one rule that causes most CI failures

**Editing a guide changes line numbers, and line numbers are published.** Each
`guides/<domain>/INDEX.tsv` and each `SKILL.md` carries `start-end` ranges pointing into
`RULES.md` / `REFERENCE.md`. Insert one line near the top of a guide and every range below
it is wrong.

They are **generated**, not written. So:

```bash
python3 scripts/gen-adapters.py --write   # after ANY guide or manifest edit
bash scripts/check-sync.sh                # the Test command; runs every gate
```

If you forget, CI tells you exactly this — both `gen-adapters --check` and `check-index.py`
print the fix in their failure output.

## Never hand-edit these

| Generated (29 files) | Edit instead |
|---|---|
| `guides/*/INDEX.tsv` | the guide's `## ` headings |
| `adapters/claude/skills/*/SKILL.md` | `adapters/manifest.json` |
| `AGENTS.md`, `CLAUDE.md`, `adapters/*/AGENTS.md` | `adapters/manifest.json` |

A hand-edit survives locally and dies in CI. `--write` overwrites it.

## Common tasks

**Change law wording** → edit `guides/<domain>/RULES.md` → `--write` → `check-sync.sh`.

**Add or rename a section** → the heading text is the index label and the retrieval signal;
make it self-describing out of context (`Layer boundaries` is a bad label, `Data
observability: layer boundaries` is a good one). Then `--write`.

**Add a skill** → add to `skills` in `adapters/manifest.json`, then `--write`. Descriptions
sit in context **every session whether the skill fires or not**, so the whole set is capped;
a new skill must earn its description.

**Show a `## ` line as an example** → put it in a fenced block. The parsers are fence-aware
and will not mistake it for a section. Seven such headings already exist in `REFERENCE.md`.

## Budgets (`scripts/check-size.sh`)

| What | Limit | Why |
|---|---|---|
| Root maps (`AGENTS.md` + `CLAUDE.md`) | 12288 B | loaded every session |
| `RULES.md` file | 8192 B | sprawl backstop only |
| `RULES.md` **section** | 1900 B | **the real cost — what a task reads** |
| `REFERENCE.md` section | 6552 B | ratchet |
| `SKILL.md` | 1800 B | loads on match |
| All skill descriptions | 1400 B | in context every session |
| `INDEX.tsv` | 4096 B | read to select sections |

The **section** budgets are the ones that matter. With line-range retrieval nobody reads a
whole file, so a per-file cap only stops sprawl — and a cap you can live at becomes a target
(every `RULES.md` once sat at 8191 B).

The `REFERENCE.md` and conservation limits are **ratchets**: set just above today's maximum
so nothing grows. Lower them when you improve something; never raise one to make a new
violation pass. If a section is over budget, split it — see below.

## Splitting a section

Size alone is not the test. Ask **what a partial read costs**:

- **Interlocking rules** (an escalation chain, a safety boundary) → keep whole. Someone
  reading the mechanics without the constraint is the failure the section prevents.
- **A catalog or standalone artifact** (a template, a checklist, a taxonomy) → split. Each
  part already restates its own guard.

Keep any gating constraint attached to what it gates. Worked examples:
`orchestration/REFERENCE.md` (escalation chain kept whole, templates lifted out) and
`observability/REFERENCE.md` §7 (taxonomy split, conditional gate kept with the definition).

## Conservation needles

`scripts/*-conservation.tsv` assert that specific law text still lives in a specific file, so
a migration cannot silently drop it. Rewording pinned text fails CI — update the needle in
the same commit.

A needle must be **specific enough to localize law**. `'Done'` appears in 23 files and proves
nothing. `scripts/conservation-baseline.txt` ratchets the count of too-generic needles
(currently 38); it may fall, never rise.

## Before you push

```bash
bash scripts/check-sync.sh
```

One command, every gate: drift, size, index truth, routing, hooks. It is what CI runs
(`.github/workflows/checks.yml`). Green locally means green there.

## Ask the author first

Per [`../AGENTS.md`](../AGENTS.md): settled protocol / code-style / stack law, new layers, and
rewriting author-native guide voice. Structural changes (splitting a section, renaming a
heading) are lower-stakes than rewording law — but they change retrieval labels, so say what
you changed and why.
