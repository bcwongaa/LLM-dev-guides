# L0 — Agent Protocol

How any coding agent works in a repo that uses these guides. Shared ritual for Grok,
Claude, Codex, and any other tool: start the same way, open the right guide, know when to
ask, ship with the same definition of done. Includes **team-style git flow** and
**parallel agents** so multiple workers behave like a careful team. **Protocol only** —
not coding style, not stack choice, not domain design.

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
- Team-style git flow (feature branches, small PRs, base branch, conflicts)
- Parallel agents / subagents (isolation, ownership, handoff)
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
| Flags, expand/contract, prod deploy choreography | **L9** |
| Long-lived “why we chose X” | **L10** |
| Tool hooks, MCP names, CLI flags | **Tool adapters** (thin entry files) |
| Exact CI vendor YAML | Project-local |

If a rule is about *how code should look or which stack to pick*, it does **not** belong
here.

---

## Conflict order

When instructions disagree, apply this order (highest wins):

```
1. Local codebase convention (existing code, project CLAUDE.md / AGENTS.md project facts)
2. These guides (L0–L10), when the relevant layer file exists
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
4. If docs/agent/STATUS.md exists — read it (and any workstream STATUS you own)
5. Confirm git base: on a **feature branch** off the integration base — not long-lived
   direct commits to `main`/`develop` for feature work
6. Then plan (if non-trivial) or edit
```

```
✓  Adapter → L0 → L1 (bugfix) → STATUS present → feature branch → edit one module
✗  Skip guides and “improve” three unrelated packages
✗  Load every L-file “just in case”
✗  Ignore STATUS and redo work another tool already finished
✗  Pile feature work on main/develop without a branch + PR
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
| Auth boundaries, PII, secrets, IDOR, supply chain | **L8** |
| Flags, expand/contract, rollback, deploy safety | **L9** (`L9_CHANGE_AND_RELEASE.md`) |
| Why we chose X (standing decision) | **L10** / `L10_DECISIONS/` |

Mixed tasks: open every layer you will actually touch (e.g. new endpoint + migration →
L4 + L5, plus L1 for code shape). Do not open the rest.

```
✓  “Fix null check in formatter” → L1 only
✓  “Add Postgres column + API field” → L1 + L4 + L5
✗  Open L1–L10 for a one-line bugfix
✗  Invent a private testing philosophy that fights L7
```

---

## Missing layers

**Core suite status:** L0–L9 and tool adapters are written. **L10** (ADRs) may still be
empty or thin — use it when present.

If a routing target file is **missing from the consumer repo** (guides not vendored) or an
optional layer (e.g. L10) has no decisions yet:

1. **Do not invent** a parallel house rule for that domain.
2. **Match local code** and existing project instructions.
3. **Ask** if the change hits the [always ask](#always-ask-conservative) list.
4. Otherwise proceed with smallest safe change; for standing “why we chose X” with no ADR,
   ask rather than invent history.

```
✓  Guides vendored: open L7 for test policy
✓  L10 empty: ask before treating a stack choice as sacred forever
✗  Guides missing locally: invent a second style guide in the PR
✗  Ignore L8 because “security isn’t my task” on an auth change
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

When unsure whether something is on the ask list: **ask** (if you can talk to the human).

```
✓  “Should we use Mongo for this new domain?” → ask (L3 / greenfield)
✓  Rename local helper used only in this file → decide (L1)
✗  Introduce a new framework because a skill suggested it → ask, almost always no
✗  Expand “fix login bug” into auth redesign → ask (or refuse expansion)
```

### Parent agent is the authority for subagents

**Subagents cannot ask the human.** They have no reliable user channel for the
conservative ask-list.

| Role | Duty on ask-list items |
|---|---|
| **Subagent** | Does **not** invent product/architecture answers alone. Surfaces the decision need to the **parent** (return a clear blocker / options / recommendation). Stays inside the brief and owned paths. |
| **Parent agent** (session that spawned the subagent) | **Acts as the authority** in place of the human for that subagent: decides using these guides, local code, STATUS, and the original user task — **or** escalates to the real human when the parent itself must ask. |
| **Human** | Still the authority for the parent session on the always-ask list. |

Rules:

1. **Subagent hits an always-ask item** → stop autonomous expansion; report to parent with
   options and a recommended choice when possible. Do not silently pick a new stack,
   break a schema, or expand scope.
2. **Parent receives that report** → either:
   - **Decide** for the subagent (guides + task intent + local code), and resume the
     subagent with an explicit decision; or
   - **Ask the human** when the parent would have asked anyway (greenfield stack, destructive
     data, security model, true product ambiguity).
3. **Parent must not launder responsibility** — “the subagent chose Mongo” is invalid. The
   parent owns decisions it approved for subagents.
4. **Write decisions down** (STATUS, PR, or brief handoff) so other agents/subagents do not
   re-litigate.

```
✓  Subagent: “Need stack for new worker — options A/B; recommend B per L3. Parent decide.”
✓  Parent: decides B from guides + user goal, or asks human if still ambiguous
✗  Subagent silently scaffolds a new service and new DB because it “had to progress”
✗  Parent ignores ask-list and says “whatever, keep going” on destructive migration
```

Parallel **peer** agents (separate sessions both talking to the human) still **ask the
human** on the always-ask list — only **subagents under a parent** use parent-as-authority.

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
5. **Git hygiene** — feature work on a branch from the integration base; PR small and
   purposeful when review-ready; no silent commits to protected base as the normal path.
6. **Short summary** — what changed, what was deliberately not changed, open questions.

Complete does **not** mean perfect, fully refactored, or every nearby smell fixed.

### Post-task check

Before calling the work done:

1. Scope — no out-of-scope edits  
2. Guides — opened and applied the right L\*  
3. Tests — not worse  
4. Lint/types — clean if applicable  
5. Summary — written  
6. Handoff — STATUS updated or cleared; PR description if review-ready  
7. Git — on correct base lineage; PR not a mega-diff; branch deletable after merge  

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

When **multiple agents or humans** share a repo, prefer **one STATUS per workstream**
(see [Parallel agents](#parallel-agents-and-subagents)) or clear sections so Do-not-touch
and Goal do not overwrite each other.

---

## Team-style git flow

Work **as if a team of developers** shares the repo: isolated feature work, review via PR,
small diffs, clean branch hygiene. This is protocol law for agents using these guides
unless the project explicitly documents a different model.

### Integration base

| Situation | Base branch |
|---|---|
| Repo has `develop` (or `dev`) | Branch from and open PRs into **`develop`** (or project’s named integration branch) |
| No develop-style branch | Branch from and open PRs into **`main`** (or `master` if that is the default) |

Always **branch off the current integration base** after updating it (fetch + fast-forward
or rebase onto latest base). Do not start feature work from a stale or random commit.

```
✓  git fetch && git checkout develop && git pull && git checkout -b feat/short-name
✓  PR: feat/short-name → develop (or → main if no develop)
✗  commit feature work directly on main/develop as the normal path
✗  branch from an old feature branch that already mixed three topics
```

### Feature work and PRs

- **New features and non-trivial fixes** → **branch + PR**. Treat the team (humans and
  agents) as reviewers via the PR.
- **Small PR ≫ big PR.** Prefer several focused PRs over one mega-diff. Split by
  concern when a change grows (L1 smallest change still applies inside each PR).
- One PR ≈ one clear purpose. Do not bundle unrelated refactors (hard ban on drive-bys).
- Agent **opens / updates the PR**; **human merges** into the protected integration base
  (aligns L9: human ships protected integration / prod paths). Do not force-push shared
  bases; do not merge your own PR to `main`/`develop` unless the human explicitly said so
  for this task.

### After merge

- The **merged feature branch is considered deleted** — delete local and remote feature
  branches after merge (or rely on host auto-delete). Do not keep landing commits on a
  merged branch.
- Next work: **branch again from the updated integration base**, not from the dead branch.

```
✓  merge PR → delete feat/… → checkout develop → pull → new branch
✗  reopen the merged branch and pile the next feature on it
```

### Conflicts

When your branch conflicts with the base or another change:

1. **Update onto the latest integration base** — prefer **rebase** onto latest
   `develop`/`main` (or the PR’s target), then fix conflicts.
2. **Understand the other side** before resolving: read the conflicting hunks, the other
   PR/commit message, and STATUS / Do-not-touch if another workstream owns the area.
3. Resolve **deliberately** so both intents survive when possible; if they cannot, prefer
   the safer product behavior and **note the choice** in the PR.
4. **Never** blind `take ours` / `take theirs` without reading.
5. If the other change is unclear or high-impact (auth, money, schema) — **ask**.

```
✓  rebase onto latest develop → read both sides → fix → force-with-lease only on your feature branch if needed
✗  git checkout --ours . without reading
✗  resolve by deleting the other feature’s logic to make tests pass
```

### Naming (suggested, not sacred)

Prefer short, purpose-based names: `feat/…`, `fix/…`, `chore/…`. Match project convention
when it exists.

---

## Parallel agents and subagents

Multiple agents (or subagents) may work at once **only with isolation**. Behave like
teammates who do not type in the same dirty working tree.

### Defaults

| Rule | Detail |
|---|---|
| **Isolation** | **One branch per agent/workstream**; prefer **one git worktree** (or clean clone) per parallel agent — **no shared dirty worktree** |
| **Path ownership** | Each workstream lists **Do not touch** / owned paths in its STATUS; do not edit another stream’s files without coordinating |
| **Base** | Every stream branches from the same integration base rules as above |
| **Integration** | Land via **small PRs**; later streams rebase onto base after earlier merges |
| **Handoff** | Per-workstream STATUS (e.g. `docs/agent/STATUS-<short-name>.md`) or clearly separated sections |

```
✓  Agent A: worktree + feat/payments-idempotency
✓  Agent B: worktree + feat/admin-export — non-overlapping paths
✗  two agents `Write` the same files on one dirty checkout
✗  parallel agents both rewriting package-lock without ownership
```

### Starting a parallel workstream

1. Update integration base.  
2. Create branch (and worktree if the tool supports it).  
3. Write STATUS for that stream: Goal, Done, Next, **Do not touch**, Open questions.  
4. Stay inside owned paths unless the human expands scope.  

### When streams collide

- If you need a file another stream owns: **stop**, read their STATUS/PR, and either wait,
  split work, or ask the human.
- Merge conflicts across streams: same conflict rules — rebase, understand the other
  change, no blind overwrite.
- Do not “win” by deleting the other agent’s uncommitted work.

### Subagents spawned by one parent

Subagents inherit **this protocol** (scope, guides, git isolation). Prefer:

- **read-only** explore/review subagents on the same tree;  
- **write** subagents on a **dedicated branch/worktree** when they edit code;  
- parent integrates via PR or explicit sequential merge — not three writers on `main`.

**Ask vs decide:** subagents **cannot ask the human**. On any always-ask item, they
**escalate to the parent**; the **parent decides** (or asks the human). See
[Parent agent is the authority for subagents](#parent-agent-is-the-authority-for-subagents).

When briefing a subagent, the parent should pre-decide or constrain ask-list topics
(stack, scope boundaries, “do not migrate”, owned paths) so the subagent is not blocked
mid-flight without a channel.

```
✓  Parent brief: “TS + existing Nest app only; no new deployable; touch only billing/”
✓  Subagent blocks: “Schema break needed — parent must decide expand steps”
✗  Subagent invents auth model because parent is busy
```

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
| Feature commits straight to main/develop | Team flow breaks; review and rollback suffer |
| Mega-PR with unrelated changes | Review fails; parallel work collides |
| Two agents on one dirty worktree | Overwrites, unexplainable conflicts |
| Blind conflict resolution (ours/theirs) | Silently drops the other teammate’s intent |
| Reusing a merged branch for the next feature | Dirty history; wrong base |
| Subagent silently deciding always-ask items | No human channel; invents architecture |
| Parent blaming subagent for an unapproved stack/schema choice | Parent is the authority for subagents |

---

## When to break the rules

- **Human explicitly overrides** a protocol step for this task (“skip STATUS”, “expand scope to X”, “commit on main for this hotfix”).
- **Emergency production fix** — still no drive-by refactors; smallest branch/PR or documented direct fix; note protocol skips in the summary.
- **Adapter or guide missing in a legacy repo** — follow local project instructions; do not block forever. Prefer adding a thin adapter later.
- **Project documents a different branch model** (e.g. trunk-only) — follow **local** git convention; keep small PRs and conflict understanding anyway.

Breaking “always ask” on greenfield stack or security without a human is **not** a valid
exception.

---

## Done checklist (for work under this protocol)

- [ ] Thin adapter read (or project equivalent)
- [ ] L0 applied; only relevant L\* opened
- [ ] STATUS read if present; updated if WIP spans tools/sessions/workstreams
- [ ] Plan written if non-trivial
- [ ] Ask-list items: human asked (parent session) or parent decided for subagents (documented)
- [ ] No out-of-scope edits
- [ ] Feature branch from integration base (`develop` if present, else `main`)
- [ ] Parallel work isolated (own branch/worktree; path ownership)
- [ ] Tests not worse; lint/types clean if available
- [ ] Short summary delivered
- [ ] Small, purposeful PR when review-ready; description filled
- [ ] After merge: feature branch treated as deleted; next work from fresh base

---

## Relationship to other layers

```
Adapter (tool) → L0 (protocol + git/agents) → L1…L10 (domain law) → code
                           ↑
                 STATUS / branch / PR (handoff)
```

L0 does not replace L1–L10. It ensures every agent enters them the same way, coordinates
like a team on git, and stops at the same done bar. **L9** still owns expand/contract and
prod deploy safety; L0 owns branch/PR/parallel-agent behavior before and around that.
