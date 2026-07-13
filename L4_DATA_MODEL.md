# L4 — Data Model

How data earns meaning, stays correct, and changes without quietly destroying the
information the system depends on.

**The goal:** a reader should be able to look at a schema and know what every field means,
which invalid states storage will reject, which states application code owns, and how the
model can evolve safely. Data-model decisions should reduce ambiguity, not merely make the
first migration convenient.

## Scope of this guide

This guide covers:

- schema shape and field meaning;
- nullability, absence, identifiers, precision, and time;
- invariants and where they are enforced;
- Postgres relational models, MongoDB documents, and Redis cache/key-value data;
- normalization, JSON, lifecycle, retention, migrations, transactions, and concurrency.

This guide does **not** cover:

- language, framework, or storage selection — **L3**;
- greenfield domain boundaries and project layout — **L2**;
- HTTP, event, DTO, or wire contracts — **L5**;
- deployment choreography, expand/contract rollout, or rollback — **L9**;
- authentication, PII policy, or secrets — **L8**.

L3 decides which storage role is appropriate. L4 decides how data behaves once that storage
has been chosen.

## What “complete” means

A data-model change is complete when:

1. Every new or changed field has one clear meaning.
2. Local invariants are enforced as close to storage as the chosen store allows.
3. External and weakly typed data is validated at the trust boundary.
4. The migration preserves existing data or explicitly documents the approved loss.
5. Concurrent writers cannot silently violate the intended invariant.
6. The storage shape matches the nature of the data instead of hiding relational data in
   documents, JSON, or cache values for convenience.

Complete does **not** mean every business policy is universal. Precision, retention,
rounding, archive behavior, and some lifecycle states remain business-specific. The guide
should provide the default and force the exception to be explicit.

---

## 1. Give every field one meaning

A field is not a junk drawer for several states that happen to fit in the same type.

```
✓ status = "pending" | "active" | "completed"
✓ archivedAt = null until the record is archived
✓ middleName = null when the value is known to be absent

✗ status = null means pending, deleted, not loaded, or not applicable
✗ amount = 0 means free, unknown, not calculated, or not applicable
✗ metadata = JSON because the real fields have not been decided yet
```

If two states produce different behavior, represent them separately. Use a status, an
explicit boolean, a timestamp, a separate relation, or another domain value that makes the
difference visible.

### Null, absent, and undefined

L1’s distinction remains important:

```
null       → the field exists in the model but has no value
undefined  → the caller did not provide the field
```

Storage adds another constraint:

- SQL has `NULL`, but no persistent `undefined`.
- In a document store, an absent field and a field explicitly set to `null` can be distinct.
- In a request or patch, omitted and explicitly cleared are different instructions.

Do not rely on SQL `NULL` to carry several meanings. A nullable field gets one documented
meaning. If “unknown,” “not applicable,” and “not collected yet” must behave differently,
use an explicit state or relation.

```
✓  status = "not_collected"; value = null
✓  status = "not_applicable"; value = null
✗  value = null and every caller guesses which absence state it means
```

Omitting a column during an insert may invoke a database default. Explicitly writing
`NULL` does not mean the same thing. Make that distinction deliberate rather than relying
on ORM defaults.

### Persistent shape and in-memory shape

Persistent entities mirror the external schema exactly, including casing and shipped typos.
Clean in-memory domain types are created through an explicit conversion at the boundary.
Do not silently rename a database field in the entity layer and pretend the schema changed.
See **L1 §7 and §11**.

---

## 2. Validate at trust boundaries

TypeScript types do not validate runtime data. A DTO annotation, interface, or generic only
helps code that has already received valid data.

Validate runtime data before trusting it when it comes from:

- HTTP requests;
- another service or message boundary;
- a database whose contents may be old, corrupted, or written by another system;
- Redis or another weakly typed cache;
- external vendors and files.

After validation inside one confined service, typed internal code may trust the value. Do
not add noisy duplicate validation to every internal function just because the original
input came from outside.

```
✓ external input → runtime validation → typed internal value → domain logic
✓ Redis read → decode and validate → cache value or treat it as a miss
✗ external JSON → cast as Order → write to Postgres
✗ Redis value → assume its old shape still exists forever
```

At a TypeScript boundary, prefer `unknown` when the framework permits it. If a framework
forces `any`, narrow it immediately. A runtime validator should check the actual shape, not
only that a value is truthy.

```
✗ typeof amount === "number"
  // accepts NaN and Infinity

✓ typeof amount === "number" && Number.isFinite(amount)
  // add the domain range and precision checks as required
```

Runtime validation protects the process boundary. It does not replace database constraints
or transaction safety. Two valid requests can still race; storage must protect the
invariant they share.

---

## 3. Enforce each invariant in the right place

The database and application have different jobs.

| Concern | Owner |
|---|---|
| Non-nullability, unique values, foreign keys, local checks | Database |
| Atomic update and conflict detection | Database, inside a transaction or atomic operation |
| Request/message/cache shape | Runtime boundary validator |
| Workflow and state-transition policy | Application |
| Cross-service behavior and external calls | Application / integration layer |
| Read-only derived projection | Query, view, or pure calculation |

The database should protect facts about its own data. Application code should own behavior.

```
✓ UNIQUE(user_id, active_date) prevents two active rows for one user and date
✓ application service decides whether a user is allowed to create the row
✗ trigger silently sends an email when a row changes
✗ SQL function implements the order workflow and the application only invokes it
```

### No new business logic in the database

Do not introduce new stored procedures, triggers, or mutating SQL functions for:

- workflows;
- pricing or eligibility rules;
- state machines;
- authorization;
- external calls;
- application orchestration disguised as PL/pgSQL.

Allowed database logic is data-local and visible:

- constraints and indexes;
- referential integrity;
- read-only views;
- read-only, side-effect-free SQL functions used as projections;
- deterministic, side-effect-free derived calculations;
- generated columns when they represent a pure derivation.

Existing repositories may already depend on database routines. Follow that local code when
working inside it, but do not expand the pattern or use legacy behavior as a reason to put
new domain behavior in SQL.

Age is a good example of a derived value: calculate it from date of birth when read. Do not
store a value that becomes wrong every day merely because it was convenient to calculate it
once.

---

## 4. Identifiers are storage facts, not accidental public contracts

Use the chosen database’s generated identifier by default:

- Postgres: a database-generated identity value or the project’s established equivalent;
- MongoDB: the driver/database-generated identifier;
- Redis: application-defined namespaced keys, not generated row IDs.

Do not manually create identifiers in application code unless the access pattern requires
it. Do not expose an internal database key as a public API identifier merely because it is
already available. Add a separate public identifier when enumeration, external stability,
or a different public format genuinely requires one.

Identifiers should be:

- unique within their intended scope;
- stable for the lifetime of the record;
- represented with a type or clear name at code boundaries;
- included in the relevant uniqueness and foreign-key constraints.

An identifier is not a substitute for a business key. If “one active subscription per user
and product” is the invariant, the database needs a constraint for that business key even
though every row already has a unique primary key.

---

## 5. Exact values need units, precision, and rounding

Never use floating point for a value where exactness matters.

```
✓ amount + currency
✓ quantity + unit
✓ decimal or integer representation with declared scale
✓ explicit rounding at the business boundary

✗ money stored as a floating-point number
✗ percentage stored as an unexplained 0.15 or 15
✗ token quantity stored as a number with no precision contract
✗ formatted "$12.30" used as the source of truth
```

There is no universal scale for every rate, percentage, token amount, measurement, or
financial value. The business rule decides the accepted precision and rounding behavior.
The model must still make the choice explicit:

- what unit is stored;
- what scale is supported;
- how values are rounded;
- whether negative values are allowed;
- what currency or measurement system applies.

For ordinary currency, integer minor units or an exact decimal representation are both
reasonable. The choice must be consistent within the domain and must never silently fall
back to floating point.

---

## 6. Time has different meanings

Do not use one timestamp type for every temporal concept.

| Meaning | Representation |
|---|---|
| An event or instant | UTC timestamp / instant |
| A date on a calendar | Date without a time or timezone |
| A local scheduled event | Local rule plus an IANA timezone, then derive instants |
| A duration | Explicit duration or measured interval |

Use UTC as the standard for persisted instants and ordering. Preserve the original timezone
separately when it matters for display, audit, or recurring local behavior.

```
✓ createdAt = UTC instant
✓ birthday = calendar date
✓ store opening = local time + "Asia/Hong_Kong"
✗ birthday = timestamp at midnight UTC
✗ date-only value represented by inventing the first second of a day
```

Do not manufacture a timestamp merely because sorting is easier. Use a date type for a
date-only concept. A timestamp at midnight is a different meaning and can move across a
calendar boundary when converted between timezones.

---

## 7. Normalize structured data; earn every JSON field

Structured data uses structured fields by default. JSON is for a real document-shaped need,
not for avoiding a schema decision.

JSON is reasonable for:

- genuinely unbounded metadata;
- raw third-party payloads that must be preserved;
- data whose shape is intentionally document-oriented;
- an explicitly chosen read model with its own validation and indexing.

JSON is not a good excuse for:

- ordinary fields that need foreign keys or uniqueness;
- fields frequently filtered or sorted;
- fields whose nullability and lifecycle are not understood;
- a schema that the team is postponing out of fear of migration work.

Denormalization is also deliberate. Duplicate a value only when its ownership, update path,
staleness behavior, and rebuild path are understood.

For MongoDB, embed data that is owned and read together. Reference data that is shared,
independently updated, unbounded, or likely to grow without the parent. If the model needs
many relational constraints across documents, Postgres is usually the more honest store.

---

## 8. Postgres and relational models

Postgres is the relational default for transactional business data. The relational rules
also apply to another relational database when its capabilities support the same invariant.

### Tables and columns

- Use a table when records have a stable shape and independent identity.
- Use the database type that matches the meaning: date for date, boolean for boolean, exact
  numeric for exact numeric values.
- Make required fields `NOT NULL`.
- Use foreign keys for relationships that must not dangle.
- Use `CHECK` constraints for simple local bounds and valid combinations.
- Use unique constraints for business uniqueness, including scoped uniqueness.
- Add indexes for real access paths and uniqueness enforcement, not by reflex on every field.

```
✓ UNIQUE(account_id, provider)
✓ CHECK(amount >= 0)
✓ FOREIGN KEY(user_id) REFERENCES users(id)

✗ application comment: "this combination should be unique"
✗ nullable column because the ORM made the migration easier
✗ cascade delete that can erase independently valuable records without an explicit reason
```

A foreign key prevents a dangling reference; it does not decide whether the relationship
should be deleted. Cascade behavior must be explicit and must match ownership.

### Access style

Follow L3 and L1:

- ORM for common CRUD;
- typed wrappers for ordinary reusable access;
- direct client access for complex queries, aggregations, and multi-filter reads;
- no business rules hidden in ORM callbacks, model hooks, or database triggers.

The wrapper is for convenience, not enforcement. A generic repository that makes a complex
query unreadable is worse than a direct query whose purpose is obvious.

### Postgres values that need special care

- Use database-generated identity values for ordinary primary keys.
- Use `date` for date-only concepts.
- Use timezone-aware instants according to the project’s established Postgres convention,
  with UTC as the persisted standard.
- Use exact numeric or integer representations for exact values.
- Do not use `NULL` as an undocumented state machine.

---

## 9. MongoDB and document models

MongoDB is for data that is genuinely dynamic or document-oriented. “It is JSON” is not
enough; relational data serialized as JSON is still relational data.

### Document shape

A document still needs a deliberate shape:

- required fields and their meanings;
- identifier generation;
- field absence versus explicit `null`;
- array growth and maximum size;
- ownership and update boundaries;
- indexes and uniqueness where required.

Validate documents at runtime on writes and on reads when old or independently written
documents cannot be assumed valid. Use native queries as L3 requires; do not add a heavy ODM
to pretend Mongo is a relational database.

### Embed versus reference

Embed when the child data is owned by the parent, read with it, and has bounded growth.
Reference when the data is shared, independently updated, unbounded, or has its own
lifecycle.

```
✓ order embeds its bounded line-item snapshot
✓ user references a separately managed organization
✗ unbounded event history embedded forever in one user document
✗ shared mutable profile copied into every document with no update path
```

If correctness depends on a transaction across many independently changing documents,
reconsider whether Mongo is the right store for that model. Do not hide a relational
invariant behind application conventions merely because the document is convenient.

---

## 10. Redis cache and key-value data

Redis is not the system of record for core business state. This section covers cache and
key-value storage only. Streams, queues, and pub/sub data shapes are out of scope here.

Redis values are weakly typed and may be stale, missing, evicted, malformed, or left over
from an older version. The application must validate the value before using it.

Every Redis key-value model defines:

- a namespace and key format;
- the serialization format;
- a schema/version marker when the value can evolve;
- TTL and eviction expectations;
- the authoritative source of truth;
- miss, stale-value, and malformed-value behavior;
- how the value is rebuilt or invalidated.

```
✓ cache miss → load source → validate → store → return
✓ malformed cached value → discard or invalidate → load source
✓ versioned key/value when shape changes

✗ Redis value trusted because the writer used the same TypeScript interface
✗ core business record exists only in Redis
✗ cache key omits a parameter that changes the result
✗ no TTL or invalidation policy for data that can become stale
```

The cache is allowed to fail differently from the source of truth. A cache miss is normal;
silently treating malformed or stale data as authoritative is not.

---

## 11. Lifecycle, archive, and deletion

Preserve data by default when no retention policy says otherwise. Archive behavior is an
explicit lifecycle decision for each entity, not a universal `deletedAt` filter copied into
every table.

An archival model must define:

- the lifecycle marker or state;
- whether archived data remains in the primary store or moves elsewhere;
- which queries include or exclude it;
- whether it can be restored;
- how uniqueness behaves while archived;
- retention and eventual deletion rules.

```
✓ archivedAt has a documented meaning and every relevant query handles it deliberately
✓ legal/privacy retention policy can override preservation
✓ restore behavior is defined before archive is introduced

✗ soft-delete every table without checking query and uniqueness behavior
✗ retain sensitive data forever because storage is cheap
✗ move data to an archive that cannot be found or restored
```

Hard deletion is valid when the data has no retention requirement, when privacy or
compliance requires it, or when the entity’s business meaning ends with deletion. Data
retention is not a substitute for L8 security and PII rules.

---

## 12. Migrations change data, not just files

A migration is a change to live meaning. Treat it as a data operation, not merely a schema
diff.

Rules:

- migrations are versioned and committed;
- once applied to a shared environment, do not edit the old migration to change history;
- prefer additive changes before destructive changes;
- validate or backfill existing data before adding a new constraint;
- separate large backfills from the schema change when their runtime or failure behavior
  differs;
- destructive changes require explicit approval and a data-loss statement;
- a down migration is not automatically safe after data has changed.

```
✓ add nullable column → deploy compatible code → backfill → enforce requiredness
✓ add new field while readers understand old and new shapes
✓ remove old data only after the retention and rollback consequences are explicit

✗ rename a live column and deploy code that only understands the new name
✗ add NOT NULL before existing rows have a valid value
✗ assume rollback can restore data that a migration destroyed
✗ rewrite an applied migration because the first version was inconvenient
```

The exact deployment choreography belongs to L9. L4 still owns the data-safety fact that
the model must remain valid during the change.

---

## 13. Transactions and concurrent writers

One business operation touching one database should use one explicit transaction when its
steps must succeed or fail together. Keep external calls out of the transaction unless the
integration genuinely requires that coupling.

Protect shared invariants with the database wherever possible:

- unique constraints for uniqueness;
- atomic conditional updates for counters and state changes;
- transactions for read-and-write sequences;
- optimistic version checks when stale writes must be rejected;
- row locks when a critical section truly requires them.

```
✗ read balance → calculate in application → write balance
  // two workers can read the same old balance and overwrite each other

✓ UPDATE accounts
  SET balance = balance - :amount
  WHERE id = :id AND balance >= :amount
  // check that exactly one row changed

✓ read record with version 4 → write WHERE id = :id AND version = 4
  // reject the write if another worker already advanced the version
```

An ORM `.save()` call is not automatically an atomic business operation. Know whether the
ORM call is one statement, a transaction, or several independent writes.

Do not use a distributed transaction by implication. When one operation spans multiple
services or stores, the cross-service contract and recovery behavior must be explicit;
that belongs with the API/event and release guidance as those layers are written.

Choose stronger isolation or locking because a specific invariant needs it, not because it
sounds safer. Document the non-default choice where a future reader would otherwise mistake
it for ordinary CRUD.

---

## 14. Anti-patterns: never do these

```
✗ use NULL to represent several undocumented states
✗ use floating point for exact money or quantity
✗ store a date-only value as a fake midnight timestamp
✗ put core business state only in Redis
✗ put relational data in Mongo because JSON is convenient
✗ hide a business workflow in a trigger, stored procedure, or SQL function
✗ trust a TypeScript type as runtime validation
✗ trust a Redis value because it came from “our” application
✗ add NOT NULL before old rows have a valid value
✗ treat a down migration as proof that destructive work is reversible
✗ use a generic ORM wrapper that hides a complex query
✗ perform read-modify-write without a transaction or conflict check
✗ add soft delete everywhere without defining filtering, uniqueness, restore, and retention
```

---

## 15. Intentional patterns that may look like mistakes

**A nullable column with a documented meaning.** Nullable is not automatically a smell;
overloaded nullable state is.

**A direct SQL query beside ORM CRUD.** L1 and L3 prefer direct storage-client access when
the query is complex. The direct query can be more readable than a generic abstraction.

**Validation on a cache read.** Redis is intentionally treated as untrusted and stale. The
check is a data-safety boundary, not pointless duplication.

**A read-only database projection.** A view or pure derivation can keep a trivial, shared
calculation close to the data. It must not become a hidden workflow or business engine.

**A forward-only destructive migration.** Not having a fake down migration can be safer
than pretending deleted data can be recovered automatically.

**Preserved archived data that ordinary queries exclude.** Archival is a lifecycle state;
the exclusion must be explicit and reversible where the entity requires it.

---

## When to break these rules

- The existing repository already has a storage convention; follow it for a scoped change
  rather than rewriting the system to match this guide.
- A vendor or database capability forces a different representation; document the reason at
  the boundary and keep the exception narrow.
- A migration must be destructive for legal, privacy, or operational reasons; get explicit
  approval and state what cannot be recovered.
- A measured query or scale requirement justifies denormalization, JSON, a stronger lock, or
  a cache; record ownership, invalidation, and rebuild behavior.
- A legacy database routine is load-bearing; preserve it while avoiding new domain logic in
  the database.

Working behavior and data safety beat storage-style purity. The exception should be visible,
local, and explained where a future reader would otherwise “fix” it.

---

## Done checklist

- [ ] Every new field has one documented meaning.
- [ ] `NULL`, absent, and omitted input are not being confused.
- [ ] External and weakly typed values are validated at the boundary.
- [ ] Local invariants use database constraints or the strongest available store guarantee.
- [ ] Business workflows remain in application code.
- [ ] IDs, units, precision, rounding, and time representation are explicit.
- [ ] Structured data is not hidden in JSON without a concrete reason.
- [ ] Redis keys, versions, TTLs, source of truth, and malformed-value behavior are defined.
- [ ] Archive, restore, retention, and deletion behavior are explicit for the entity.
- [ ] Migration order, backfill, constraint timing, and data-loss risk are understood.
- [ ] Concurrent writers cannot silently violate the invariant.
- [ ] ORM access is simple where it should be; complex queries remain readable.
- [ ] L1 post-code checks still apply to the code and migration work.

## Relationship to other layers

| Topic | Layer |
|---|---|
| Agent protocol and missing-guide behavior | **L0** / `L0_AGENT_PROTOCOL.md` |
| Code shape, entity boundaries, null-vs-absent code style | **L1** / `L1_CODING_STYLE.md` |
| Greenfield layout and domain boundaries | **L2** / `L2_PROJECT_BOOTSTRAP.md` |
| Language, framework, storage role, ORM defaults | **L3** / `L3_LANGUAGE_AND_FRAMEWORK.md` |
| Wire DTOs, HTTP/events, idempotency | **L5** / `L5_API_AND_CONTRACTS.md` |
| Observability and database health | **L6** / `L6_OBSERVABILITY.md` |
| Testing data-related behavior | **L7** / `L7_TESTING.md` |
| Expand/contract rollout, rollback, deploy safety | **L9** / `L9_CHANGE_AND_RELEASE.md` |
| Auth, PII, and secrets | **L8** / `L8_SECURITY_AND_SECRETS.md` |
| Standing data-store decisions | **L10** / `L10_DECISIONS/` |
