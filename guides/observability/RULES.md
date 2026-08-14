# Observability

What a system must emit so failures, slowness, stale/incomplete data, and bad data access are visible **before** months of silent pain. Rationale: [`REFERENCE.md`](REFERENCE.md).

**Scope `[suite-default]`:** **Minimum bars for logs**, metrics, traces; correlation / request IDs; DB and pool health; runtime data health and lineage **when the data can be wrong while the system is up**; liveness vs readiness; greenfield stack early; secrets/PII in telemetry (light). Not handler shape, APM dashboards, SLO/paging. Neighbors: [protocol](../protocol/RULES.md) · [architecture](../architecture/RULES.md) · [stack](../stack/RULES.md) · [data](../data/RULES.md) · [security](../security/RULES.md) · [release](../release/RULES.md) · [testing](../testing/RULES.md) · [code-style](../code-style/RULES.md).

## Complete `[suite-default]`

Paths findable with a **correlation/request id**. Golden signals exist or are extended (rate, errors, latency) plus any **key business** counter you introduced. No secrets; PII minimized. Added DB/IO is not invisible. Greenfield did not skip **an** observability framework early. Touched pipelines/derived data have relevant data-health signals.

## 1. Greenfield: instrument early `[suite-default]`

Wire a real stack on **any greenfield** as soon as the app handles real requests or a real DB. Capability early, not a brand — Datadog is a default `[project-example]`.

```
✓  logs + metrics (+ APM) in the first vertical slice that hits the DB
✗  “we’ll add Datadog after launch”
```

Brownfield: **ask** before large platform work; do not make visibility **worse**.

## 2. Logs `[suite-default]`

### Shape

```
[timestamp][context] message
```

**timestamp**: millisecond-precision UTC. **context**: subsystem name (`btc`, `rest`, `worker`) `[project-example]`. **blank line after each entry**. Stdout informational, stderr errors. No logging framework required. Platform agent or **structured / JSON** when the project expects it.

### Levels `[common]`

**error** — needs attention. **warn** — degraded but handled. **info** — sparse milestones. **debug** — **Off in production** by default. Prefer **metrics** for high-cardinality rates; logs for discrete events and failures.

### Secrets and PII

**Never** log secrets: passwords, tokens, API keys, raw session material, private keys. **Minimize PII**. Opaque ids. Field policy → [security](../security/RULES.md). Do not log entire request bodies by default on auth or payment paths.

## 3. Correlation / request IDs `[suite-default]`

**Required** for external-facing request handling: accept an incoming id or generate one at the edge; put it on **every log line**; **Propagate** to internal calls and child spans.

## 4. Metrics (minimum bar) `[suite-default]`

HTTP/RPC: **RED-style** golden signals. **Rate**. **Errors**. **Duration** (p95–p99). **Business** (a few counters that matter). **No metric spam.** No unique metric per user id.

## 5. Tracing `[suite-default]`

**Multi-service / multi-deployable**: distributed tracing; **propagate** on internal RPC and async publish/consume when feasible. **Single deployable**: full tracing optional; keep request ids and timing metrics.

## 6. Database and pool health `[suite-default]`

If the service uses a DB (or similar pool): **Errors** visible; **Slow queries** have a path; **Pool saturation** (wait time, in-use vs max); **Timeouts** distinct from app bugs when possible.

## 7. Data observability: when the data can be wrong while the system is up `[suite-default]`

App observability: is the software up? **Data observability**: is the data usable, complete enough, current enough?

### Apply it conditionally

Use the bar for scheduled/batch/streaming/ingest/transform/export/backfill; derived/replicated data; a critical feed whose late/partial failure is invisible to request metrics; a multi-stage flow needing cause/impact. Do **not** require a five-signal platform for every synchronous CRUD table, local tool, or static reference dataset.

### Five useful capabilities, not five universal boxes

Coverage model, not vendor law. Apply the capabilities that match the failure modes. **Freshness** — watermark or lag vs a stated cadence; `MAX(updated_at)` is not proof. **Volume** — in/out + rejects; evidence, not completeness. **Schema** — field/type/contract drift; checks observe, they do not define. **Content health / distribution** — targeted null, uniqueness, validity, range; not every column. **Lineage** — source → job → output → consumer; diagnostic context, not a health metric.

### Pipeline and monitor health still matter

Also expose job success/failure/duration; records read/written/rejected; a run id; check-execution failure, so a **silent monitor** is not healthy data.

### Keep signals actionable, safe, and affordable

For each monitored path, know why it is critical, what normal means, who owns it, what evidence is safe (no raw PII), and **What the check costs**.

### Layer boundaries

Field meaning → [data](../data/RULES.md). Tests → [testing](../testing/RULES.md). Expand/contract, backfill → [release](../release/RULES.md). **Runtime freshness**, volume, drift, execution, lineage → this file. Observed-data PII → [security](../security/RULES.md).

## 8. Health: liveness vs readiness `[common]`

**Liveness** — restart if this fails (deadlock / stuck runtime). **Readiness** — safe to receive traffic; **depends on critical dependencies**. If the service **cannot work without** the DB, readiness fails when that dep is down. `/health/live` — process up. `/health/ready` — DB ping `[project-example]`. Keep checks **cheap**.

## 9. What agents must do `[suite-default]`

Greenfield — setup stack early. New external endpoint — request id + logs; rate/error/latency. Money/side-effect — business counter; no secret logging. Heavy DB — slow/error visibility. Pipeline/derived — relevant freshness, volume, schema, content-health, lineage; only as justified. Backfill — run/progress/reject visibility. Brownfield, no APM — don’t expand without ask; don’t remove existing signals.

**Out of scope:** pages, SLO targets, on-call rotations. Emitting those signals **is** in scope.

## Never `[suite-default]`

```
✗ greenfield with no metrics/APM until “later” · secrets or full payment payloads in logs
✗ debug logging left on in production · high-cardinality metrics (user id as label)
✗ no request/correlation id across hops · readiness that ignores a hard dependency
✗ only host CPU/memory, zero app golden signals · log volume as a substitute for metrics
✗ silent pool exhaustion · pipeline healthy only because the job exited 0
✗ one recent row as proof every expected partition is fresh · row count as completeness
✗ anomaly detection as proof of correctness · monitor every dataset/column with no owner
✗ hand-maintained lineage that silently drifts · silent monitor failures
```

## Looks wrong, is intentional `[suite-default]`

Plain text logs plus a SaaS agent. Few business metrics, not dozens. No distributed tracing on a modular monolith if request ids + RED exist. Datadog from week one is not overkill. Cheap readiness that only checks a DB connection. No five-capability setup for ordinary synchronous CRUD.

## When to break `[suite-default]`

Minimal local prototype — still remove secret logging. Platform already injects metrics/traces or lineage — don’t duplicate. Hotfix: do not strip existing telemetry. Extreme cost — drop labels, not all visibility. One-off backfill — standing monitors may be wasteful; progress and rejects still need a visible path. Visible production truth beats a clean but silent system.

## Done `[suite-default]`

Greenfield stack early. Correlation id on external requests and logs. Levels sane. No secrets. RED-style signals. Trace context propagated when tracing is in use. DB/pool visibility considered. Pipeline/derived: relevant freshness, volume, schema, content-health, lineage. Checks actionable. Pipeline and **monitor execution failures** visible. Liveness vs readiness correct. Log shape respected.
