# Data

Binding data-model law. Prose: [`REFERENCE.md`](REFERENCE.md).

**Scope `[suite-default]`:** meaning, nullability, IDs, precision, time, invariants, Postgres/Mongo/Redis, JSON, lifecycle, migrations, transactions, two-tier access. Stack chooses the store; this file decides how data behaves. ## Complete `[suite-default]`

One meaning per field. Local invariants as close to storage as the store allows. External / weakly typed data validated at the trust boundary. Migration preserves data or documents the approved loss. Concurrent writers cannot silently violate the invariant. Shape matches the data — no hiding relational facts in documents, JSON, or cache.

## 1. One meaning per field `[suite-default]`

If two states produce different behavior, represent them separately.

### Null, absent, and undefined `[suite-default]`

`null` = field exists, no value. `undefined` = caller did not provide it. SQL has `NULL` but no persistent `undefined`. Documents: absent ≠ explicit `null`. Request/patch: omitted ≠ cleared. One documented meaning per nullable field. Unknown / N/A / not-collected as different behavior → explicit state. Persistent entities mirror the external schema. Domain types convert at the boundary.

## 2. Validate at trust boundaries `[common]`

Types do not validate runtime data. Validate: HTTP; other service/message; a DB that may be old, corrupt, or foreign-written; Redis/weak cache; vendors/files. After validation inside one confined service, typed internals may trust. Prefer `unknown` at a TS boundary; if `any` is forced, narrow immediately. Check shape, not truthiness. `typeof n === "number"` accepts NaN/Infinity — require `Number.isFinite`.

## 3. Invariants in the right place `[suite-default]`

DB: non-null, unique, FK, local checks, atomic update/conflict. Runtime: request/message/cache shape. App: workflow, state-transition, authorization, external calls. Query/view: read-only derived projection. DB protects facts. App owns behavior.

### No new business logic in the database `[suite-default]`

No new stored procedures, triggers, or mutating SQL for workflows, pricing/eligibility, state machines, authorization, external calls, or orchestration. Allowed: constraints, indexes, FKs, read-only views, side-effect-free projections, generated columns that are a pure derivation.

## 4. Identifiers `[suite-default]`

Identifiers are storage facts, not accidental public contracts. Default: Postgres identity; Mongo driver/database id; Redis namespaced keys. Do not mint IDs in app code unless required. Do not expose an internal key as a public API id merely because it exists. Not a substitute for a business key.

## 5. Units, precision, and rounding `[common]`

Never float where exactness matters. Make explicit: unit, scale, rounding, negatives, currency/measurement system. Ordinary currency: integer minor units or exact decimal — never silently fall back to float.

## 6. Time has different meanings `[suite-default]`

Instant = UTC timestamp. Calendar date = date, no time or timezone. Local scheduled event = local rule + IANA timezone, then derive instants. Duration = explicit duration or interval. UTC for persisted instants and ordering. Do not invent midnight UTC for a date-only concept.

## 7. Normalize; earn every JSON field `[suite-default]`

Structured fields by default. JSON is earned for unbounded metadata; raw third-party payloads; intentionally document-oriented data; an explicit read model with its own validation and indexing. Not an excuse to postpone a schema. Denormalize only when ownership, update, staleness, and rebuild are understood.

## 8. Postgres `[suite-default]`

Relational default for transactional business data. Table = stable shape + independent identity. Type matches meaning. Required `NOT NULL`. FKs that must not dangle. `CHECK` for local bounds. Unique for business uniqueness. Cascade must be explicit.

### Access style — Two tiers of data access `[suite-default]`

- **Wrapper methods** for common CRUD — named, typed, reusable.
- **Direct storage-client access** for complex queries — aggregations, multi-filter finds, sorts, limits.

No business rules in ORM callbacks or DB triggers. The wrapper is convenience, not enforcement. Generated identity for ordinary PKs. `date` for date-only. Exact numeric or integer for exact values.

## 9. Mongo `[suite-default]`

For genuinely dynamic or document-oriented data. “It is JSON” is not enough. Validate on write, and on read when old documents cannot be assumed valid. Native queries. Embed: owned by the parent, read with it, bounded growth. Reference: shared, independently updated, unbounded, or own lifecycle. If correctness needs a transaction across many independently changing documents, reconsider Mongo.

## 10. Redis `[suite-default]`

Not the system of record for core business state. Cache / key-value only. Values may be stale, missing, evicted, malformed, or leftover — validate before use. Define namespace, key format, serialization, version marker, TTL, source of truth, miss/stale/malformed behavior, and rebuild path.

## 11. Lifecycle, archive, and deletion `[suite-default]`

Preserve by default when no retention policy says otherwise. Archive is per-entity, not a universal `deletedAt`. Define marker, stay vs move, query inclusion, restore, uniqueness while archived, retention. Hard delete when no retention requirement, privacy requires it, or meaning ends.

## 12. Migrations change data, not just files `[suite-default]`

A migration changes live meaning. Versioned and committed. Do not edit an applied migration. Additive before destructive. Validate or backfill before a new constraint. Separate large backfills when runtime differs. Destructive work needs explicit approval and a data-loss statement. [release](../release/RULES.md) owns deploy choreography.

## 13. Transactions and concurrent writers `[suite-default]`

One business operation, one database, one explicit transaction when steps must succeed or fail together. External calls stay out. Protect invariants: unique constraints; atomic conditional updates; transactions for read-and-write; optimistic version checks. ORM `.save()` is not automatically atomic. No distributed transaction by implication.

## Never `[suite-default]`

```
✗ NULL as several undocumented states · float for exact money/qty · date-only as fake midnight
✗ core business state only in Redis · relational data in Mongo because JSON is convenient
✗ workflow in a trigger / stored procedure · TS type as runtime validation
✗ NOT NULL before old rows are valid · down migration as reversibility proof
✗ generic ORM wrapper hiding a complex query · read-modify-write with no conflict check
✗ soft-delete everywhere without filter / uniqueness / restore / retention
```

## Looks wrong, is intentional `[suite-default]`

**Documented nullable** is not a smell. **Direct SQL beside ORM CRUD** for complex queries. **Redis is untrusted** on read.

## When to break `[suite-default]`

Existing convention: follow it for a scoped change. Vendor/DB force: document at the boundary. Destructive legal/privacy/ops: explicit approval. Measured scale: denorm / JSON / lock / cache — record ownership, invalidation, rebuild. Legacy DB routine: preserve; do not add new domain logic in the DB.

## Done `[suite-default]`

One documented meaning per new field. `NULL` / absent / omitted not confused. Boundary validation. DB constraints for local invariants. Workflows in app code. IDs, units, precision, time explicit. JSON earned. Redis not SoR. Concurrent writers cannot silently violate the invariant.
