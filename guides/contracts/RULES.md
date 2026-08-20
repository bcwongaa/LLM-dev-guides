# Contracts

Binding API and contract law. Rationale and examples: [`REFERENCE.md`](REFERENCE.md).

**Scope `[suite-default]`:** public/external HTTP and WebSocket; internal S2S transport and contracts; event payloads; DTO vs domain/storage; wire validation; versioning; idempotency; pagination; IDs; PATCH; webhooks; light authn/authz at the boundary. In-process calls are architecture, not remote contracts — do not invent HTTP between modules in one process.

Not: `../code-style/RULES.md` (shape) · `../architecture/RULES.md` (in-process) · `../stack/RULES.md` (framework) · `../data/RULES.md` (tables) · `../testing/RULES.md` · `../security/RULES.md` (auth/PII) · `../release/RULES.md` (rollout) · `../protocol/RULES.md` (ask).

## Complete `[suite-default]`

Transport fits **external vs internal**; wire types converted at the boundary; inbound validated before domain trusts it; breaks avoided, versioned, or asked; money/side-effect mutations safe under retry; errors/success match **project** style (no second envelope); tests cover the changed contract (`../testing/RULES.md`).

## 1. Transport: external vs internal `[suite-default]`

### External

HTTP and WebSocket only, unless a hard approved reason. Default: **HTTP + JSON** REST (§2). WebSocket for bidirectional or server-push. No public/browser gRPC or exotic protocols by default. GraphQL or other styles only if the product already uses them or the author chooses.

### Internal

In-process, queues/buses, or gRPC are valid. **HTTP JSON between internal services is usually a poor default.** Prefer in-process public module API → async messages when fan-out fits → gRPC for sync calls. Avoid internal HTTP/JSON first. gRPC > HTTP for sync internal RPC. Do not split deployables just to use gRPC. Brownfield internal HTTP: follow local convention. New transport outside HTTP/WebSocket: **ask**.

## 2. Default external style: boring REST/JSON `[suite-default]`

New external HTTP: **resource-oriented REST + JSON** unless the product already standardized something else or the author chooses. Brownfield: **follow the existing API style**. Do not REST-wash an RPC codebase mid-feature. No GraphQL on a greenfield external API without ask.

## 3. DTOs are not domain or DB models `[suite-default]`

**Separate wire types from storage/domain types.** Convert at the boundary. Reuse only when the project already does it **and** the shape is intentionally public. Do not return the ORM / Prisma row as the HTTP body by default.

## 4. Validate at the boundary `[common]`

All **inbound** data from outside the process is untrusted — including “our” internal services. Validate **before** domain relies on it. Use the framework’s conventional place; do not invent a parallel validation framework. TypeScript compiling is not validation.

## 5. Errors at the wire `[suite-default]`

**Do not invent a house-wide error DTO** if the framework or project already has one. Stable **HTTP status**; **machine-readable** project-consistent body; map domain errors at the boundary. No stack traces, internal table names, or raw SQL/ORM errors to public clients. No `200` + `{ success: false }` as the only pattern without precedent.

## 6. Success bodies `[suite-default]`

**Return the resource or result JSON directly** by default. No mandatory `{ data, meta, error: null }` unless the project already uses it. Lists may include pagination fields or a small documented envelope the service already standardized.

## 7. Versioning and breaking changes `[common]`

**Prefer additive, non-breaking change.** Version when you must break. **Ask** before breaking a published contract. Consumers **tolerate unknown additive fields**. Producers must not rename or repurpose fields silently. Non-breaking: add optional field/endpoint; carefully relax a constraint. Breaking: remove/rename/retype; stricter validation that rejects old clients; change auth; reuse a field. `/v1` or negotiated version — **match the project**. No `/v1` theater on an unversioned mature API.

## 8. Idempotency and retries `[common]`

Clients retry. **Mutations with money or hard side effects** must be safe under replay. Use **Idempotency-Key** (or project equivalent) for pay/pull/transfer POSTs; natural idempotency (PUT absolute state, create-if-absent) is fine. Not every POST needs a key. If double-submit would corrupt money, inventory, or external side effects, design idempotency **before** shipping.

## 9. Pagination `[suite-default]`

**No single house mandate** for cursor vs offset. One primary style per service; **always bound** page size; stable sort when paging. No unbounded `GET /orders`.

## 10. Identifiers on the wire `[suite-default]`

Do **not** expose raw internal DB keys as the public contract **by default**. Brownfield that already exposes internal IDs: **continue local convention** unless changing IDs is an approved project.

## 11. Partial updates (PATCH) `[suite-default]`

**Omitted** → leave unchanged. **Null** (when allowed) → clear / set null per documented meaning. Do not treat missing JSON keys as null. PUT-only full replace is fine if documented and required fields are validated on every write.

## 12. Events and message payloads `[suite-default]`

Named event/type + payload version or additive-compatible schema. Consumers **must tolerate new optional fields**. Do not rename/remove fields in place. Payload is not the producer’s DB row. Do not invent an event bus for style — **ask**. Do not publish ORM entities to the bus as the contract.

## 13. Webhooks and third-party callbacks `[common]`

Inbound webhooks are **hostile until proven otherwise**: verify signature → validate shape → handle **idempotently** → retain **raw payload** when needed for audit → map to domain commands. Do not spread vendor JSON through the core. `[project-example]` verify Stripe signature → idempotent ledger apply → 200.

## 14. Authn / authz at the boundary (light) `[suite-default]`

Protected routes require an **authenticated principal** (**project convention**). **Authorization** is application logic — not `role: admin` from the client. No secrets in query strings or logs (`../observability/RULES.md`, security). Deep auth/PII: security. This file only places the boundary. Do not trust `body.isAdmin`.

## 15. Service-to-service contracts `[suite-default]`

Prefer **in-process** module APIs before any network. Remote: §1 (messages or gRPC over internal HTTP). Explicit contracts, validation at entry, versioning — same honesty as public APIs. **Never** use “reach into the other service’s database” as the integration API. Data entering a process is untrusted regardless of transport.

## Never `[suite-default]`

```
✗ ORM as public JSON · silent breaking field renames · unbounded lists
✗ side-effect mutations without idempotency · second response envelope
✗ parallel validation stack · unverified webhooks / S2S
✗ fake REST / HTTP localhost over in-process · internal HTTP JSON as default sync RPC
✗ public gRPC (or exotic protocols) without ask · leak stacks / internal errors
✗ change auth without treating it as breaking
```

## Looks wrong, is intentional `[suite-default]`

Framework-default errors instead of RFC7807 when the project is consistent. Additive-only unversioned API. No Idempotency-Key on a read-only POST search. UUID PK as public id when chosen. Thinner internal payload if still versioned/validated. Internal gRPC/queues + public REST.

## When to break `[suite-default]`

Author or existing public contract dictates another style. Vendor webhook forces their shape — adapt at the edge. Emergency shim with a sunset date — document and ask if it breaks clients. Local prototype — still no unvalidated money paths.

Working clients and safe retries beat diagram purity.

## Done `[suite-default]`

See Complete. Also: PATCH omitted ≠ null; lists bounded; public IDs thought through; webhooks verified + idempotent; protected routes have a principal; authz not client-claimed.
