# Protocol — reference

Binding surface: [`RULES.md`](RULES.md). This file keeps the original protocol prose and examples.

v2 changes already binding in RULES (do not treat the older one-liner below as the live order):

- Instruction authority and implementation convention are **two systems**.
- Business logic and architecture always reach the human.
- Roots may decide routine reversible schema/API/scope only when the RULES criteria all hold.


How any coding agent works in a repo that uses these guides. Shared ritual for Grok,
Claude, Codex, and any other tool: start the same way, open the right guide, know when to
ask, ship with the same definition of done. **Protocol only** — not coding style, not
stack choice, not domain design.

Git flow, parallel agents, subagent briefs, and orchestration mechanics live in
**`../orchestration/REFERENCE.md`** — load that file only when branching/PRing, spawning subagents,
or running parallel workstreams. A solo one-file fix does not need it.

---

## Scope of this guide

**In scope**

- Bootstrap ritual before editing (including the test baseline)
- Which domain guide to open for which task
- Ask vs decide (conservative), including subagent escalation basics
- Local convention discovery and the brownfield tie-breaker
- Scope discipline (hard ban on drive-bys)
- Definition of done + post-task check
- Multi-tool entry via thin adapters
- WIP handoff (`docs/agent/STATUS.md`) and PR handoff
- How third-party skills relate to these guides

**Out of scope** (do not put these in protocol)

| Concern | Where it lives |
|---|---|
| Team git flow, parallel agents, subagent briefs, orchestrator role | **../orchestration/REFERENCE.md** |
| Code shape, smells, naming | **code-style** |
| Greenfield layout / domain split | **architecture** |
| Language, framework, storage defaults | **stack** |
| Schema, migrations, data invariants | **data** |
| HTTP/events/contracts | **contracts** |
| Logs/metrics/traces, DB health, runtime data health/lineage | **observability** |
| What/how to test | **testing** |
| Auth, PII, secrets | **security** |
| Flags, expand/contract, prod deploy choreography | **release** |
| Long-lived “why we chose X” | **decisions** |
| Tool hooks, MCP names, CLI flags | **Tool adapters** (thin entry files) |
| Exact CI vendor YAML | Project-local |

If a rule is about *how code should look or which stack to pick*, it does **not** belong
here.

---

## Conflict order

When instructions disagree, apply this order (highest wins):

```
1. Local codebase convention (existing code, project CLAUDE.md / AGENTS.md project facts)
2. These guides (relevant domain RULES), when the relevant layer file exists
3. User-global tool files (~/.claude/CLAUDE.md, ~/.codex, ~/.grok prefs)
4. Third-party skills — except pure vendor API usage (see Skills)
5. Model default taste
```

One-line form (adapters use this exact line):

```
local code > guides > user-global tool files > third-party skills (except pure vendor API how-to) > model taste
```

User-global files (personal `~/.claude/CLAUDE.md` and equivalents) are **personal
defaults**: they win over skills and taste, but in a repo that adopts this suite the
suite’s law and the local codebase win over them. Personal tooling habits stay; personal
style/process rules yield.

Also always:

```
working behavior           >  style purity
smallest change that ships >  drive-by improvement
```

---

## Multi-tool entry

Each tool loads a **thin adapter** first. The adapter points here; it does **not** restate
code-style/stack.

| Tool | Typical entry file in the consumer repo |
|---|---|
| Claude Code | `CLAUDE.md` |
| Codex | `AGENTS.md` |
| Grok Build | `AGENTS.md` and/or a short project instruction that points at protocol |

**Adapter job:** map + exact commands + “read protocol, then the relevant domain guides”.
**Protocol job:** shared ritual for every tool.
**Domain guides job:** domain law.

Templates live under `adapters/` (`claude/`, `codex/`, `grok/`). Consuming repos copy or
symlink them into the root; they must stay thin. See `adapters/README.md`. The Claude
adapter also ships optional pointer-skills and hooks (`adapters/claude/skills/`,
`adapters/claude/hooks/`) that enforce parts of this ritual — they supplement protocol, never
replace it.

---

## Bootstrap ritual

Before editing code:

```
1. Read your tool’s thin adapter (CLAUDE.md / AGENTS.md / …)
2. Read this file (protocol) if not already loaded
3. Open only the domain guide(s) the routing table requires for this task
4. If docs/agent/STATUS.md exists — read it (and any workstream STATUS you own)
5. Baseline: run the project’s Test (and Lint) commands from the adapter’s Exact
   commands and record the result (pass/fail + failure count). “Tests not worse”
   at the end is measured against THIS. Skip only if the project has no test command.
6. Confirm git base: on a **feature branch** off the integration base — not long-lived
   direct commits to `main`/`develop` for feature work (mechanics: ../orchestration/REFERENCE.md)
7. Then plan (if non-trivial) or edit
```

```
✓  Adapter → protocol → code-style+testing (bugfix) → STATUS present → baseline recorded → feature branch → edit one module
✗  Skip guides and “improve” three unrelated packages
✗  Load every domain guide “just in case”
✗  Ignore STATUS and redo work another tool already finished
✗  Declare “tests not worse” with no pre-edit baseline
✗  Pile feature work on main/develop without a branch + PR
```

---

## Guide routing table

Open the **smallest** set of guides that match the task. Missing file → see
[Missing layers](#missing-layers).

| Task type | Open |
|---|---|
| How to start / ask vs decide / done bar | **protocol** (this file) |
| Branching/PRs, conflicts, parallel agents, subagent briefs | **../orchestration/REFERENCE.md** |
| Day-to-day code shape / smells | `guides/code-style/` |
| **Bugfix** | **code-style + testing** (every bugfix gets a repro/regression test) |
| Greenfield layout, engines/modules, new deployable? | **architecture** |
| Language / framework / storage choice or bans | **stack** |
| Schema, migrations, keys, nullability, money/time | **data** |
| HTTP/events/DTOs, versioning, wire errors | **contracts** |
| Logs, metrics, traces, DB health, runtime data health/lineage, early APM | **observability** |
| What to test, TDD, pyramid, factories, flakes | **testing** |
| Auth boundaries, PII, secrets, IDOR, supply chain | **security** |
| Flags, expand/contract, rollback, deploy safety | **release** |
| Why we chose X (standing decision) | **decisions** |

Mixed tasks: open every layer you will actually touch (e.g. new endpoint + migration →
data + contracts, plus code-style for code shape). Do not open the rest.

```
✓  “Fix null check in formatter” → code-style + testing (repro test)
✓  “Add Postgres column + API field” → code-style + data + contracts
✗  Open the domain guides for a one-line bugfix
✗  Invent a private testing philosophy that fights testing
```

---

## Missing layers

If a routing target file is **missing from the consumer repo** (guides not vendored) or an
optional layer (e.g. decisions) has no decisions yet:

1. **Do not invent** a parallel house rule for that domain.
2. **Match local code** and existing project instructions.
3. **Ask** if the change hits the [always ask](#always-ask) list.
4. Otherwise proceed with smallest safe change; for standing “why we chose X” with no ADR,
   ask rather than invent history.

```
✓  Guides vendored: open testing for test policy
✓  decisions empty: ask before treating a stack choice as sacred forever
✗  Guides missing locally: invent a second style guide in the PR
✗  Ignore security because “security isn’t my task” on an auth change
```

---

## Ask vs decide (conservative)

### Always ask

Do **not** decide alone:

| Area | Examples |
|---|---|
| Greenfield stack | New language, framework, major library platform |
| New service / major boundary | New deployable, new package that splits the system |
| Schema / data breaks | Migrations with expand risk, renames, destructive changes |
| API / contract breaks | Public API shape, versioning, breaking DTO changes |
| Security / secrets / PII | Auth model, permission changes, secret handling |
| Ambiguous product intent | Unclear acceptance criteria, conflicting user signals |
| Scope expansion | Anything outside the original task |

### May decide without asking

Within existing stack and local convention:

- Day-to-day code shape following **code-style**
- Stack-local defaults following **stack** when continuing an existing project
- Small bugfixes, refactors **strictly required** to ship the task (not drive-bys)
- Test updates needed so the suite is not worse

When unsure whether something is on the ask list: **ask** (if you can talk to the human).

```
✓  “Should we use Mongo for this new domain?” → ask (stack / greenfield)
✓  Rename local helper used only in this file → decide (code-style)
✗  Introduce a new framework because a skill suggested it → ask, almost always no
✗  Expand “fix login bug” into auth redesign → ask (or refuse expansion)
```

### Subagents: escalate, never improvise

**Subagents cannot ask the human.** Core rules (full detail + templates:
`../orchestration/REFERENCE.md`):

1. A subagent that hits an always-ask item **stops** and reports to its **direct parent**
   with options + a recommendation. It does not silently pick a stack, break a schema, or
   expand scope.
2. The **parent is the authority** for its children: it decides from guides + local code +
   task intent, or escalates. The parent owns decisions it approves — no blaming the child.
3. **Hard items always reach the human via the root**: destructive/irreversible data loss,
   new auth model / security boundary, new deployable / multi-repo split, true product
   ambiguity. Parents must not rubber-stamp these.
4. Nested children escalate to their **direct spawner** only; only the root talks to the
   human.
5. Peer sessions (each talking to the human) still ask the human directly.

---

## Local convention (how to find it, and the brownfield tie-breaker)

“Local code wins” needs a procedure in repos with mixed history:

**Discovery:** before writing in an unfamiliar area, read **2–3 sibling files** nearest
the edit (same folder, then same package). Prefer the **most recently merged** code in
that area as the live convention when styles compete.

**Tie-breakers** (highest wins): nearest file > package > repo; newer > older.

**When the local convention is itself an code-style anti-pattern:**

- **Net-new files/modules** follow **code-style**.
- **Edits inside an existing file** match that file’s dominant pattern — *unless* the
  pattern is on code-style’s never-list (swallowed errors, dishonest types, missing await) **and**
  the fix stays within the lines you are already changing. Then fix those lines to code-style and
  say so in the summary. Do not sweep the rest of the file (scope ban).

```
✓  Repo half callbacks / half async: new code follows the newer async convention in that package
✓  Editing an error-swallowing wrapper’s catch block anyway → stop swallowing in those lines, note it
✗  “File uses catch-and-ignore, so my new code also ignores errors” — never-list is not a convention
✗  Convert the whole file to async “while here” — drive-by
```

---

## Plan before code

Write a **≤5 bullet plan** (chat and/or STATUS) **before editing** when the task is
non-trivial:

- Multi-file change
- Design or API choice
- Unclear scope
- Touches ask-list domains (even if you will ask mid-flight)

**Skip** the plan for trivial one-file fixes with obvious scope.

```
✓  Plan: 1) add failing test 2) fix parser 3) run unit suite
✗  Multi-module rewrite with no stated plan or STATUS
```

---

## Scope discipline (hard ban)

**NEVER:**

- Change code outside the task
- “While I’m here” refactors or cleanups
- Expand the task without explicit approval from the **human**, or from the **parent**
  when you are a subagent (parent documents the expansion; hard items still go to human)
- Touch unrelated files to satisfy personal taste

If fixing the task truly requires a one-line change in a dependency of the edit path, that
line is in scope — say so in the summary. Adjacent *unrelated* improvement is not.

```
✓  Task is “fix date format on invoice”; edit invoice formatter + its test
✗  Same task; also reformat the entire billing package
✗  Same task; migrate billing to a new library unprompted
```

---

## Definition of done

A task is complete when:

1. **Scope respected** — only what the task required; hard ban above held.
2. **Relevant guides followed** — for layers that exist and apply.
3. **Tests not worse** — suite passes, or failure count is not higher than the **baseline
   recorded at bootstrap**. Bugfixes and behavior changes also carry the testing coverage bar
   (repro/regression test), not just “not worse.”
4. **Lint / typecheck** — run if the project already has them; don’t leave new failures.
5. **Git hygiene** — feature work on a branch from the integration base; PR small and
   purposeful when review-ready (mechanics: `../orchestration/REFERENCE.md`); no silent commits to
   protected base as the normal path.
6. **Short summary** — what changed, what was deliberately not changed, open questions —
   **with evidence**: the before/after tail of the test/lint output, not just a checked box.

Complete does **not** mean perfect, fully refactored, or every nearby smell fixed.

### Post-task check

Before calling the work done:

1. Scope — no out-of-scope edits
2. Guides — opened and applied the right domain guides
3. Tests — not worse vs the recorded baseline; new/changed behavior covered (testing)
4. Lint/types — clean if applicable
5. Summary — written, with test/lint evidence
6. Handoff — STATUS updated or cleared; PR description if review-ready
7. Git — on correct base lineage; PR not a mega-diff; branches deleted (not reused) after merge

If a check fails, fix or shrink the change. Do not expand scope to polish distant code.

---

## Handoff (multi-tool / multi-session)

### WIP: `docs/agent/STATUS.md`

Use when work spans **sessions or tools** (Grok ↔ Claude ↔ Codex), or when you leave
unfinished work.

**Path:** `docs/agent/STATUS.md` (create `docs/agent/` if needed).

**Mandatory sections:**

```markdown
# STATUS

## Goal
## Done
## Next
## Do not touch
## Open questions
```

Optional (not required by protocol): verify commands, tool last used.

```
✓  Update STATUS when switching tools mid-feature
✓  Clear or mark done when the task ships / PR is the source of truth
✗  Leave a stale STATUS that contradicts the branch
✗  Put long design essays in STATUS — use a plan/ADR instead
```

### Review-ready: PR description

When opening or updating a PR, the PR body is the handoff for reviewers and the next
agent:

- What / why
- How to verify
- Out of scope / do not touch
- Open questions

STATUS is for **WIP continuity**; the PR is for **review continuity**.

When **multiple agents or humans** share a repo, prefer **one STATUS per workstream** or
clear sections so Do-not-touch and Goal do not overwrite each other
(see `../orchestration/REFERENCE.md`).

---

## Third-party skills

Catalogs and vendor skills (Stripe, Playwright, Sentry, etc.) are **optional** and
**task-scoped**.

| Wins | Loses |
|---|---|
| **These guides** for stack, style, process, scope | Skill advice that rewrites architecture or taste |
| **Skill** for pure vendor API usage patterns | Skill that conflicts with code-style/stack on code shape or stack |
| **Local code** over both when the repo already does X | Blind skill copy-paste into a foreign style |

```
✓  Stripe skill for idempotent PaymentIntent params; code-style for how the wrapper is shaped
✗  Next.js skill pushes serverless backend as default against stack — reject / ask
✗  Install dozens of skills “for completeness” and drown the protocol
```

Do not bulk-load skill catalogs into every session. Install and open a skill only when the
task needs that vendor/domain.

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| Skipping protocol and improvising process per tool | Multi-tool drift; no shared done bar |
| Restating code-style/stack inside adapters or STATUS | Forked law; guides go stale |
| Opening every guide every time | Noise; model follows the wrong rule |
| Inventing missing layers | Fake house style the author never approved |
| Drive-by refactors | Review noise; breaks “smallest change” |
| Autonomous greenfield stack pick | Highest-cost wrong decision |
| Treating STATUS as optional memory while switching tools | Lost work / duplicate work |
| Letting a skill override stack bans | Silent violation of stack |
| “Tests not worse” with no recorded baseline | Unfalsifiable done bar |
| Bugfix shipped with no repro/regression test | Same bug returns; testing exists for this |
| Treating a never-list smell as “local convention” | Guides exist to stop exactly that |

Orchestration anti-patterns (mega-PRs, dirty shared worktrees, rubber-stamping parents,
blind conflict resolution): see `../orchestration/REFERENCE.md`.

---

## When to break the rules

- **Human explicitly overrides** a protocol step for this task (“skip STATUS”, “expand scope to X”, “commit on main for this hotfix”).
- **Emergency production fix** — still no drive-by refactors; smallest branch/PR or documented direct fix; note protocol skips in the summary.
- **Adapter or guide missing in a legacy repo** — follow local project instructions; do not block forever. Prefer adding a thin adapter later.
- **Project documents a different branch model** (e.g. trunk-only) — follow **local** git convention; keep small PRs and conflict understanding anyway.
- **No test command exists** — the baseline step is skipped, not faked; say so in the summary (and see testing on minimum harnesses before larger work).

Breaking “always ask” on greenfield stack or security without a human is **not** a valid
exception.

---

## Done checklist (for work under this protocol)

- [ ] Thin adapter read (or project equivalent)
- [ ] Protocol applied; only relevant domain guides opened (orchestration only when branching/spawning)
- [ ] STATUS read if present; updated if WIP spans tools/sessions/workstreams
- [ ] Baseline test/lint run recorded before editing (or “no test command” noted)
- [ ] Plan written if non-trivial
- [ ] Ask-list items: human asked (root) or parent decided for children (documented); hard items not rubber-stamped
- [ ] No out-of-scope edits (human or parent-approved expansion only)
- [ ] Feature branch from integration base (`develop` if present, else `main`)
- [ ] Parallel/subagent work follows `../orchestration/REFERENCE.md` (isolation, briefs, hotspots)
- [ ] Tests not worse vs baseline; bugfix/behavior change covered per testing; lint/types clean if available
- [ ] Short summary delivered with test/lint evidence
- [ ] Small, purposeful PR when review-ready; description filled
- [ ] After merge: feature branches (and umbrella slices) deleted — not reused; next work from fresh base

---

## Relationship to other layers

```
Adapter (tool) → protocol (core ritual) → orchestration (git/agents, when needed) → the domain guides (domain law) → code
                          ↑
                STATUS / branch / PR (handoff)
```

Protocol does not replace the domain guides. It ensures every agent enters them the same way and stops at
the same done bar. **../orchestration/REFERENCE.md** owns branch/PR/parallel-agent mechanics; **release**
still owns expand/contract and prod deploy safety.
