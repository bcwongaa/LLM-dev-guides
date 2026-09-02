# Observability — reference

Binding surface: [`RULES.md`](RULES.md). This file keeps the original observability prose and the relocated log-line section.

What a system must emit so failures, slowness, stale/incomplete data, and bad data access
are visible **before** months of silent pain — not a vendor tutorial or an on-call
handbook.

**The goal:** agents stop shipping “it works on my machine” services with no request IDs,
no latency signals, no idea the DB pool is dying, or a green pipeline that silently
produces unusable data. Observability is part of building, especially on greenfield.

## Scope of this guide

**In scope**

- Minimum bars for logs, metrics, traces
- Correlation / request IDs
- DB and pool health signals
- Runtime data health for pipelines and derived / replicated datasets
- Data lineage when data crosses meaningful processing stages
- Health/readiness checks
- Greenfield: stand up an observability stack early
- Secrets/PII in telemetry (light; deep policy → [`../security/RULES.md`](../security/RULES.md))

**Out of scope**

| Concern | Where it lives |
|---|---|
| Exact log line shape default | [`RULES.md`](RULES.md) (`[timestamp][context] message`) |
| Code structure of handlers | [`../code-style/RULES.md`](../code-style/RULES.md) |
| Which APM product license / full dashboard design | Project ops (this guide only requires *a* real stack) |
| SLO math, pages, escalation policies | Out of suite for now |
| Schema meaning, invariants, and query correctness | [`../data/RULES.md`](../data/RULES.md) / [`../testing/RULES.md`](../testing/RULES.md) |
| Expand/contract and backfill rollout order | [`../release/RULES.md`](../release/RULES.md) |
| Auth/PII product policy | [`../security/RULES.md`](../security/RULES.md) |

This guide is **what to observe and the minimum bar**, not how to click Datadog.

## What “complete” means

A service or feature change is observability-complete when:

1. Important paths can be found in logs with a **correlation/request id**.
2. Golden signals exist or are extended for the surface you touched (rate, errors, latency
   as applicable) plus any **key business** counter you introduced.
3. You did not log **secrets**; PII is minimized.
4. DB/IO work you added is not invisible (slow query / error visibility path exists).
5. Greenfield work did not skip standing up **an** observability framework early.
6. A pipeline or derived / replicated dataset you touched has signals for its relevant
   runtime data-health risks and enough lineage to find upstream cause and downstream
   impact.

Complete does **not** mean perfect dashboards, full distributed tracing on a single
process toy, profiling every dataset/column, or paging rules.

---

## 1. Greenfield: instrument early

**Highly recommend** wiring a real observability stack on **any greenfield** setup as soon
as the app handles real requests or a real database — e.g. **Datadog** or another
APM/metrics/log platform the author prefers.

Why: a “fine” p95 that is actually terrible often shows up only after traffic and data
grow. Discovering a slow query path **months later** is an avoidable failure mode.

```
✓  greenfield: logs + metrics (+ APM) in the first vertical slice that hits the DB
✓  local dev can use lighter sinks; staging/prod use the real backend
✗  “we’ll add Datadog after launch”
✗  only console.log with no aggregation, no latency histograms, no service name
```

Brownfield without a stack: do not boil the ocean mid-bugfix; still **ask** before
large platform work, and do not make visibility **worse**. Prefer adding the missing
signal for the path you touch.

Choice of vendor is **author/project** — this guide requires the capability early, not a brand
(Datadog is a strong default recommendation, not a hard ban on alternatives).

---

## 2. Logs

### Shape

Default line shape remains [`RULES.md`](RULES.md):

```text
[timestamp][context] message
```

- Use **structured / JSON** logs when the project or platform already expects them, or at
  high-volume service boundaries where fields must be queryable.
- Do not invent a second personal log format mid-repo. Match local convention.

### Levels

| Level | Use |
|---|---|
| **error** | Failures that need attention; include enough context to act |
| **warn** | Degraded or unexpected but handled |
| **info** | Important lifecycle and business milestones (sparse enough to be useful) |
| **debug** | **Off in production** by default; local/dev diagnosis |

```
✓  error with request id + operation name + safe identifiers
✓  info on “order completed” at low volume
✗  info log on every loop iteration in a hot path
✗  debug left on in prod flooding the sink
```

Prefer **metrics** for high-cardinality rates; logs for discrete events and failures.

### Secrets and PII

- **Never** log secrets: passwords, tokens, API keys, raw session material, private keys.
- **Minimize PII**: avoid full card numbers, full auth headers, unrestricted personal data
  dumps. Prefer opaque ids. Full field policy → [`../security/RULES.md`](../security/RULES.md).
- Do not log entire request bodies by default on authenticated or payment paths.

---

## 3. Correlation / request IDs

**Required** for external-facing request handling:

1. Accept an incoming correlation id if the client/gateway sends one (document the header
   the project uses), **or** generate one at the edge.
2. Put it on **every log line** for that request.
3. **Propagate** to internal calls (HTTP headers, gRPC metadata, message attributes) and
   to child spans when tracing is on.

```
✓  one id from edge → API → worker log lines
✗  three services, three unrelated log streams, no join key
✗  only log the id on errors (too late for the trail that led there)
```

Single-process local tools may skip if there is no multi-hop path — production services
should not.

---

## 4. Metrics (minimum bar)

For an HTTP/RPC service, aim for **RED-style** golden signals (and USE-style resource
signals where you own the process):

| Signal | Examples |
|---|---|
| **Rate** | requests / messages handled |
| **Errors** | 5xx, handler failures, consumer failures |
| **Duration** | latency histogram / p95–p99 where the platform allows |
| **Business** | a few counters that matter (charges attempted, pulls completed, jobs failed) |

```
✓  http.server.request duration + error rate by route family
✓  payments.succeeded / payments.failed counters
✗  a unique metric name per user id (cardinality bomb)
✗  zero app metrics, only host CPU from the cloud console
```

**No metric spam.** A handful of stable names beats hundreds of unused series.

---

## 5. Tracing

- **Multi-service / multi-deployable** systems: use distributed tracing; **propagate**
  context on internal RPC and async publish/consume when feasible.
- **Single deployable**: full distributed tracing is optional; still keep request ids and
  timing metrics. Local spans can help heavy handlers but are not mandatory theater.

```
✓  trace edge → api → billing gRPC → db span
✗  require Jaeger on a one-box CLI
✗  tracing without log correlation (two disconnected worlds)
```

---

## 6. Database and pool health

If the service uses a DB (or similar pool), observability must include:

| Concern | Why |
|---|---|
| **Errors** | Connection/query failures visible in metrics or logs |
| **Slow queries** | Path to see outliers (APM DB views, slow query log, statement timing) |
| **Pool saturation** | Wait time, pool in-use vs max — exhaustion looks like “random latency” |
| **Timeouts** | Distinct from app bugs when possible |

```
✓  APM or metrics show p95 query time rising before users page you months later
✓  alertable signal or dashboard for pool wait (alerting rules themselves are out of this guide)
✗  “DB is fine” with no query latency visibility
✗  unbounded query in a hot path with no timing anywhere
```

This guide does not replace [`../data/RULES.md`](../data/RULES.md) query design or [`../testing/RULES.md`](../testing/RULES.md) tests. It makes production truth visible.

---

## 7. Data observability: when the data can be wrong while the system is up

Application observability asks whether the software is available and behaving. **Data
observability** asks whether the data it produces or depends on is usable, complete enough,
and current enough for its consumers.

A pipeline can finish successfully, a query can return in 20 ms, and every health check can
be green while half of yesterday's records are missing. [`../data/RULES.md`](../data/RULES.md) constraints prevent invalid
states the store can recognize; [`../testing/RULES.md`](../testing/RULES.md) tests prove known behavior before ship. This guide makes silent
runtime degradation visible after real data starts moving.

### Apply it conditionally

Use the data-observability bar when a change introduces or materially changes:

- scheduled, batch, streaming, ingestion, transformation, export, or backfill work;
- derived or replicated data such as read models, materialized views, search indexes,
  warehouse/lake assets, analytics datasets, or ML inputs;
- a critical external feed whose partial or late failure could remain invisible to normal
  request metrics;
- a multi-stage flow where identifying upstream cause or downstream impact matters.

Do **not** require a five-signal platform for every synchronous CRUD table, local tool, or
static reference dataset. For those, data invariants, tests, and the ordinary service/DB
signals are normally enough.

```
✓  nightly settlement export: freshness + records written + reconciliation + source-to-export lineage
✓  product search index: source lag + indexed count + failed documents + source/index dependency
✓  plain transactional table: constraints + tests + DB health; no ceremonial lineage platform
✗  every table and column monitored because "data observability is mandatory"
```

## Data observability: five useful capabilities, not five universal boxes

Freshness, volume, schema, content distribution, and lineage are a useful coverage model.
Apply the capabilities that match the failure modes; do not treat their names as vendor or
architecture law.

| Capability | Question | Minimum useful signal |
|---|---|---|
| **Freshness** | Did usable data arrive when consumers expect it? | Last successful completion, source/event watermark, and/or source-to-consumer lag against a stated cadence |
| **Volume** | Did roughly the expected amount arrive? | Records/events/bytes read and written by meaningful run, window, or partition; include rejects/duplicates when relevant |
| **Schema** | Did runtime structure change compatibly and intentionally? | Added/removed/renamed fields, type/nullability change, or contract/version mismatch visible at the boundary |
| **Content health / distribution** | Do critical fields still look valid and plausible? | Targeted null, uniqueness, validity, range, cardinality, category-share, or quantile signals |
| **Lineage** | Where did this data come from and what depends on it? | Source/producer → transformation/job → output → critical consumer at the smallest useful granularity |

**Freshness needs a business expectation.** `MAX(updated_at)` is not automatically proof
that a load is fresh: one new row can hide a missing partition, late events can be normal,
and a backfill can make old business data look newly updated. Prefer the source/event
watermark or completed partition that consumers actually rely on.

**Volume is evidence, not completeness.** Stable row count can hide one missing record and
one duplicate. Pair volume with reconciliation, rejected-record counts, uniqueness, or a
source total where the domain requires it.

**Schema checks observe; they do not define.** [`../data/RULES.md`](../data/RULES.md) defines stored field meaning and safe
schema shape, `../contracts/RULES.md` defines published contracts, and [`../release/RULES.md`](../release/RULES.md) owns compatible rollout. This guide detects
unexpected runtime drift and confirms that intentional changes arrived without silently
breaking consumers. Do not duplicate those schema rules inside the monitor.

**Content health is broader than a statistical distribution.** Known business invariants
use explicit checks. Historical baselines can surface unknown shifts, but "statistically
normal" does not prove data is correct. Monitor critical fields, not every column by
reflex.

**Lineage is diagnostic context, not a health metric.** Prefer metadata the platform,
orchestrator, query engine, or data tool already emits. Table/dataset-level lineage is a
good default; require field-level lineage only when it materially changes root-cause or
impact analysis. A hand-maintained diagram with no update path is not trustworthy lineage.

## Data observability: pipeline and monitor health still matter

The five capabilities do not replace ordinary execution signals. A meaningful data path
also exposes, as applicable:

- run/job success, failure, duration, retry count, and queue/schedule delay;
- records read, written, rejected, and deduplicated;
- a run/correlation id joining logs to input and output datasets;
- the deployed code/config version when it helps identify a regression;
- monitor/check execution failure, so a silent monitor is not mistaken for healthy data.

Use fixed rules for known invariants and historical/anomaly baselines for variable patterns.
Do not make anomaly detection the only way to catch a fact the business already knows.

## Data observability: keep signals actionable, safe, and affordable

For each monitored dataset or path, know:

1. **Why it is critical** and which consumer is harmed when it degrades.
2. **What normal means**, including expected cadence, partitions, lateness, and planned
   pauses or backfills.
3. **Who owns the producing path** or where the incident can be routed. Exact paging policy
   remains project ops.
4. **What evidence is safe to collect.** Prefer metadata and aggregate statistics; do not
   copy raw PII into telemetry to explain an anomaly.
5. **What the check costs.** Use warehouse metadata, targeted partitions, sampling, or
   incremental checks before repeatedly scanning an entire large dataset.

```
✓  known invariant uses a fixed assertion; changing daily volume uses a seasonal baseline
✓  backfill is labelled/suppressed deliberately while progress and rejects remain visible
✓  aggregate null rate emitted without shipping raw customer values
✗  alert with no dataset owner, affected consumer, run id, or next diagnostic step
✗  full-table profile every minute on an expensive warehouse
✗  monitoring query exports sensitive rows into a general-purpose log sink
```

## Data observability: layer boundaries

| Concern | Owner |
|---|---|
| Field meaning, stored invariants, source of truth | [`../data/RULES.md`](../data/RULES.md) |
| Input/output event or API contract | `../contracts/RULES.md` |
| Deterministic assertions and regression tests before ship | [`../testing/RULES.md`](../testing/RULES.md) |
| Expand/contract, backfill ordering, rollback/forward-fix | [`../release/RULES.md`](../release/RULES.md) |
| Runtime freshness, volume, drift, execution signals, and lineage | this guide |
| PII, retention, and access policy for observed data | [`../security/RULES.md`](../security/RULES.md) |

---

## 8. Health: liveness vs readiness

| Check | Meaning |
|---|---|
| **Liveness** | Process should be restarted if this fails (deadlock / stuck runtime) |
| **Readiness** | Safe to receive traffic; **depends on critical dependencies** |

If the service **cannot work without** the DB (or another critical dep), readiness should
fail when that dep is unavailable — not return 200 while every request 500s.

```
✓  /health/live  — process up
✓  /health/ready — DB ping / pool can checkout (when DB is required)
✗  ready always 200 while Postgres is down for a DB-backed API
✗  ready that runs an expensive full-table scan
```

Match platform conventions (K8s probes, load balancer checks). Keep checks **cheap**.

---

## 9. What agents must do

| Situation | Behavior |
|---|---|
| Greenfield service | Propose/setup observability stack early (Datadog or chosen framework) |
| New external endpoint | Request id + logs; metrics for rate/error/latency as the stack allows |
| New money/side-effect path | Business counter or clear log milestone; no secret logging |
| New heavy query / DB use | Ensure slow/error visibility path exists |
| New/changed pipeline or derived dataset | Identify relevant freshness, volume, schema, content-health, and lineage signals; add only those justified by its failure modes |
| Backfill or bulk transformation | Run/progress/reject visibility; distinguish planned movement from an incident |
| Brownfield, no APM | Don’t expand scope to full platform without ask; don’t remove existing signals |

**Out of scope for this guide:** defining pages, SLO targets, and on-call rotations. Emitting the
signals those systems need **is** in scope.

---

## 10. Anti-patterns

```
✗ greenfield with no metrics/APM until “later”
✗ secrets or full payment payloads in logs
✗ debug logging left on in production
✗ high-cardinality metrics (user id as label)
✗ no request/correlation id across hops
✗ readiness that ignores a hard dependency
✗ only host CPU/memory, zero app golden signals
✗ log volume as a substitute for metrics on hot paths
✗ silent pool exhaustion (“requests just hang”)
✗ pipeline marked healthy only because the job exited 0
✗ one recent row used as proof that every expected partition is fresh
✗ row count treated as proof that the dataset is complete and duplicate-free
✗ anomaly detection treated as proof of business correctness
✗ monitor every dataset/column with no criticality, owner, cost, or response path
✗ hand-maintained lineage that silently drifts from the running system
✗ monitoring failures invisible, so “no alerts” is mistaken for healthy data
```

---

## 11. Intentional patterns that may look like mistakes

**Plain text logs plus a SaaS agent.** Valid when the agent parses/ships them; structure
optional until query needs force it.

**Few business metrics, not dozens.** Intentional — cover what hurts.

**No distributed tracing on a modular monolith.** OK if request ids + RED metrics exist.

**Datadog (or similar) from week one on a small service.** Not overkill — prevents late
discovery of bad p95 DB paths.

**Cheap readiness that only checks “can get a DB connection.”** Better than a deep
synthetic transaction on every probe.

**No five-capability data-observability setup for ordinary synchronous CRUD.** Correct when
constraints, tests, and normal service/DB signals cover its realistic failure modes.

**Table-level rather than field-level lineage.** Correct until field detail would materially
improve diagnosis or impact analysis.

**A few explicit data assertions beside anomaly monitoring.** Known invariants should fail
clearly; baselines are for patterns whose exact threshold is not already known.

---

## When to break these rules

- Author chooses a minimal local prototype with no deploy — still remove secret logging.
- Platform already injects metrics/traces — don’t duplicate; integrate.
- Platform already captures job/dataset lineage or quality metrics — enrich and reuse it
  instead of building a parallel catalog.
- Emergency hotfix: do not strip existing telemetry; add minimal logs if the path is blind.
- Extreme cardinality or cost constraints — drop labels, not all visibility.
- One-off backfill — full standing monitors may be wasteful; progress, rejects, reconciliation,
  and restartability still need a visible path.

Visible production truth beats a clean but silent system.

---

## Done checklist

- [ ] Greenfield: observability stack planned or present early (Datadog or equivalent)
- [ ] External requests carry/propagate a correlation id; logs include it
- [ ] Log levels sane; debug not flooding prod
- [ ] No secrets; PII minimized
- [ ] RED-style signals (or extension of existing) for surfaces you ship
- [ ] Key business counters for money/side-effect paths when relevant
- [ ] Multi-service: trace context propagated when tracing is in use
- [ ] DB/pool errors and slow-path visibility considered
- [ ] Pipeline/derived data touched: relevant freshness, volume, schema, and content-health signals exist
- [ ] Pipeline/derived data touched: lineage identifies useful upstream cause and downstream impact
- [ ] Data checks are actionable, cost-aware, and do not leak raw sensitive data
- [ ] Pipeline and monitor execution failures are themselves visible
- [ ] Liveness vs readiness correct for critical deps
- [ ] obs log shape (or project structured equivalent) respected

## Relationship to other layers

| Topic | Layer |
|---|---|
| Default log line format | [`RULES.md`](RULES.md) |
| Protocol / scope | [`../protocol/RULES.md`](../protocol/RULES.md) |
| Multi-service layout | [`../architecture/RULES.md`](../architecture/RULES.md) |
| Stack/vendors | [`../stack/RULES.md`](../stack/RULES.md) / author |
| Query design | [`../data/RULES.md`](../data/RULES.md) |
| Wire errors clients see | `../contracts/RULES.md` |
| Data contracts clients/producers exchange | `../contracts/RULES.md` |
| Tests and deterministic pre-ship assertions | [`../testing/RULES.md`](../testing/RULES.md) |
| PII/secrets policy depth | [`../security/RULES.md`](../security/RULES.md) |
| Backfill and rollout choreography | [`../release/RULES.md`](../release/RULES.md) |

## 21. Log format

Original v1 wording relocated from coding-style §21. Binding line shape: [`RULES.md`](RULES.md).

Consistent structure across every log line (default shape for this suite):

```
[timestamp][context] message
```

- **timestamp**: millisecond-precision UTC
- **context**: subsystem name for the producing task (`btc`, `rest`, `worker`)
- **blank line after each entry** for terminal readability

Stdout for informational, stderr for errors. No logging framework **required by code-style** —
projects may use a platform agent or structured logs when this guide or the project demands it.

This section is the default **line shape** only. Observability policy (levels, request ids, metrics, traces, DB health, runtime data health/lineage, greenfield APM) is [`RULES.md`](RULES.md).
