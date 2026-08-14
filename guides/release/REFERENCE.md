# Release — reference

Binding surface: [`RULES.md`](RULES.md). This file keeps the original change-and-release prose and examples.

How to ship schema, API, and behavior changes without locking readers out, destroying
data you cannot restore, or treating “deploy” as the same thing as “safe.”

**The goal:** agents stop one-shot migrations that break old code, silent destructive
prod edits, and flag/config chaos. Rollout is a sequence, not a single merge.

## Scope of this guide

**In scope**

- Expand/contract for schema and published APIs
- Deploy vs migrate ordering
- Feature flags / runtime config as the control plane
- Rollback reality (app vs data)
- Environments and artifact promotion
- What agents may prepare vs what humans must approve
- Hotfix minimum bar

**Out of scope**

| Concern | Where it lives |
|---|---|
| Migration *data safety* facts (NULLs, loss, applied history) | **../data/REFERENCE.md** |
| Wire contract shape / versioning vocabulary | **../contracts/REFERENCE.md** |
| Observability during/after ship | **../observability/REFERENCE.md** |
| Test proof before ship | **../testing/REFERENCE.md** |
| Auth/secrets product policy | **../security/REFERENCE.md** |
| CI vendor YAML | Project-local |
| Feature branch / PR / parallel-agent workflow | **../orchestration/REFERENCE.md** (team-style git flow) |
| On-call pages / SLO burn math | Out of suite for now |

../data/REFERENCE.md says the data must remain valid during change. **This guide says in what order you deploy the
steps** and how you control blast radius.

## What “complete” means

A production-bound change is complete when:

1. Old and new code/readers were considered (expand before contract).
2. Destructive or irreversible data steps had **explicit human approval**.
3. Behavior risk is controlled (flags/config and/or compatible multi-step rollout).
4. Rollback path for **app** is known; **data** forward-fix is planned if down is fake.
5. Same artifact can run in each env with config/flags differing — not a laptop-only build.
6. Tests are not worse; relevant suite green (../testing/REFERENCE.md).

---

## 1. Expand / contract (default for prod schema)

Never require “new code only understands new schema” in the same instant as a breaking
DDL — unless you have an approved downtime plan (rare; **ask**).

### Order

```
1. Expand   — additive schema (nullable column, new table, new index concurrent if needed)
2. Deploy   — code that works with old + new shapes
3. Backfill — populate new data safely (batch; observable; restartable)
4. Switch   — code prefers new path (often behind flag/config)
5. Contract — remove old column/path only when nothing reads it
```

```
✓  add column nullable → deploy readers/writers dual-safe → backfill → NOT NULL → drop old
✗  rename column + deploy code that only knows the new name in one shot
✗  add NOT NULL before backfill
✗  “down migration” as the plan to un-delete production rows
```

Large backfills are **separate** from the schema expand when runtime or failure modes
differ (../data/REFERENCE.md). Watch progress, rejects, reconciliation, and relevant freshness/volume with
../observability/REFERENCE.md signals.

---

## 2. API and behavior rollout

Same spirit as schema (align **../contracts/REFERENCE.md**):

```
Expand contract → migrate clients → remove old
```

- Support **old + new** wire shapes during transition when you do not control all clients.
- Additive fields first; breaking changes need version or approval (../contracts/REFERENCE.md + ../protocol/REFERENCE.md).
- Dual-write / dual-read only with a clear owner and exit criteria — not forever.

```
✓  accept v1 and v2 bodies; emit v2; deprecate v1; remove later
✗  break JSON field meaning on Tuesday because the app shipped
```

---

## 3. Feature flags and runtime config

**Flags/config are a primary control system** for this author — not only temporary
release toggles.

Use them for:

- gradual or instant behavior switches in prod;
- env-specific and runtime configuration that should not require a rebuild;
- kill-switches for risky paths.

Rules:

| Do | Don't |
|---|---|
| Name flags clearly; document default | Mystery `flag_37` with no owner |
| **Clean up dead flags regularly** | Infinite flag graveyard |
| Default safe when flag service is down (fail closed/open **intentionally**) | Crash loop if config missing without a plan |
| Prefer config for “what mode is prod in” over hardcoding | Bake secrets into images (→ ../security/REFERENCE.md) |

Long-lived flags for product modes are OK. **Stale rollout flags** after the bake is done
are not — remove code paths and flag entries.

```
✓  payments.new_ledger default false → enable in prod → remove old path + flag
✓  config-driven rate limit or feature mode
✗  200 permanent flags nobody dares delete
✗  ship irreversible data rewrite only gated by a flag you never verified
```

---

## 4. Rollback reality

| Layer | Expectation |
|---|---|
| **Application** | Rollback / redeploy previous artifact should be **easy** and routine |
| **Data** | Rollback is **often impossible** after destructive migration or backfill |

Design for **forward fix** on data: expand/contract, dual paths, compensating writes —
not “run down.sql and pray” (../data/REFERENCE.md).

```
✓  app bad → redeploy previous version; schema still compatible (because expand)
✓  bad backfill → repair script / compensating migration with approval
✗  drop column then “rollback the app” and expect old code to work
✗  treat down migrations as proof production data returns
```

---

## 5. Environments and artifacts

- **Promote the same build artifact** across environments (or the same immutable image
  digest). Config and flags differ by env — not a special “prod-only” compile.
- Dev/staging should exercise migrations and flag defaults before prod when the change is
  non-trivial.
- Do not rely on “only works on my machine” local state as the release path.

```
✓  same image → staging → prod; DATADOG/FLAG/DB urls from env
✗  hand-built prod binary with different code than CI
```

---

## 6. What agents may do vs must ask

| Agents may | Always ask / human owns |
|---|---|
| Prepare PR, migration files, expand steps, flag plan | **Production deploy** |
| Dual-write/read design in code | **Destructive** schema or data loss |
| Staging-oriented checklists and verify commands | **Hard API break** without expand path |
| Document rollback/forward-fix notes in PR | **Prod data backfill** that rewrites money/history |

**Human ships prod.** Agent prepares the plan and the change set. Project CI may auto-deploy
non-prod; that does not grant prod autonomy.

Matches ../protocol/REFERENCE.md: schema/API breaks, security, scope expansion — ask.

---

## 7. Hotfix / emergency

- **Smallest change** that stops the bleeding.
- Still **no silent data destruction**.
- May skip non-essential ceremony (extra flags, perfect expand theater) for pure **app
  revert** or a one-line safe fix — **note what you skipped** in the PR/summary.
- Destructive data emergency still needs a human decision and a written loss/repair plan.

```
✓  revert bad release artifact; leave expanded columns in place
✗  “emergency” DROP TABLE without approval
```

---

## 8. Release checklist (non-destructive)

Use as a default pre-prod mental list:

1. Tests green / not worse (../testing/REFERENCE.md)
2. Compatible with currently running code (expand if needed)
3. Flags/config defaults safe
4. Observability on the new path (../observability/REFERENCE.md)
5. Rollback = previous app artifact still works against current DB
6. PR states expand/contract step and what is **not** yet contracted

Destructive extras:

7. Explicit human approval
8. Data-loss / irreversibility statement
9. Forward-fix plan if rollback cannot restore data

---

## 9. Anti-patterns

```
✗ breaking DDL + breaking code in one deploy
✗ NOT NULL before backfill
✗ rewrite applied migrations on shared environments
✗ assume down migration restores prod data
✗ agent pushes production without approval
✗ flag graveyard never cleaned
✗ different code artifacts per environment by habit
✗ contract (drop old) while old app instances still run
✗ silent meaning change of an API field on ship day
```

---

## 10. Intentional patterns that may look like mistakes

**Multiple deploys for one “feature.”** Correct expand/contract — not inefficiency.

**Column left nullable longer than aesthetic purity wants.** Backfill and dual-read need
time.

**Long-lived product flags.** OK when they are real config; clean up *dead* ones.

**No down migration for a destructive step.** Safer than a lying down migration (../data/REFERENCE.md).

**App rollback without schema rollback.** Expected when expand was done right.

---

## When to break these rules

- Author approves a maintenance window and single-shot cutover.
- Solo local prototype with no shared prod — still don’t build habits that can’t promote.
- Platform provides stronger primitives (online DDL, automatic expand) — use them; keep
  the compatibility idea.
- Emergency: smallest safe fix; document skipped steps; never skip approval on data loss.

Working production and recoverable mistakes beat one-shot elegance.

---

## Done checklist

- [ ] Expand before contract for schema/API when old readers exist
- [ ] Deploy order: expand → compatible code → backfill → switch → contract
- [ ] Flags/config used as control plane; dead flags not left forever
- [ ] App rollback path known; data forward-fix known if destructive
- [ ] Same artifact promotion model; env via config/flags
- [ ] Destructive / prod ship: human approval
- [ ] Agent prepared plan/PR only for prod; did not self-ship prod
- [ ] Hotfix: smallest change; no silent data destruction; skips noted
- [ ] ../data/REFERENCE.md data rules and ../contracts/REFERENCE.md contract rules still held
- [ ] Tests not worse (../testing/REFERENCE.md); signals for the path exist (../observability/REFERENCE.md)

## Relationship to other layers

| Topic | Layer |
|---|---|
| Ask vs decide, scope | **../protocol/REFERENCE.md** |
| Migration data validity | **../data/REFERENCE.md** |
| API break definition | **../contracts/REFERENCE.md** |
| See it in prod | **../observability/REFERENCE.md** |
| Prove before ship | **../testing/REFERENCE.md** |
| Secrets in config | **../security/REFERENCE.md** |
