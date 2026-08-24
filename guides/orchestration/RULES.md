# Orchestration

Git flow, parallel agents, and subagent mechanics. Load **only** when branching/PRing, spawning write children, running parallel workstreams, or acting as orchestrator. Authority, ask vs decide, and the done bar live in [`../protocol/RULES.md`](../protocol/RULES.md). Templates and full prose: [`REFERENCE.md`](REFERENCE.md).

**Scope `[suite-default]`:** integration base, small PRs, umbrellas, delete-after-merge, conflicts, isolation, hotspots, parent/child briefs. A solo one-file fix does not need this file.

## Integration base `[common]`

| Situation | Base |
|---|---|
| Repo has `develop` (or `dev`) | Branch from and PR into **`develop`** |
| No develop-style branch | Branch from and PR into **`main`** (or `master`) |

Update the base first (fetch + fast-forward). Do not start feature work from a stale or random commit. Do not commit feature work directly on `main`/`develop` as the normal path.

## Feature work `[suite-default]`

New features and non-trivial fixes → **branch + PR**. Small PR ≫ big PR. One PR ≈ one purpose. No bundled unrelated refactors.

Agent opens/updates the PR. **Human merges** the protected integration base. Do not merge your own PR to `main`/`develop` unless the human explicitly said so for this task.

## Umbrella (heavy work only) `[suite-default]`

Use an umbrella feature branch only when independent PRs into the base would thrash mid-feature. Default remains several PRs into `develop`/`main`.

| Role | Branch / PR |
|---|---|
| Parent | Owns `feat/big-thing` off the integration base; umbrella PR → base when review-ready |
| Child / slice | Branches from the **live umbrella tip**; PR/merge **into the umbrella**, not into `main`/`develop` |
| Land the feature | Human merges the umbrella PR |

After the umbrella merges: delete the umbrella **and** every child slice (local + remote). **Never reuse** any of them.

```
✗  Subagent opens PR straight to main while umbrella WIP is the land path
✗  Reuse feat/big-thing after it merged
✗  Call every two-file change an umbrella
```

## After merge `[suite-default]`

The merged branch is dead. Delete it local and remote. Next work: **new branch from the updated integration base**, even if the product theme continues.

## Conflicts `[common]`

1. Rebase onto the latest target (integration base or umbrella).
2. **Understand the other side** before resolving: hunks, the other PR/commit, STATUS / Do-not-touch.
3. Keep both intents when possible; if not, prefer the safer product behavior and **note the choice**.
4. **Never** blind `take ours` / `take theirs`.
5. Unclear or high-impact (auth, money, schema) → ask / escalate.

## Isolation `[suite-default]`

Multiple agents may work at once **only with isolation**. One branch per workstream; prefer one worktree (or clean clone) per parallel agent. **No shared dirty worktree.**

Each stream lists owned paths and **Do not touch** in its STATUS. Default: every stream branches from the same integration base. Heavy work: children branch from the live umbrella.

## Hotspots — serialize `[suite-default]`

Assign **one owner** or run serially:

- lockfiles
- migration chains / linear schema history
- generated dumps that rewrite whole files
- global CI / root release config

If two streams both need a hotspot: **stop**, coordinate via parent/STATUS, or sequence PRs. Do not “win” by deleting another agent’s uncommitted work.

## Parent / child `[suite-default]`

Protocol owns the authority rules. This file is the mechanic:

- Write children get a dedicated branch/worktree. Do not leave them on the parent’s dirty checkout.
- Every write child is briefed with: `GUIDES_ROOT`, protocol path, owned/forbidden paths, **branch base + merge target**, decisions already made, escalate-to-parent. A three-line “go implement X” with no protocol is a parent failure.
- Default child base = integration base. Heavy = live umbrella tip; merge target = umbrella.
- Nested children escalate to the **direct spawner** only. Only the root talks to the human.
- Parent owns decisions it approves. Hard items (destructive data, new auth, new deployable, true product ambiguity) are not rubber-stamped.

Brief and result templates: REFERENCE.

## Orchestrator checklist `[suite-default]`

1. Understand the goal; open protocol + relevant guides.
2. Plan workstreams (≤5 bullets each); prefer small PRs into the integration base.
3. Choose shape: multi-PR into base, **or** heavy umbrella + slices.
4. Assign owned paths; name hotspot owners; forbid shared dirty trees.
5. Brief each write child (include protocol / `GUIDES_ROOT` / base + merge target).
6. Parallelize only when paths/hotspots do not fight.
7. Collect results; decide or escalate (hard list → human).
8. Integrate with understanding; open/update PRs.
9. Human merges protected base (umbrella last if heavy); **delete** branches — do not reuse.
10. Update STATUS; clear done streams.

## When to break `[suite-default]`

- Human explicitly overrides a step for this task (“commit on main for this hotfix”).
- Emergency production fix — still no drive-bys; smallest branch/PR or documented direct fix.
- Project documents a different branch model (e.g. trunk-only) — follow **local** git; keep small PRs and conflict understanding.

## Never

```
✗ Feature commits straight to main/develop as the normal path
✗ Mega-PR with unrelated changes
✗ Umbrella for every small change
✗ Child PR to main while the umbrella is the land path
✗ Two agents on one dirty worktree
✗ Blind conflict resolution
✗ Reusing a merged branch
✗ Write child with no protocol / owned paths / merge target
✗ Parallel edits to a lockfile or migration chain
✗ Nested child skipping its parent to “ask the human”
```
