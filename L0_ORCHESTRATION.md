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
✓  Heavy work only: child branches from live umbrella feat/… (see below), not from a dead merged branch
✗  commit feature work directly on main/develop as the normal path
✗  branch from a merged or abandoned feature branch to start “the next thing”
```

### Feature work and PRs

- **New features and non-trivial fixes** → **branch + PR**. Treat the team (humans and
  agents) as reviewers via the PR.
- **Small PR ≫ big PR** is the default. Prefer several focused PRs over one mega-diff.
  Split by concern when a change grows (L1 smallest change still applies inside each PR).
- One PR ≈ one clear purpose. Do not bundle unrelated refactors (hard ban on drive-bys).
- Agent **opens / updates the PR**; **human merges** into the protected integration base
  (aligns L9: human ships protected integration / prod paths). Do not force-push shared
  bases; do not merge your own PR to `main`/`develop` unless the human explicitly said so
  for this task.

### Heavy work: feature branch as temporary base

When a change is **too large for one focused PR** but still one product goal (multi-slice
feature, multi-module cutover, orchestrated subagent fan-out), keep **one umbrella feature
branch** open to the integration base and treat that branch as the **temporary base** for
child work:

| Role | Branch / PR |
|---|---|
| **Parent / orchestrator** | Owns `feat/big-thing` off `develop`/`main`; opens (or updates) the **umbrella PR** → integration base when review-ready |
| **Subagent / slice** | Branches **from the current umbrella tip** (`feat/big-thing-slice-a`), works in isolation (prefer worktree) |
| **Land child work** | Merge or open a **small PR into the umbrella** (`feat/…-slice-a` → `feat/big-thing`), not into `main`/`develop` |
| **Land the feature** | Human merges the **umbrella PR** into the protected integration base |

```
develop (or main)
  └── feat/big-thing          ← parent owns; umbrella PR target for children
        ├── feat/big-thing-a  ← subagent A → PR/merge back into feat/big-thing
        └── feat/big-thing-b  ← subagent B → PR/merge back into feat/big-thing
```

Rules:

1. **Prefer small PRs still.** Use the umbrella only when splitting into independent
   integration-base PRs would thrash mid-feature (shared WIP types, incomplete surface,
   coordinated multi-file cut). Default remains several PRs into `develop`/`main`.
2. **Children branch from the umbrella tip**, after updating it (fetch + merge/rebase of
   parent’s latest). They do **not** branch from a random sibling or a dead merged branch.
3. **Children do not open PRs to the protected base** for that workstream unless the
   parent re-scopes them. Integration base stays green; WIP lives under the umbrella.
4. **Parent integrates** child merges into `feat/big-thing` (rebase/merge with
   understanding — same conflict rules). Path ownership and hotspots still apply among
   children.
5. **After the umbrella merges** to `develop`/`main`: delete the umbrella **and** all
   child slice branches (local + remote). **Never reuse** any of them for the next feature.
6. Brief write children with the umbrella as **Branch / worktree** base and “merge target =
   umbrella, not main/develop.”

```
✓  Heavy feature: parent holds feat/checkout; subagents branch off it; PR slice → feat/checkout; human merges umbrella → develop; delete all
✓  Light feature: single feat/fix-date → develop; no umbrella
✗  Subagent opens PR straight to main while parent still owns unfinished umbrella WIP
✗  Reuse feat/big-thing after it merged for “phase 2” — open a new branch from updated base
✗  Call every two-file change an “umbrella” to avoid small PRs
```

### After merge

**Delete and do not reuse.** Once a PR lands on the protected integration base:

- The **merged branch is dead** — delete it **local and remote** (or rely on host
  auto-delete). Same for every **child slice branch** under a merged umbrella.
- **Do not reopen, recommit, or rename-reuse** a merged branch for the next task. History
  and base become wrong; parallel agents inherit stale tips.
- Next work: **new branch from the updated integration base** (fetch + pull/ff first),
  even if the product theme continues (“phase 2” of the same feature).

```
✓  merge PR → delete feat/… (and any feat/…-slice-*) → checkout develop → pull → new branch
✓  “same epic, next slice” after merge: still a fresh branch off latest develop
✗  reopen the merged branch and pile the next feature on it
✗  keep a merged remote branch “for convenience” and force-push new work onto it
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
| **Base** | Default: every stream branches from the same **integration base** (`develop`/`main`). Heavy work: children branch from the **live umbrella** feature branch (see above) |
| **Integration** | Default: land via **small PRs** into the integration base. Heavy work: land child slices into the umbrella first; human merges the umbrella PR last |
| **Handoff** | Per-workstream STATUS (e.g. `docs/agent/STATUS-<short-name>.md`) or clearly separated sections |
| **After merge** | Delete merged branches (umbrella + slices); **never reuse** — next work gets a new branch from updated base |

```
✓  Agent A: worktree + feat/payments-idempotency → PR to develop
✓  Agent B: worktree + feat/admin-export — non-overlapping paths
✓  Heavy: parent feat/checkout; A/B worktrees on feat/checkout-a|b → merge into feat/checkout
✗  two agents `Write` the same files on one dirty checkout
✗  parallel agents both rewriting package-lock without ownership
✗  child PR targets main while umbrella WIP is still the intended land path
```

### Starting a parallel workstream

1. Update the correct base (integration base, or the live umbrella tip for heavy work).
2. Create branch (and worktree if the tool supports it).
3. Write STATUS for that stream: Goal, Done, Next, **Do not touch**, Open questions.
4. Stay inside owned paths unless the human expands scope.
5. Know the **merge target** (integration base vs umbrella) before opening a PR.

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

**Where write children branch from:**

| Work size | Child base | Child merge target |
|---|---|---|
| Default / focused | Integration base (`develop`/`main`) | PR into integration base |
| **Heavy** (umbrella) | Parent’s **live** `feat/…` tip | PR/merge into the umbrella; human merges umbrella last |

Do not leave write children on the parent’s dirty checkout. After any PR merges to the
protected base, **delete** those branches — children never “keep” a merged branch for
follow-on work.

**Context packing (required for write children):** every write subagent must receive enough
protocol to obey it — at minimum: path to **L0** (or an embedded child brief that restates
isolation + escalate-to-parent + owned paths), `GUIDES_ROOT`, owned/forbidden paths,
**branch base + merge target**, and decisions already made. A three-line “go implement X”
with no L0 is a protocol failure by the parent.

When briefing a subagent, the parent should pre-decide or constrain ask-list topics
(stack, scope boundaries, “do not migrate”, owned paths) so the subagent is not blocked
mid-flight without a channel. Use the brief template below.

```
✓  Parent brief: “TS + existing Nest app only; no new deployable; touch only billing/”
✓  Heavy: “Base = feat/checkout@latest; PR target = feat/checkout; do not open PR to main”
✓  Subagent blocks: “Schema break needed — parent must decide expand steps”
✗  Subagent invents auth model because parent is busy
✗  Parent spawns writer with no GUIDES_ROOT and no owned paths
✗  Parent spawns writer with no merge target (“just push somewhere”)
```

### Subagent brief and result templates

Copy/adapt these in the parent prompt or STATUS. Keep short.

**Brief (parent → child):**

```markdown
## Brief
- Goal:
- GUIDES_ROOT:
- Read first: L0 (+ L0_ORCHESTRATION if writing on a branch; L1/L7/… as needed)
- Owned paths:
- Do not touch:
- Decisions already made: (stack, scope, no new service, …)
- Branch / worktree: (create from …)
- Merge target: (integration base | umbrella feat/… — not both)
- Done means:
- On always-ask items: escalate to parent (you cannot ask the human)
```

**Result (child → parent):**

```markdown
## Result
- Status: done | blocked | partial
- Summary:
- Branch / PR: (and merge target)
- Files touched:
- Tests / verify:
- Blockers / decisions needed: (options + recommendation)
- Do not touch still holds: yes/no
```

### Orchestrator checklist

When one agent **plans and delegates** (tech-lead / orchestrator role):

1. **Understand** user goal; open L0 + relevant L\*.
2. **Plan** workstreams (≤5 bullets each); prefer small PRs into the integration base.
3. **Choose shape:** default multi-PR into base, **or** heavy umbrella + child slices
   that merge back into the feature branch first.
4. **Assign** owned paths; name hotspot owners; forbid shared dirty trees.
5. **Brief** each write child with the template above (include L0 / GUIDES_ROOT, **base +
   merge target**).
6. **Run** children in parallel only when paths/hotspots don’t fight.
7. **Collect** results; decide or escalate ask-list items (hard list → human).
8. **Integrate** — rebase onto the correct base (integration or umbrella), fix conflicts
   with understanding, open/update PRs.
9. **Human merges** protected base (umbrella last if heavy); **delete** feature + slice
   branches after merge — **do not reuse**.
10. **Update** STATUS; clear done streams.

```
✓  Orchestrator sequences migration PR before feature PR that depends on it
✓  Heavy: children merge to feat/…; only umbrella PR hits develop; then delete all
✗  Fan-out five writers on one worktree with one sentence each
✗  After merge, “reuse” feat/… for the next epic instead of a fresh branch
```

---

## Anti-patterns (orchestration)

| Anti-pattern | Why it hurts |
|---|---|
| Feature commits straight to main/develop | Team flow breaks; review and rollback suffer |
| Mega-PR with unrelated changes | Review fails; parallel work collides |
| Umbrella for every small change | Fake “heavy work”; delays review; fights small-PR default |
| Child PR to main while umbrella is the land path | Splits WIP; base gets half-feature; parent loses control |
| Two agents on one dirty worktree | Overwrites, unexplainable conflicts |
| Blind conflict resolution (ours/theirs) | Silently drops the other teammate’s intent |
| Reusing a merged branch for the next feature | Dirty history; wrong base; **delete after merge is law** |
| Keeping merged remotes “for later” | Someone force-pushes new work onto a dead tip |
| Subagent silently deciding always-ask items | No human channel; invents architecture |
| Parent blaming subagent for an unapproved stack/schema choice | Parent is the authority for subagents |
| Parent rubber-stamping destructive/auth/deployable choices | Hard items must reach the human |
| Write subagent without L0 / owned paths / merge target in brief | Protocol never enters context |
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
