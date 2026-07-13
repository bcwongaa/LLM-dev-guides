# L5 — API and Contracts

How data crosses process and trust boundaries: HTTP, events, DTOs, errors clients see,
and what may change without breaking consumers.

**The goal:** agents stop inventing one-off wire shapes, silent breaking changes, and
“just post the entity to the client.” Contracts stay boring, explicit, and safe under
retries — especially where money or side effects are involved.

## Scope of this guide

**In scope**

- Public/external APIs (HTTP, WebSocket) and their wire contracts
- Internal service-to-service transport choice and contracts
- Event/message payloads between deployables
- DTO vs domain/storage models
- Validation at the wire
- Versioning and breaking changes
- Idempotency for dangerous mutations
- Pagination, IDs on the wire, PATCH semantics
- Webhooks and other untrusted inbound callbacks
- Light authn/authz placement at the boundary

**Out of scope**

| Concern | Where it lives |
|---|---|
| Handler/service code shape | **L1** |
| Logical engines vs deployables | **L2** |
| Framework choice (Nest, etc.) | **L3** |
| Tables, migrations, DB invariants | **L4** |
| Deep auth product rules, PII policy | **L8** (when written) |
| Deploy flags / expand-contract of APIs in prod | **L9** (when written) |
| How to test contracts | **L7** |

In-process module calls (same deployable) are **L2**, not remote contracts. Do not invent
HTTP between modules in one process “for purity.”

## What “complete” means

A contract change is complete when:

1. Transport fits **external vs internal** rules (§1).
2. Wire types are explicit and converted at the boundary (not raw DB entities by accident).
3. Inbound data is validated before domain logic trusts it.
4. Breaking changes were avoided, versioned, or **approved** (L0 ask).
5. Money/side-effect mutations are safe under retry (idempotency or natural idempotence).
6. Errors and success shapes match the **project’s** established style (framework default
   is fine — do not invent a second envelope).
7. Tests cover the contract behavior you changed (L7).

---

## 1. Transport: external vs internal

### External (browsers, mobile, third parties, public clients)

Stick with **HTTP** and **WebSocket** unless there is a hard, approved reason not to.

- **HTTP + JSON**, resource-oriented REST, is the default request/response style (§2).
- **WebSocket** when you need bidirectional or server-push streams to clients.
- Do **not** expose gRPC (or exotic protocols) to public/browser clients by default.
- GraphQL or other external styles only when the product already uses them or the author
  chooses — not “because modern.”

```
✓  public REST JSON API + WebSocket for live feed
✗  public gRPC as the default external API without ask
✗  invent a custom binary client protocol for a normal web app
```

### Internal (service-to-service, between deployables)

There are **many** valid options: in-process calls (L2), message queues/buses, gRPC, and
others. **HTTP JSON between internal services is usually a poor default** — high overhead,
weak contracts, easy to misuse as a fake module boundary.

Preference when a **remote** internal call is justified (L2 already approved a deployable
split):

```
prefer:  in-process public module API (same deployable)     → L2
then:    async messages / events when fan-out or decoupling fits
then:    gRPC (or similar typed RPC) for sync internal calls
avoid:   internal HTTP/JSON as the first choice
```

**gRPC > HTTP** for synchronous internal RPC when you need request/response across
processes. Still: do not split deployables just to use gRPC.

```
✓  worker ↔ api over gRPC or a queue with an explicit payload
✓  two logical engines in one process: function calls, not HTTP localhost
✗  every microservice talks HTTP REST to every other “for simplicity”
✗  HTTP localhost between modules in the same Node process
```

Brownfield that already uses internal HTTP: **follow local convention** for scoped work;
do not rewrite the mesh mid-feature for taste. Propose better transport when adding a
**new** internal path.

New internal transport or public protocol outside HTTP/WebSocket: **ask** (L0/L3).

---

## 2. Default external style: boring REST/JSON

For **new external** HTTP APIs, prefer **resource-oriented REST + JSON** unless the
product already standardized something else or the author chooses otherwise.

```
✓  GET /orders/{id}  → 200 + order JSON
✓  POST /orders      → 201 + created order (or 200 if project convention)
✗  POST /api/doCreateOrder with ad hoc bag and no resource model
✗  GraphQL on greenfield external API without ask
```

Brownfield: **follow the existing API style**. Do not REST-wash an RPC codebase mid-feature.

---

## 3. DTOs are not domain or DB models

**Separate wire types from storage/domain types.** Convert explicitly at the boundary
(align L1 entity conversion and L4 persistent vs in-memory shape).

```
✓  http OrderResponse ← map(domain Order)
✓  body CreateOrderRequest → validated → domain command
✗  return the ORM entity / Prisma row as the HTTP body by default
✗  accept a partial DB row shape from the client and save it blindly
```

Reuse is allowed only when the project already does it **and** the shape is intentionally
public — not because mapping felt like boilerplate.

---

## 4. Validate at the boundary

All **inbound** data from outside the process is untrusted: public HTTP/WebSocket, other
services (gRPC or otherwise), queues, webhooks, files, admin imports.

- Validate **before** domain logic relies on the value (L4 trust boundary).
- If the **framework has a conventional place** for validation (pipes, decorators, binders,
  middleware), **use it** — do not invent a parallel validation framework.
- Domain may still enforce business rules; wire validation catches shape/type/range early.

```
✓  framework DTO validation on the controller → domain service
✓  webhook: verify signature → parse → validate → handle
✗  assume JSON “from our other service” is well-typed forever
✗  skip validation because TypeScript compiled
```

Whatever carries data **from outside the process**, treat it as untrusted at entry —
including “our” internal services.

---

## 5. Errors at the wire

**Do not invent a house-wide error DTO** if the framework or project already has a
convention. Prefer:

- stable **HTTP status** that matches the outcome;
- a **machine-readable** body consistent with the project;
- domain/app errors **mapped** at the boundary (do not leak stack traces or internal
  table names to public clients).

```
✓  404 when the resource is missing for this principal
✓  409 when a business conflict is expected
✓  400/422 for invalid input (follow project norm)
✗  200 OK with { success: false } as the only pattern without project precedent
✗  raw SQL or ORM errors returned to the client
```

If the project has no convention yet, pick the framework default and stay consistent —
document once in the service, do not create a second error style next PR.

---

## 6. Success bodies

**Return the resource or result JSON directly** by default.

```
✓  { "id": "…", "status": "pending", … }
✗  mandatory { "data": { … }, "meta": { … }, "error": null } unless the project already uses it
```

Lists may include pagination fields alongside items **or** a small documented envelope if
the service already standardized one — consistency within the service beats a new global
wrapper.

---

## 7. Versioning and breaking changes

**Prefer additive, non-breaking change.** Version when you must break. **Ask** before
breaking a published contract (L0).

| Usually non-breaking | Breaking (version or ask) |
|---|---|
| Add optional field | Remove or rename field |
| Add endpoint | Change field type or meaning |
| Relax a constraint carefully | Make validation stricter in a way that rejects old clients |
| | Change auth requirements |
| | Reuse a field for a new meaning |

Consumers of **events** and flexible clients should **tolerate unknown additive fields**.
Producers must not rename or repurpose fields silently.

```
✓  add optional "notes" field; old clients ignore it
✓  /v2/orders when response meaning of "status" changes
✗  rename "amount" → "amountCents" in place with no version and no migration period
✗  “nobody uses this yet” breaking change without checking
```

URL version (`/v1/...`) or explicit negotiated version are both fine — **match the
project**. Do not add `/v1` theater to an unversioned mature API without a reason.

---

## 8. Idempotency and retries

Clients retry. Networks duplicate. **Mutations with money or hard side effects** must be
safe under replay.

```
✓  Idempotency-Key (or project equivalent) for pay/pull/transfer POSTs
✓  natural idempotency: PUT that sets absolute state; “create if absent” with stable key
✗  POST /charges that creates a new charge on every retry with no key
✗  “user won’t double-click” as the safety design
```

Not every POST needs a key (e.g. pure search). If double-submit would corrupt money,
inventory, or external side effects, design for idempotency **before** shipping.

---

## 9. Pagination

**No single house mandate** for cursor vs offset. Within a service:

- pick **one** primary style for list endpoints and document it;
- **always bound** page size (max limit);
- stable sort order when paging.

```
✓  ?limit=50&cursor=…  or  ?page=2&pageSize=20 — consistent in this API
✗  unbounded GET /orders that returns the whole table
✗  offset pagination with no max limit
```

---

## 10. Identifiers on the wire

Align **L4**: do **not** expose raw internal DB keys as the public contract **by default**.

```
✓  public/stable id when clients store references or IDs appear in URLs shared externally
✓  internal keys stay internal when enumeration or leakage is a concern
✗  auto-increment /orders/1, /orders/2 as the long-term public API without thought
```

Brownfield that already exposes internal IDs: **continue local convention** unless
changing IDs is an explicit, approved project.

---

## 11. Partial updates (PATCH)

Prefer **explicit partial update** where clients send only fields to change.

- **Omitted** field → leave unchanged  
- **Null** (when allowed) → clear / set null per documented meaning (L1/L4 null vs absent)

```
✓  PATCH { "status": "cancelled" } does not wipe other fields
✗  treating missing JSON keys as null and nulling half the row
✗  undocumented “send the full object or else”
```

If the project is PUT-only full replace, follow that — but document it and validate
required fields on every write.

---

## 12. Events and message payloads

When deployables communicate asynchronously:

- **Named** event/type + explicit payload version or additive-compatible schema;
- consumers **must tolerate new optional fields**;
- do not break by renaming/removing fields in place;
- payload is not “whatever the producer’s DB row looks like today.”

```
✓  order.completed.v1 { orderId, completedAt, … } — additive fields later
✗  reuse the same event name with a different shape and no version
✗  publish ORM entities to the bus as the contract
```

If there is no event bus yet, do not introduce one for style points (L2/L3 ask).

---

## 13. Webhooks and third-party callbacks

Inbound webhooks are **hostile until proven otherwise**:

1. **Verify** signature / authenticity per vendor rules.  
2. **Validate** payload shape after verification.  
3. Handle **idempotently** (vendors retry).  
4. Retain **raw payload** when needed for audit or reprocessing (L4 JSON-for-third-party).  
5. Map to domain commands; do not spread vendor JSON through the core.

```
✓  verify Stripe signature → idempotent ledger apply → 200
✗  trust body because the path is “obscure”
✗  non-idempotent handler that double-credits on retry
```

---

## 14. Authn / authz at the boundary (light)

- Protected routes require an **authenticated principal** (session, bearer, etc. —
  **project convention**).
- **Authorization** is application logic (roles/permissions/ownership) — not “the client
  sent `role: admin`.”
- Do not put secrets in query strings or logs (also L8 when written).
- Deep product auth/PII rules wait for **L8**; L5 only places the boundary.

```
✓  middleware loads principal → handler checks canCancel(order, principal)
✗  trust body.isAdmin
✗  invent a new auth scheme mid-feature without ask
```

---

## 15. Service-to-service contracts

- Prefer **in-process** module APIs inside one deployable (**L2**) before any network.
- For **remote** internal calls, pick transport per §1 (prefer messages or gRPC over
  internal HTTP).
- Whatever the transport: explicit contracts, validation at entry, versioning discipline —
  same honesty as public APIs.
- **Never** use “reach into the other service’s database” as the integration API.
- Any data entering a process from outside is untrusted regardless of transport.

---

## 16. Anti-patterns

```
✗ return ORM entities as public JSON by default
✗ silent breaking field renames
✗ unbounded list endpoints
✗ charge/post side effects without idempotency
✗ invent a global response envelope over framework defaults
✗ invent a parallel validation stack beside the framework
✗ trust webhooks or S2S bodies without verification/validation
✗ fake REST / HTTP localhost over in-process calls
✗ internal HTTP JSON mesh as the default sync RPC
✗ public gRPC (or exotic protocols) for normal external clients without ask
✗ leak internal errors and stack traces to clients
✗ change auth requirements without treating it as breaking
```

---

## 17. Intentional patterns that may look like mistakes

**Framework-default errors instead of RFC7807.** Intentional when the project is
consistent; do not “upgrade” mid-stream for taste.

**Unversioned API that only evolves additively.** Valid until a real break needs `/v2`.

**No Idempotency-Key on a read-only POST search.** Fine if it has no side effects.

**Exposing UUIDs that are also DB keys.** OK when the project chose UUID primary keys as
public ids deliberately.

**Thinner internal worker payload than public HTTP.** OK if still versioned/validated at
entry.

**gRPC (or queues) between internal services while the public API is REST.** Correct
split: external stays HTTP/WebSocket; internal uses a better tool than HTTP JSON.

---

## When to break these rules

- Author or existing public contract dictates another style.
- A vendor webhook forces their shape — adapt at the edge, keep domain clean.
- Emergency compatibility shim with a sunset date — document and ask if it breaks clients.
- Local-only prototype — still do not ship unvalidated money paths.

Working clients and safe retries beat diagram purity.

---

## Done checklist

- [ ] External clients: HTTP and/or WebSocket unless an approved exception
- [ ] Internal remote: not defaulting to HTTP JSON; prefer in-process, messages, or gRPC
- [ ] Wire DTO ≠ accidental DB entity; mapping explicit
- [ ] Inbound validated at boundary (framework-conventional mechanism)
- [ ] No silent breaking change; version or ask if breaking
- [ ] Side-effect/money mutations idempotent under retry
- [ ] List endpoints bounded; pagination style consistent in this service
- [ ] Public IDs thought through (L4)
- [ ] PATCH omitted ≠ null (if partial updates exist)
- [ ] Webhooks verified + idempotent
- [ ] Protected routes have a principal; authz not client-claimed
- [ ] Tests cover contract behavior changed (L7)
- [ ] Errors/success match project convention — no second house style

## Relationship to other layers

| Topic | Layer |
|---|---|
| Ask before breaking / greenfield | **L0** |
| Handler structure, conversion | **L1** |
| In-process vs remote | **L2** |
| Framework | **L3** |
| Storage shape, null, JSON retention | **L4** |
| Testing contracts | **L7** |
| Auth/PII product policy | **L8** (when written) |
| Rollout of breaking APIs | **L9** (when written) |
