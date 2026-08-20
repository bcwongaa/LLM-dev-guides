# Release

Ship schema, API, and behavior without locking readers out or treating deploy as safe. Branch / PR: [`../orchestration/RULES.md`](../orchestration/RULES.md). Ask vs decide: [`../protocol/RULES.md`](../protocol/RULES.md). Rationale: [`REFERENCE.md`](REFERENCE.md).

**Scope `[suite-default]`:** Expand/contract for schema and published APIs; Deploy vs migrate ordering; flags/config as the control plane; rollback reality; artifact promotion; agent vs human; Hotfix minimum bar.

**Out of scope:** data-validity, wire vocabulary, telemetry, tests, secrets policy, ADRs, CI YAML, git flow, On-call pages / SLO burn math. Data must stay valid. **This file is the deploy order** and blast-radius control.

## Relocated — do not restate

[protocol](../protocol/RULES.md) · [orchestration](../orchestration/RULES.md) · [data](../data/RULES.md) · [contracts](../contracts/RULES.md) · [observability](../observability/RULES.md) · [security](../security/RULES.md) · [decisions](../decisions/RULES.md)

## Complete `[suite-default]`

Old and new readers considered (expand before contract). Destructive data steps had **explicit human approval**. Behavior risk controlled (flags/config and/or multi-step rollout). **App** rollback known; **data** forward-fix planned if down is fake. Same artifact per env via config/flags — not a laptop-only build. Tests not worse.

## 1. Expand / contract `[suite-default]`

Expand / contract (default for prod schema). Never require “new code only understands new schema” in the same instant as a breaking DDL — unless an approved downtime plan (rare; **ask**).

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
✗  add NOT NULL before backfill
✗  “down migration” as the plan to un-delete production rows
```

Large backfills are **separate** from the schema expand when runtime or failure modes differ (data). Watch progress and rejects (observability).

## 2. API and behavior rollout `[suite-default]`

Same spirit (align contracts):

```
Expand contract → migrate clients → remove old
```

Support **old + new** wire shapes when you do not control all clients. Additive fields first; breaking changes need version or approval (contracts + protocol). Dual-write / dual-read only with a clear owner and exit criteria — not forever.

```
✓  accept v1 and v2 bodies; emit v2; deprecate v1; remove later
✗  break JSON field meaning on Tuesday because the app shipped
```

## 3. Feature flags and runtime config `[suite-default]`

**Flags/config are a primary control system** — not only temporary release toggles. Use for gradual or instant prod switches; env/runtime config that must not require a rebuild; kill-switches.

Name flags; document default. **Clean up dead flags regularly.** Default safe when flag service is down (fail closed/open **intentionally**). Prefer config for “what mode is prod in”; never bake secrets into images (→ security).

Long-lived product-mode flags are OK. **Stale rollout flags** after the bake are not — remove code paths and flag entries.

```
✓  payments.new_ledger default false → enable in prod → remove old path + flag
✗  200 permanent flags nobody dares delete
✗  ship irreversible data rewrite only gated by a flag you never verified
```

## 4. Rollback reality `[suite-default]`

| Layer | Expectation |
|---|---|
| **Application** | Rollback / redeploy previous artifact should be **easy** and routine |
| **Data** | Rollback is **often impossible** after destructive migration or backfill |

Design for **forward fix** on data: expand/contract, dual paths, compensating writes — not “run down.sql and pray” (data).

```
✓  app bad → redeploy previous version; schema still compatible (because expand)
✗  drop column then “rollback the app” and expect old code to work
```

## 5. Environments and artifacts `[common]`

**Promote the same build artifact** across environments (or the same immutable image digest). Config and flags differ by env — not a special “prod-only” compile. Staging should exercise migrations and flag defaults before prod when non-trivial. Do not rely on “only works on my machine.”

```
✓  same image → staging → prod; DATADOG/FLAG/DB urls from env
✗  hand-built prod binary with different code than CI
```

## 6. What agents may do vs must ask `[suite-default]`

| Agents may | Always ask / human owns |
|---|---|
| Prepare PR, migration files, expand steps, flag plan | **Production deploy** |
| Dual-write/read design in code | **Destructive** schema or data loss |
| Staging-oriented checklists and verify commands | **Hard API break** without expand path |
| Document rollback/forward-fix notes in PR | **Prod data backfill** that rewrites money/history |

**Human ships prod.** Agent prepares the plan and change set. CI may auto-deploy non-prod; that is not prod autonomy. Matches protocol: schema/API breaks, security, scope — ask.

## 7. Hotfix / emergency `[suite-default]`

**Smallest change** that stops the bleeding. Still **no silent data destruction**. May skip non-essential ceremony (extra flags, perfect expand theater) for pure **app revert** or a one-line safe fix — **note what you skipped**. Destructive data emergency still needs a human decision and a written loss/repair plan.

```
✓  revert bad release artifact; leave expanded columns in place
✗  “emergency” DROP TABLE without approval
```

## 8. Release checklist `[suite-default]`

Non-destructive pre-prod list: tests green / not worse; compatible with currently running code (expand if needed); flags/config defaults safe; observability on the new path; Rollback = previous app artifact still works against current DB; PR states expand/contract step and what is not yet contracted.

Destructive extras: explicit human approval; Data-loss / irreversibility statement; forward-fix plan if rollback cannot restore data.

## When to break `[suite-default]`

Author approves a maintenance window and single-shot cutover. Solo local prototype with no shared prod — still don’t build habits that can’t promote. Stronger platform primitives (online DDL, automatic expand) — use them; keep compatibility. Emergency: smallest safe fix; document skipped steps; never skip approval on data loss.

## Never

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

## Looks wrong, is intentional `[suite-default]`

**Multiple deploys for one “feature.”** Correct expand/contract — not inefficiency.

**Column left nullable longer than aesthetic purity wants.** Backfill and dual-read need time.

**Long-lived product flags.** OK when they are real config; clean up *dead* ones.

**No down migration for a destructive step.** Safer than a lying down migration (data).

**App rollback without schema rollback.** Expected when expand was done right.

## Done `[suite-default]`

Expand before contract when old readers exist. Order: expand → compatible code → backfill → switch → contract. Flags/config as control plane; dead flags not left forever. App rollback known; data forward-fix known if destructive. Same artifact promotion; env via config/flags. Destructive / prod ship: human approval. Agent prepared plan/PR only; did not self-ship prod. Hotfix: smallest change; no silent data destruction; skips noted. Data and contract rules still held. Tests not worse; signals for the path exist.
