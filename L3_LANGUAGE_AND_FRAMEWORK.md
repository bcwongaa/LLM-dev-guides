# L3 — Language and Framework

How to pick languages, frameworks, and storage — and how to behave once a stack is chosen.

**The goal:** agents stop inventing stacks, mixing mental models, or treating “popular” as
“default.” Suggestions should match the author’s judgment. Final greenfield choices are
**never autonomous** unless the author explicitly overrides that rule.

This guide is not a language tutorial. It is not how to split domains
(→ **L2** / `L2_PROJECT_BOOTSTRAP.md`), not schema design (→ **L4** / `L4_DATA_MODEL.md`),
and not day-to-day code smell (→ **L1** / `L1_CODING_STYLE.md`). Per-framework taste
guides may appear later; until then, use each framework’s common practice plus judgment.

---

## 1. Process rule: when to consult vs continue

### Consult the author (do not decide alone)

- **Greenfield** — new project or new deployable system.
- **New stack introduction** — new language, new major framework, or new datastore role
  in a solution that did not have it.

Propose using this guide, state trade-offs, wait for confirmation — unless the author
explicitly said to pick without asking.

### Do not consult — continue what exists

- Bugfixes, features, refactors **inside an already-chosen stack**.
- The current stack’s weirdness, legacy framework, or imperfect layout **wins**.
- Do **not** rewrite existing code to a preferred stack “because the guide likes Nest /
  React / Postgres better.” Work with what is there (see L1 scope rules).

```
✓  greenfield: propose TS + Nest + Postgres, wait
✓  existing Next.js app: add the feature in Next.js, no migration lecture
✗  mid-feature: “we should port this service to Kotlin”
✗  greenfield: scaffold a full stack with no author confirmation
```

**Slight doubt on an architecture-sized dependency** (new ORM, auth suite, queue product):
ask. Routine packages inside the existing stack: use judgment and house tooling rules.

---

## 2. Decision order

Always in this order:

1. **What kind of work is this?** (UI, HTTP API, worker, script, EVM, ML, CPU-heavy, …)
2. **Language** — from the tree below.
3. **Framework or none** — idiomatic for that language and the job; not a universal default.
4. **Storage** — by nature of the data and access patterns.

“What’s the default framework?” is the wrong question. Frameworks are good and bad by
context. Languages carry harder constraints (runtime, CPU vs I/O, mental model).

---

## 3. Greenfield hard rules

These are **absolute when planning greenfield** (or deliberately introducing a new stack).
They are not a license to rewrite brownfield.

```
NO  Python application service — ever.
NO  TypeScript when the workload needs a lot of CPU-bound parallelism or heavy
    computation that would stall the Node event loop.
NO  Serverless as the system backend (Next API routes, lambdas-as-app-core, etc.).
YES TypeScript uses npm and runs on Node.js (not “whatever package manager is trendy”).
NO  Business logic in the database — no SQL functions / stored procedures for business
    rules. NEVER. Constraints and integrity are fine; domain behavior lives in application
    code. (Also load-bearing for L4.)
```

Gray area outside this list: **ask** when unsure. Do not invent a second ban list mid-task.

---

## 4. Language decision tree (for suggestions)

Use this to **propose**, not to ship unilaterally. “Parallelism” here means **CPU-bound /
multi-core compute** — work that stalls or would stall the event loop — **not** high
concurrency I/O. TypeScript/Node is fine for many concurrent requests that mostly wait on
network and DB.

```
Is this EVM / smart-contract work?
  → Solidity (required). Tooling: Hardhat is known and acceptable; Foundry is also
    acceptable when the project or author prefers it. Do not migrate an existing
    project’s toolchain unprompted.

Is this frontend UI?
  → TypeScript + React (default).
  → Vue or Angular only with a strong, stated reason (usually existing team/codebase).
  → Prefer TanStack + Vite-style client apps over treating Next.js as the default.
  → Next.js on greenfield ONLY when really justifiable (e.g. clear SEO/SSR product need).
    Prefer not to default to it. Existing Next codebases: keep working in Next.
  → Serverless / framework-hosted backend is NOT the system backend.
    Thin glue only (see §6).

Is this scripting, ML, or bulk data massage?
  → Python is allowed.
  → Python is never a long-lived application service.

Is the work CPU-bound, multi-core, or heavy compute that would stall the event loop?
  → Do not choose TypeScript or Python for that component.
  → Greenfield: pick a language fit for compute (usually Rust; Go only in narrow cases).
  → Do not plan greenfield around “TS + worker threads will save us.”

Is execution speed / efficiency / memory pressure critical?
  → Prefer Rust.
  → Go is rarely the winner here: Express/Node can cover many “small service” shapes at
    higher memory cost; if it must be fast and efficient, Rust is usually not much more
    effort than Go. Accept that tradeoff. Go still wins when a Go-only SDK dominates.

Is this a heavy backend with an OOP mental model, and the author is steering JVM?
  → Prefer Kotlin (Spring Boot is the known shape).
  → Prefer Kotlin + thin Java interop first; full Java modules only when interop truly
    fails or a dependency must stay native Java.

Otherwise (typical greenfield service / API without special CPU needs)?
  → TypeScript is the default — it is capable enough for most scopes.
  → NestJS when an opinionated TS backend framework is wanted.
  → Framework-optional where language culture is small (many Rust services).

Is there a small service whose ecosystem is locked to one SDK language?
  → That language can win (e.g. Go-only SDK) even if another language would be “purer.”
```

### TypeScript default vs Kotlin direction (intentional tradeoff)

TypeScript remains the **daily greenfield default** for ordinary APIs and products that do
not need CPU-bound parallelism. It is genuinely capable for those scopes.

Kotlin is a **preferred direction** for heavy OOP backends when the author chooses to aim
there — not something agents should front-load on day one “for the future.” Early Kotlin
is often future work the project does not need yet. **Porting later (including with AI)
is an accepted tradeoff.** Do not pressure a greenfield TS proposal into Kotlin unless the
author steers that way or constraints clearly demand the JVM.

---

## 5. Language field notes

### TypeScript

- **When:** default for most greenfield; **required** for frontend; fine for high
  **I/O concurrency**.
- **How:** **OOP style**; keep types honest. `:any` and ignored strictness skew the
  codebase over time. **npm** + **Node.js**.
- **When not:** CPU-bound / multi-core / heavy compute that stalls the event loop.
- **Concurrency note:** many simultaneous network/DB-bound requests ≠ reason to leave TS.

**Worker threads and scale-out (greenfield vs day-to-day):**

| Context | Rule |
|---|---|
| **Greenfield planning** | Absolute: if CPU-bound work is foreseeable, **do not** plan TS + worker threads as the architecture. Choose a fit language (or a separate compute service in that language). |
| **Day-to-day in an existing TS system** | Not absolute. Prefer **horizontal scale of a stateless TS service** over worker threads when that solves load. Worker threads only for narrow off-main-thread blips if unavoidable — still prefer not to. |

### Rust

- **When:** cutting-edge speed, efficiency, memory safety; CPU-bound components.
- **How:** idiomatic Rust — **structs, `impl`, traits, composition, explicit ownership**.
  Do **not** import Java/TypeScript class hierarchies. FP tools (iterators, `Result`,
  immutability) where they pay; this is not “pure FP only.”
- **When not:** default CRUD API language for ordinary products.

### Kotlin

- **When:** author-steered heavy OOP backends; preferred over Java for new JVM work;
  mental model close to TypeScript.
- **How:** Spring Boot is the known full-stack backend shape on the JVM here.
- **Cost:** not dynamic; JS libraries need JVM equivalents — budget research.

### Java

- **When:** interop — dependency is native/easiest in Java; or a module must remain Java
  for legacy-stable business logic.
- **How:** **prefer Kotlin + thin Java interop first.** Full Java module only when interop
  truly fails or the dep forces it. Do not open a Java junk drawer by default.
- **When not:** default greenfield “because enterprise.”

### Solidity

- **When:** EVM. No alternative language discussion.
- **How:** known toolchain includes Hardhat; Foundry acceptable by project/author
  preference. Keep whichever the repo already uses.

### Go

- **When:** uncommon. Mainly **Go-only SDK** lock-in, or author explicitly wants Go.
- **Not when:** “small HTTP service” alone — Express/Node often covers that with a larger
  memory footprint, and that tradeoff is accepted. If efficiency really matters, prefer
  **Rust** (effort is not far off).
- **How:** usually framework-light; follow Go conventions (including `error` returns).

### Python

- **When:** scripting, machine learning, mass data massage.
- **When not:** application services and APIs — **never** on greenfield.
- **Why not:** long-context readability for humans is poor; conventions often fight clear
  structure.

---

## 6. Frontend and thin glue

| Default | Prefer | Greenfield avoid unless justified |
|---|---|---|
| React + TypeScript | TanStack-centered patterns + Vite | Next.js without a real SSR/SEO (or similar) justification |
| | | Vue/Angular without a strong reason |
| | | Serverless / framework API routes as the **system** backend |

React is the default largely because of **ecosystem gravity**, not pure technical
superiority. That bias is intentional.

**Next.js:** on greenfield, use **only when really justifiable**. Do not rewrite an
existing Next (or Vue/Angular) codebase just because this guide prefers something else.

**Serverless backends:** not the application core. They may exist as **glue only**
(webhooks, tiny adapters). If the glue is on the order of ~30 lines and needs a tiny
HTTP surface in the TS world, **Express** is appropriate — not Nest, not a fake full
backend inside Next.

```
✓  Express handler as thin webhook glue
✓  full product API as Nest (or existing stack) service with real process lifecycle
✗  Next.js route handlers as the system of record / main business API on greenfield
✗  lambda soup implementing domain workflows as the default architecture
```

---

## 7. Backend frameworks

There is no single backend framework for all languages.

| Context | Known / preferred shape |
|---|---|
| TypeScript, opinionated long-lived HTTP service | **NestJS** |
| TypeScript, tiny glue / minimal surface | **Express** (glue), not a second “app platform” |
| Kotlin / Java | **Spring Boot** |
| Rust | often **no** heavy framework; small libraries + clear modules |
| Go | rare; framework-light if used |
| Queues / jobs (TS world) | BullMQ when architecture needs it |
| Messaging | RabbitMQ when architecture needs it |

Do not add a second HTTP framework, second DI container, or second “app shell” to a
codebase that already has one without asking (new-stack rule).

---

## 8. Storage and where logic lives

Pick storage from **data nature**, not fashion.

| Store | Role |
|---|---|
| **Postgres** | Default relational store. Almost always wins unless a rare niche forbids it. |
| **MongoDB** | Only when data is truly dynamic / document-oriented and that shape is the point. |
| **Redis** | Cache, and/or loose inter-service communication in a microservice setup. |
| **SQLite** | Embedded store for the small localhost-only tool shape (L2 §7) or single-process utilities. Not the default for multi-user production services — that is Postgres. |

```
✓  transactional business records, relations, constraints  → Postgres
✓  genuinely schemaless document blobs as the product model → consider Mongo (ask)
✓  hot read cache, short-lived coordination, pub/sub-ish glue → Redis
✗  Mongo “because JSON” when the data is relational
✗  Redis as the system of record for core business state
```

### Business logic is never in the database

```
NO business logic in the DB.
NO SQL functions / stored procedures implementing domain rules.
NEVER. NEVER. NEVER.
```

- **Allowed in DB:** persistence, constraints, keys, nullability, referential integrity —
  facts about data shape and integrity.
- **Not allowed in DB:** workflows, pricing rules, state machines, “if status then …”
  domain behavior, app orchestration disguised as PL/pgSQL.

Application code owns behavior. The database stores and protects data.

### Access style (with L1 §19)

- **Postgres:** ORM preferred for common access; typed wrappers for CRUD; **direct client
  for complex queries** the wrapper cannot express cleanly. ORM is convenience, not the
  home of business rules.
- **Mongo:** native queries preferred over a heavy ODM pretending to be SQL.
- Do not bury domain logic in model hooks, ActiveRecord callbacks, or DB triggers-as-app.

---

## 9. Errors: L1 and language convention

L1’s core merit stands: **unexpected failures should surface where they are detected**,
not get translated into vague nulls three layers down.

1. **Expected outcomes are not errors.** Missing draft, empty search, “user has no
   orders yet” — normal control flow (`null`, empty, domain result), not exceptions.
2. **Follow the language’s convention** rather than fighting it.
   - TypeScript / Kotlin / Java: throwing for unexpected domain/system failures is normal.
   - Go: `error` return values — use them.
   - Rust: `Result` / `Option` at fallible boundaries; panic only for true programmer
     invariants.
3. Where L1 says “don’t return errors as values,” read that as **don’t return errors as
   values in languages where throw is the idiom.** It does **not** ban idiomatic `Result`
   / `error` in Rust and Go.

```
✓ TS: throw OrderAlreadyShippedError in the service that detected it
✓ Go: return fmt.Errorf("...: %w", err) up to the handler that maps status codes
✓ Rust: fn parse(e: Entity) -> Result<Domain, Error>
✗ TS: return new Error(...) and hope callers check
✗ Go: panic for ordinary missing rows that should be a 404
✗ Treating “not found” as an unexpected throw in a search/list path
```

---

## 10. Tooling and packages

| Rule | Detail |
|---|---|
| TypeScript package manager | **Always npm** |
| TypeScript runtime | **Node.js** |
| Strictness | **Strict mode** (or equivalent) when available |
| Formatter + linter | **Required** when the ecosystem supports them; wire them early |
| New architecture-sized libraries | **Ask** if they change the stack shape |
| Slight doubt on greenfield/stack | **Ask** |

Do not silently add a large dependency “for convenience” when it changes architecture.

---

## 11. Layout

**No personal global folder standard** in this guide. Follow the **common practice of the
language and framework** in use; use judgment. Future optional sub-guides per framework
may capture finer taste — until then, do not invent a house folder religion.

Mental model of the *solution* comes first; monorepo vs multi-repo depends on what is
being built. Both are fine when the solution shape calls for them.

---

## 12. Anti-patterns

```
✗ Decide greenfield/new stack without consulting (unless author overrode)
✗ Plan greenfield TS around worker threads for foreseeable CPU-bound work
✗ Python application service (especially greenfield — never)
✗ TypeScript for event-loop-stalling CPU-bound / multi-core compute
✗ Serverless / Next route handlers as the main system backend on greenfield
✗ Business logic in SQL functions, stored procs, triggers-as-app, or ORM model callbacks
✗ Mongo for relational core data
✗ Redis as primary business database
✗ Force Java/TS class hierarchy design in Rust
✗ Force FP-only style in TypeScript / Kotlin services that should be OOP
✗ Fight Go/Rust error idioms to satisfy a TS reading of L1
✗ Add a second framework or major client without asking (new-stack rule)
✗ Yarn/pnpm for TS when npm is the house rule
✗ Skip formatter/linter/strict mode “to move faster”
✗ Rewrite working Next/Vue/Angular/Express code just to match greenfield preferences
✗ Front-load Kotlin on day one “for the future” when TS fits the scope
```

---

## 13. Intentional patterns that may look like mistakes

**TS greenfield even though Kotlin is a long-term direction.** Capability + deferring
JVM cost is deliberate. AI-assisted port later is an accepted tradeoff.

**React “because ecosystem.”** Popularity is an accepted input. Don’t rewrite UI stacks
for purity.

**Express for glue, Nest for real TS services.** Small surface ≠ under-engineered.

**Horizontal TS replicas instead of worker threads.** Scaling stateless Node is often
preferable to in-process thread complexity when the stack is already TS.

**Framework-optional Rust services.** Not incomplete scaffolding.

**Thin Java only at interop edges.** Not a second primary language by default.

**Postgres almost always.** Boring on purpose.

**Go rarely chosen.** Not an oversight; Express-or-Rust covers most of the motivation.

---

## 14. When to break these rules

- Author **explicitly** chooses outside the tree (including temporary spikes).
- **Brownfield:** local codebase wins; no drive-by re-stack (L1).
- SDK or vendor lock forces a language (say so in notes / later ADR).
- Day-to-day TS needs a narrow escape hatch (e.g. tiny worker blip) — allowed with eyes
  open; still prefer horizontal stateless scale or a small compute side service.
- Glue serverless/Express exceptions as in §6 — glue only, not domain core.

Working delivery in the chosen stack beats a pure re-stack.

---

## 15. Done checklists

### A. Proposing a stack (greenfield or new major component)

- [ ] Problem class stated (UI / API / worker / script / EVM / ML / CPU-bound / …)
- [ ] CPU-bound vs I/O-bound called out if relevant
- [ ] Language proposed from the tree, with one-line why
- [ ] Framework or “none” proposed, with one-line why
- [ ] Storage proposed from data nature (Postgres / Mongo / Redis roles clear)
- [ ] Greenfield hard rules checked (no Python app service, no TS-for-CPU-stall, no
      serverless backend core, npm+Node for TS, no business logic in DB)
- [ ] Trade-offs and rejected alternatives named briefly
- [ ] **Author confirmation received** (unless override was explicit)
- [ ] **ADR drafted** per L10 (status: `proposed`) recording the accepted choice

### B. Implementing inside an already-chosen stack

- [ ] Did not re-litigate or rewrite the stack
- [ ] Language mental model respected (see field notes)
- [ ] No new major framework/client without asking
- [ ] No business logic pushed into SQL/DB routines or ORM callbacks
- [ ] Errors follow language convention + unexpected-vs-expected split
- [ ] Postgres ORM-first for CRUD; direct client for complex queries; Mongo native
- [ ] Strict / format / lint on if the ecosystem allows
- [ ] TS: npm + Node
- [ ] L1 post-code check still applies to the code written

---

## Relationship to other layers

| Topic | Layer |
|---|---|
| Code smell, decomposition, naming, get/ensureGet | **L1** / `L1_CODING_STYLE.md` |
| Domain split, service boundaries, greenfield layout intent | **L2** / `L2_PROJECT_BOOTSTRAP.md` |
| Language / framework / storage choice | **L3** / `L3_LANGUAGE_AND_FRAMEWORK.md` (this file) |
| Tables, migrations, invariants; reinforce no domain-in-DB | **L4** / `L4_DATA_MODEL.md` |
| Wire contracts, HTTP/events | **L5** / `L5_API_AND_CONTRACTS.md` |
| Observability | **L6** / `L6_OBSERVABILITY.md` |
| Testing | **L7** / `L7_TESTING.md` |
| Security / secrets | **L8** / `L8_SECURITY_AND_SECRETS.md` |
| Change and release | **L9** / `L9_CHANGE_AND_RELEASE.md` |
| Standing decisions (ADRs) | **L10** / `L10_DECISIONS/` |
| How agents open guides and ask vs decide | **L0** / `L0_AGENT_PROTOCOL.md` |
| Optional per-framework taste | future sub-guides if needed; not required |
