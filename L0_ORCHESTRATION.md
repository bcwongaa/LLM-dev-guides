# L0.1 — Orchestration (git flow, parallel agents, subagents)

Companion to `L0_AGENT_PROTOCOL.md`. L0 is the **every-task core**; this file is the
**orchestration annex**. Load it **only when the task involves**:

- creating or updating branches / PRs, or resolving merge conflicts
- spawning subagents (any write child)
- running parallel agents or multiple workstreams
- acting as orchestrator / tech-lead over other agents

A solo one-file bugfix does **not** need this file — L0 core covers it.

**Authority rules live in L0** (ask vs decide, parent-as-authority, hard human items).
This file adds the *mechanics*: git flow, isolation, hotspots, briefs, checklists.

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

### Shared hotspots (serialize)

Some paths cannot be safely parallel-edited. Assign **one owner workstream** or run
**serially** (queue):

| Hotspot (examples) | Rule |
|---|---|
| Lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `Cargo.lock`, …) | One owner per change wave |
| Migration chains / linear schema history | One writer; others wait or stack after merge |
| Generated dumps that rewrite whole files | One owner |
| Global CI config / root release config | One owner unless split is explicit |

```
✓  Agent A owns migrations this wave; B does not touch supabase/migrations/
✓  After A merges, B rebases and adds its migration
✗  A and B both regenerate package-lock on parallel branches without a merge plan
```

If two streams both need a hotspot: **stop**, coordinate via parent/STATUS, or sequence PRs.

### When streams collide

- If you need a file another stream owns: **stop**, read their STATUS/PR, and either wait,
  split work, or escalate (human if peer sessions; parent if subagent).
- Merge conflicts across streams: same conflict rules — rebase, understand the other
  change, no blind overwrite.
- Do not “win” by deleting the other agent’s uncommitted work.

---

## Parent / subagent authority (detail)

L0 states the rules; this section is the worked detail.

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
5. **Hard escalate to the human** (parent must not rubber-stamp) for:
   - destructive or irreversible **data** loss;
   - **new auth model** / security boundary change;
   - **new deployable** / multi-repo split;
   - true **product ambiguity** the user task does not settle.
   On those, parent asks the human even when unblocking a subagent. Other ask-list items
   (routine scope edge, non-destructive dual-write design within an approved feature) the
   parent may decide from guides + task.

```
✓  Subagent: “Need stack for new worker — options A/B; recommend B per L3. Parent decide.”
✓  Parent: decides B from guides + user goal, or asks human if still ambiguous
✓  Parent: subagent wants DROP COLUMN — parent asks human, does not auto-approve
✗  Subagent silently scaffolds a new service and new DB because it “had to progress”
✗  Parent rubber-stamps destructive migration “to unblock” the child
```

Parallel **peer** agents (separate sessions both talking to the human) still **ask the
human** on the always-ask list — only **subagents under a parent** use parent-as-authority.

### Nested spawners (multi-level delegation)

Authority is always **direct spawner**, not “any ancestor” improvising:

```
Human
  └─ Root parent (only role that asks the human)
        └─ Child A (subagent)     → escalates to Root
              └─ Grandchild A1   → escalates to Child A (not straight to Human)
```

| Rule | Detail |
|---|---|
| **Escalate to direct parent only** | A worker reports blockers to who spawned it |
| **Only root talks to human** | Intermediate parents either decide (within guides + brief) or escalate upward |
| **Same hard human list** | Destructive data, new auth, new deployable, true product ambiguity — bubble to root → human |
| **No orphan writers** | Every write agent has a clear parent responsible for its decisions |

```
✓  A1 blocks on schema → A decides or escalates to root → root asks human if hard item
✗  A1 “asks the human” directly and ignores A
✗  Root claims it never knew A approved a new service
```

### Subagents spawned by one parent

Subagents inherit **the L0 protocol** (scope, guides, git isolation). Prefer:

- **read-only** explore/review subagents on the same tree;
- **write** subagents on a **dedicated branch/worktree** when they edit code;
- parent integrates via PR or explicit sequential merge — not three writers on `main`.

**Context packing (required for write children):** every write subagent must receive enough
protocol to obey it — at minimum: path to **L0** (or an embedded child brief that restates
isolation + escalate-to-parent + owned paths), `GUIDES_ROOT`, owned/forbidden paths, and
decisions already made. A three-line “go implement X” with no L0 is a protocol failure by
the parent.

When briefing a subagent, the parent should pre-decide or constrain ask-list topics
(stack, scope boundaries, “do not migrate”, owned paths) so the subagent is not blocked
mid-flight without a channel. Use the brief template below.

```
✓  Parent brief: “TS + existing Nest app only; no new deployable; touch only billing/”
✓  Subagent blocks: “Schema break needed — parent must decide expand steps”
✗  Subagent invents auth model because parent is busy
✗  Parent spawns writer with no GUIDES_ROOT and no owned paths
```

### Subagent brief and result templates

Copy/adapt these in the parent prompt or STATUS. Keep short.

**Brief (parent → child):**

```markdown
## Brief
- Goal:
- GUIDES_ROOT:
- Read first: L0 (+ L1/L7/… as needed)
- Owned paths:
- Do not touch:
- Decisions already made: (stack, scope, no new service, …)
- Branch / worktree:
- Done means:
- On always-ask items: escalate to parent (you cannot ask the human)
```

**Result (child → parent):**

```markdown
## Result
- Status: done | blocked | partial
- Summary:
- Branch / PR:
- Files touched:
- Tests / verify:
- Blockers / decisions needed: (options + recommendation)
- Do not touch still holds: yes/no
```

### Orchestrator checklist

When one agent **plans and delegates** (tech-lead / orchestrator role):

1. **Understand** user goal; open L0 + relevant L\*.
2. **Plan** workstreams (≤5 bullets each); prefer small PRs.
3. **Assign** owned paths; name hotspot owners; forbid shared dirty trees.
4. **Brief** each write child with the template above (include L0 / GUIDES_ROOT).
5. **Run** children in parallel only when paths/hotspots don’t fight.
6. **Collect** results; decide or escalate ask-list items (hard list → human).
7. **Integrate** — rebase onto base, fix conflicts with understanding, open/update PRs.
8. **Human merges** protected base; delete feature branches after merge.
9. **Update** STATUS; clear done streams.

```
✓  Orchestrator sequences migration PR before feature PR that depends on it
✗  Fan-out five writers on one worktree with one sentence each
```

---

## Anti-patterns (orchestration)

| Anti-pattern | Why it hurts |
|---|---|
| Feature commits straight to main/develop | Team flow breaks; review and rollback suffer |
| Mega-PR with unrelated changes | Review fails; parallel work collides |
| Two agents on one dirty worktree | Overwrites, unexplainable conflicts |
| Blind conflict resolution (ours/theirs) | Silently drops the other teammate’s intent |
| Reusing a merged branch for the next feature | Dirty history; wrong base |
| Subagent silently deciding always-ask items | No human channel; invents architecture |
| Parent blaming subagent for an unapproved stack/schema choice | Parent is the authority for subagents |
| Parent rubber-stamping destructive/auth/deployable choices | Hard items must reach the human |
| Write subagent without L0 / owned paths in brief | Protocol never enters context |
| Parallel edits to lockfile or migration chain | Unmergeable or broken history |
| Nested child escalating to human, skipping parent | Breaks authority chain |

---

## When to break these rules

- **Human explicitly overrides** a step for this task (“commit on main for this hotfix”).
- **Emergency production fix** — still no drive-by refactors; smallest branch/PR or
  documented direct fix; note protocol skips in the summary.
- **Project documents a different branch model** (e.g. trunk-only) — follow **local** git
  convention; keep small PRs and conflict understanding anyway.

---

## Relationship to other layers

```
Adapter (tool) → L0 (every-task core) → this file (when branching / spawning) → L1…L10 → code
```

L0 owns ask-vs-decide and the done bar; this file owns the git/parallel mechanics around
them. **L9** still owns expand/contract and prod deploy safety.
