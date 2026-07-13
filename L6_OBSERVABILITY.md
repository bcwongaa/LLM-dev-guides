# L6 — Observability

What a system must emit so failures, slowness, and bad data access are visible **before**
months of silent pain — not a vendor tutorial or an on-call handbook.

**The goal:** agents stop shipping “it works on my machine” services with no request IDs,
no latency signals, and no idea the DB pool is dying. Observability is part of building,
especially on greenfield.

## Scope of this guide

**In scope**

- Minimum bars for logs, metrics, traces
- Correlation / request IDs
- DB and pool health signals
- Health/readiness checks
- Greenfield: stand up an observability stack early
- Secrets/PII in telemetry (light; deep policy → L8)

**Out of scope**

| Concern | Where it lives |
|---|---|
| Exact log line shape default | **L1** §21 (`[timestamp][context] message`) |
| Code structure of handlers | **L1** |
| Which APM product license / full dashboard design | Project ops (L6 only requires *a* real stack) |
| SLO math, pages, escalation policies | Out of suite for now |
| Schema/query correctness | **L4** / **L7** |
| Auth/PII product policy | **L8** (when written) |

L6 is **what to observe and the minimum bar**, not how to click Datadog.

## What “complete” means

A service or feature change is observability-complete when:

1. Important paths can be found in logs with a **correlation/request id**.
2. Golden signals exist or are extended for the surface you touched (rate, errors, latency
   as applicable) plus any **key business** counter you introduced.
3. You did not log **secrets**; PII is minimized.
4. DB/IO work you added is not invisible (slow query / error visibility path exists).
5. Greenfield work did not skip standing up **an** observability framework early.

Complete does **not** mean perfect dashboards, full distributed tracing on a single
process toy, or paging rules.

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

Choice of vendor is **author/project** — L6 requires the capability early, not a brand
(Datadog is a strong default recommendation, not a hard ban on alternatives).

---

## 2. Logs

### Shape

Default line shape remains **L1** §21:

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
  dumps. Prefer opaque ids. Full field policy → **L8** when written.
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
✓  alertable signal or dashboard for pool wait (alerting rules themselves are out of L6)
✗  “DB is fine” with no query latency visibility
✗  unbounded query in a hot path with no timing anywhere
```

L6 does not replace **L4** query design or **L7** tests. It makes production truth visible.

---

## 7. Health: liveness vs readiness

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

## 8. What agents must do

| Situation | Behavior |
|---|---|
| Greenfield service | Propose/setup observability stack early (Datadog or chosen framework) |
| New external endpoint | Request id + logs; metrics for rate/error/latency as the stack allows |
| New money/side-effect path | Business counter or clear log milestone; no secret logging |
| New heavy query / DB use | Ensure slow/error visibility path exists |
| Brownfield, no APM | Don’t expand scope to full platform without ask; don’t remove existing signals |

**Out of scope for L6:** defining pages, SLO targets, and on-call rotations. Emitting the
signals those systems need **is** in scope.

---

## 9. Anti-patterns

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
```

---

## 10. Intentional patterns that may look like mistakes

**Plain L1 text logs plus a SaaS agent.** Valid when the agent parses/ships them; structure
optional until query needs force it.

**Few business metrics, not dozens.** Intentional — cover what hurts.

**No distributed tracing on a modular monolith.** OK if request ids + RED metrics exist.

**Datadog (or similar) from week one on a small service.** Not overkill — prevents late
discovery of bad p95 DB paths.

**Cheap readiness that only checks “can get a DB connection.”** Better than a deep
synthetic transaction on every probe.

---

## When to break these rules

- Author chooses a minimal local prototype with no deploy — still remove secret logging.
- Platform already injects metrics/traces — don’t duplicate; integrate.
- Emergency hotfix: do not strip existing telemetry; add minimal logs if the path is blind.
- Extreme cardinality or cost constraints — drop labels, not all visibility.

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
- [ ] Liveness vs readiness correct for critical deps
- [ ] L1 log shape (or project structured equivalent) respected

## Relationship to other layers

| Topic | Layer |
|---|---|
| Default log line format | **L1** §21 |
| Protocol / scope | **L0** |
| Multi-service layout | **L2** |
| Stack/vendors | **L3** / author |
| Query design | **L4** |
| Wire errors clients see | **L5** |
| Tests | **L7** |
| PII/secrets policy depth | **L8** (when written) |
