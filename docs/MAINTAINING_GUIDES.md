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

| Generated | Edit instead |
|---|---|
| `guides/*/INDEX.tsv` | the guide's `## ` headings |
| `adapters/skills/*/SKILL.md` | `adapters/manifest.json` |
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
and will not mistake it for a section. Several reference files already contain such examples.

## Size policy (`scripts/check-size.py`)

Fixed byte budgets got gamed. Under an 8192 B cap every `RULES.md` ended at 8191 B, squeezed to
fit instead of written to be read. Any number we publish becomes a target, so the check flags
files that are big **for their kind**, and the fix it asks for is a topic split, not fewer bytes.

Every text file outside `temp/` is measured in bytes and in lines, against its kind:

| Kind | Files | Soft cap | Hard cap |
|---|---|---|---|
| rules | `guides/*/RULES*.md` | 8 KB, 500 lines | 16 KB, 1,000 lines |
| reference | `guides/*/REFERENCE*.md` | 20 KB, 500 lines | 40 KB, 1,000 lines |
| docs | every other `.md` | 20 KB, 500 lines | 40 KB, 1,000 lines |
| code | everything else | 20 KB, 500 lines | 40 KB, 1,000 lines |

For each metric:

- **Over the soft cap only:** a tolerated outlier. It is printed as a note and does not fail.
- **Over the soft cap and over mean + 1.5 SD of its kind:** fails. Split it by topic, or ask the author.
- **Over the hard cap:** fails as a repo-wide refactor signal. Stop and ask the author.

Why these numbers:

- The hard caps are the smallest single-read window of the first-class tools. Grok's read tool
  stops at 1,000 lines, and Codex returns at most 10,000 tokens of shell output, about 40 KB.
  Under them, any tool reads a file whole in one call. Past them, a whole-file read silently
  loses part of the file. RULES are tighter on bytes because Codex and Grok read them whole on
  every task.
- 1.5 SD is simple to explain and catches the biggest one or two files of a kind.
- The mean and SD come from `scripts/size-baseline.tsv`, computed from the files at the last
  release tag. They are not live: live stats drop the bar every time a big file is split, so
  fixing one file would fail the next one.

Two limits come from the tools themselves and always fail when exceeded: each `AGENTS.md` stays
within 32 KiB, because Codex reads at most that across the whole `AGENTS.md` chain, and each skill
description stays within 1,024 characters, the Agent Skills spec limit.

**When a size check fails,** split by topic or ask the author. Never compress wording, drop
examples, or join lines to get under a number. Text squeezed to fit is the failure this policy
exists to prevent.

**When cutting a release,** the baseline is recalculated (see *Cutting a release*). A new
baseline can fail a file that passed before. Split that file in the same PR, or ask the author.

## Splitting a file or section

A `REFERENCE.md` can split by topic into `REFERENCE-<topic>.md` beside it, for example
`guides/code-style/REFERENCE-naming.md`. The generator indexes every `RULES*.md` and
`REFERENCE*.md` in the domain. Leave a `— moved` stub heading in the original file, so section
numbers still line up with `RULES.md`.

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
(the number in that file); it may fall, never rise.

## Cutting a release

1. Set `version` in `adapters/manifest.json`, then `python3 scripts/gen-adapters.py --write`.
   Consumer templates carry the version, so an adopting repo can tell what it copied.
2. Rename the CHANGELOG `Unreleased` heading to the version. Move `generation` only if shared
   law changed.
3. Merge, then tag the merge commit.
4. `python3 scripts/check-size.py --rebaseline <tag>` and commit the new baseline.
5. Set `version` back to `unreleased` and regenerate.

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
