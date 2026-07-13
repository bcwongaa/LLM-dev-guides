# L0 — Agent Protocol

How any coding agent works in a repo that uses these guides. Shared ritual for Grok,
Claude, Codex, and any other tool: start the same way, open the right guide, know when to
ask, ship with the same definition of done. **Router and protocol only** — not coding
style, not stack choice, not domain design.

---

## Scope of this guide

**In scope**

- Bootstrap ritual before editing
- Which L-guide to open for which task
- Ask vs decide (conservative)
- Scope discipline (hard ban on drive-bys)
- Definition of done + post-task check
- Multi-tool entry via thin adapters
- WIP handoff (`docs/agent/STATUS.md`) and PR handoff
- How third-party skills relate to these guides

**Out of scope** (do not put these in L0)

| Concern | Where it lives |
|---|---|
| Code shape, smells, naming | **L1** |
| Greenfield layout / domain split | **L2** |
| Language, framework, storage defaults | **L3** |
| Schema, migrations, data invariants | **L4** |
| HTTP/events/contracts | **L5** |
| Logs/metrics/traces | **L6** |
| What/how to test | **L7** |
| Auth, PII, secrets | **L8** |
| Flags, expand/contract, release | **L9** |
| Long-lived “why we chose X” | **L10** |
| Tool hooks, MCP names, CLI flags | **Tool adapters** (thin entry files) |

If a rule is about *how code should look or which stack to pick*, it does **not** belong
here.

---

## Conflict order

When instructions disagree, apply this order (highest wins):

```
1. Local codebase convention (existing code, project CLAUDE.md / AGENTS.md project facts)
2. These guides (L0–L10), once the relevant layer exists
3. Third-party skills — except pure vendor API usage (see Skills)
4. Model default taste
```

Also always:

```
working behavior           >  style purity
smallest change that ships >  drive-by improvement
```

---

## Multi-tool entry

Each tool loads a **thin adapter** first. The adapter points here; it does **not** restate
L1/L3.

| Tool | Typical entry file in the consumer repo |
|---|---|
| Claude Code | `CLAUDE.md` |
| Codex | `AGENTS.md` |
| Grok Build | `AGENTS.md` and/or a short project instruction that points at L0 |

**Adapter job:** map + exact commands + “read L0, then the relevant L\*”.  
**L0 job:** shared ritual for every tool.  
**L1–L10 job:** domain law.

Templates live under `adapters/` (`claude/`, `codex/`, `grok/`). Consuming repos copy or
symlink them into the root; they must stay thin. See `adapters/README.md`.

---

## Bootstrap ritual

Before editing code:

```
1. Read your tool’s thin adapter (CLAUDE.md / AGENTS.md / …)
2. Read this file (L0) if not already loaded
3. Open only the L-guide(s) the routing table requires for this task
4. If docs/agent/STATUS.md exists — read it
5. Then plan (if non-trivial) or edit
```

```
✓  Adapter → L0 → L1 (bugfix) → STATUS present → edit the one module
✗  Skip guides and “improve” three unrelated packages
✗  Load every L-file “just in case”
✗  Ignore STATUS and redo work another tool already finished
```

---

## Guide routing table

Open the **smallest** set of guides that match the task. Missing file → see
[Missing layers](#missing-layers).

| Task type | Open |
|---|---|
| How to start / ask vs decide / done bar | **L0** (this file) |
| Day-to-day code shape, smells, post-code style | **L1** |
| Greenfield layout, engines/modules, new deployable? | **L2** |
| Language / framework / storage choice or bans | **L3** |
| Schema, migrations, keys, nullability, money/time | **L4** |
| HTTP/events/DTOs, versioning, wire errors | **L5** |
| Logs, metrics, traces, DB health, early APM | **L6** |
| What to test, TDD, pyramid, factories, flakes | **L7** |
| Auth boundaries, PII, secrets | **L8** |
| Flags, expand/contract, rollback, deploy safety | **L9** |
| Why we chose X (standing decision) | **L10** |

Mixed tasks: open every layer you will actually touch (e.g. new endpoint + migration →
L4 + L5, plus L1 for code shape). Do not open the rest.

```
✓  “Fix null check in formatter” → L1 only
✓  “Add Postgres column + API field” → L1 + L4 + L5 (if those files exist)
✗  Open L1–L10 for a one-line bugfix
✗  Invent an L7 testing philosophy because L7 is not written yet
```

---

## Missing layers

If the routing table points at a guide that is **not written yet**:

1. **Do not invent** a house rule for that domain.
2. **Match local code** and existing project instructions.
3. **Ask** if the change hits the [always ask](#always-ask-conservative) list.
4. Otherwise proceed with smallest safe change and note the gap in the task summary.

```
✓  L7 missing; add a test in the same style as neighboring tests
✓  L4 missing; small column add → ask (schema is high-impact)
✗  L7 missing; write a novel testing manifesto in the PR
✗  L3 missing on greenfield; pick Nest + Mongo without asking
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

- Day-to-day code shape following **L1**
- Stack-local defaults following **L3** when continuing an existing project
- Small bugfixes, refactors **strictly required** to ship the task (not drive-bys)
- Test updates needed so the suite is not worse

When unsure whether something is on the ask list: **ask**.

```
✓  “Should we use Mongo for this new domain?” → ask (L3 / greenfield)
✓  Rename local helper used only in this file → decide (L1)
✗  Introduce a new framework because a skill suggested it → ask, almost always no
✗  Expand “fix login bug” into auth redesign → ask (or refuse expansion)
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
- Expand the task without explicit human approval
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
3. **Tests not worse** — suite passes, or failure count is not higher than before.
4. **Lint / typecheck** — run if the project already has them; don’t leave new failures.
5. **Short summary** — what changed, what was deliberately not changed, open questions.

Complete does **not** mean perfect, fully refactored, or every nearby smell fixed.

### Post-task check

Before calling the work done:

1. Scope — no out-of-scope edits  
2. Guides — opened and applied the right L\*  
3. Tests — not worse  
4. Lint/types — clean if applicable  
5. Summary — written  
6. Handoff — STATUS updated or cleared; PR description if review-ready  

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

---

## Third-party skills

Catalogs and vendor skills (Stripe, Playwright, Sentry, etc.) are **optional** and
**task-scoped**.

| Wins | Loses |
|---|---|
| **These guides** for stack, style, process, scope | Skill advice that rewrites architecture or taste |
| **Skill** for pure vendor API usage patterns | Skill that conflicts with L1/L3 on code shape or stack |
| **Local code** over both when the repo already does X | Blind skill copy-paste into a foreign style |

```
✓  Stripe skill for idempotent PaymentIntent params; L1 for how the wrapper is shaped
✗  Next.js skill pushes serverless backend as default against L3 — reject / ask
✗  Install dozens of skills “for completeness” and drown the protocol
```

Do not bulk-load skill catalogs into every session. Install and open a skill only when the
task needs that vendor/domain.

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| Skipping L0 and improvising process per tool | Multi-tool drift; no shared done bar |
| Restating L1/L3 inside adapters or STATUS | Forked law; guides go stale |
| Opening every guide every time | Noise; model follows the wrong rule |
| Inventing missing layers | Fake house style the author never approved |
| Drive-by refactors | Review noise; breaks “smallest change” |
| Autonomous greenfield stack pick | Highest-cost wrong decision |
| Treating STATUS as optional memory while switching tools | Lost work / duplicate work |
| Letting a skill override stack bans | Silent violation of L3 |

---

## When to break the rules

- **Human explicitly overrides** a protocol step for this task (“skip STATUS”, “expand scope to X”).
- **Emergency production fix** — still no drive-by refactors; note protocol skips in the summary.
- **Adapter or guide missing in a legacy repo** — follow local project instructions; do not block forever. Prefer adding a thin adapter later.

Breaking “always ask” on greenfield stack or security without a human is **not** a valid
exception.

---

## Done checklist (for work under this protocol)

- [ ] Thin adapter read (or project equivalent)
- [ ] L0 applied; only relevant L\* opened
- [ ] STATUS read if present; updated if WIP spans tools/sessions
- [ ] Plan written if non-trivial
- [ ] Ask-list items asked (not silently decided)
- [ ] No out-of-scope edits
- [ ] Tests not worse; lint/types clean if available
- [ ] Short summary delivered
- [ ] PR description filled when review-ready

---

## Relationship to other layers

```
Adapter (tool) → L0 (protocol) → L1…L10 (domain law) → code
                      ↑
              STATUS / PR (handoff)
```

L0 does not replace L1–L10. It only ensures every agent enters them the same way and
stops at the same done bar.
