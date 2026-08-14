# Stack

Language / framework / storage law. Voice: [`REFERENCE.md`](REFERENCE.md). Also [`../architecture/RULES.md`](../architecture/RULES.md), [`../data/RULES.md`](../data/RULES.md), [`../code-style/RULES.md`](../code-style/RULES.md), [`../protocol/RULES.md`](../protocol/RULES.md).

**Scope `[suite-default]`:** pick a stack and behave in it. Final greenfield choices are **never autonomous** unless the author explicitly overrides.

## Consult vs continue `[suite-default]`

**Consult** (do not decide alone): **Greenfield** — new project or new deployable; **new stack introduction** — new language, major framework, or datastore role. Propose, state trade-offs, wait — unless the author said pick without asking.

**Continue** what exists: work inside an **already-chosen stack**. Current weirdness wins. Do not rewrite to a preferred stack.

Architecture-sized dependency (ORM, auth suite, queue): **ask**.

## Decision order `[suite-default]`

1. **What kind of work is this?** 2. **Language** (tree). 3. **Framework or none**. 4. **Storage** by data nature. "Default framework?" is the wrong question.

## Greenfield hard rules `[suite-default]`

```
NO  Python application service — ever.
NO  TypeScript for CPU-bound / event-loop-stalling compute.
NO  Serverless as the system backend (Next API routes, lambdas-as-app-core).
YES TypeScript uses npm and runs on Node.js.
NO  Business logic in the database. Constraints OK; domain behavior in app code.
```

Gray area: **ask**. Do not invent a second ban list.

## Language decision tree `[suite-default]`

Use this to **propose**, not to ship unilaterally. Parallelism = **CPU-bound / multi-core compute**, not high I/O concurrency.

```
EVM? → Solidity (required). Hardhat known; Foundry OK by author. Don't migrate toolchain unprompted.
Frontend UI? → TypeScript + React (default). Vue/Angular only with a strong reason.
  Prefer TanStack + Vite-style client apps. Next.js on greenfield ONLY when really justifiable (SEO/SSR). Existing Next stays Next. Serverless is NOT the system backend.
Scripting / ML / bulk data massage? → Python allowed. Never a long-lived application service.
CPU-bound / event-loop-stalling? → Not TS or Python. Usually Rust; Go only narrow.
  Do not plan greenfield around "TS + worker threads will save us."
Speed / efficiency / memory critical? → Prefer Rust. Go rarely wins (Express/Node covers
  many small services). Go-only SDK can win.
Heavy OOP + author steering JVM? → Prefer Kotlin (Spring Boot). Kotlin + thin Java interop
  first; full Java only when interop fails.
Typical greenfield service / API? → TypeScript is the default. NestJS when an opinionated
  TS backend is wanted. Framework-optional where culture is small (many Rust services).
SDK-locked small service? → That language can win (e.g. Go-only SDK).
```

### TypeScript default vs Kotlin direction `[suite-default]`

TS is the **daily greenfield default**. Kotlin is a **preferred direction** when the author steers JVM — do not front-load it "for the future." Porting later (including with AI) is an accepted tradeoff.

## Language field notes `[suite-default]`

- **TypeScript** — default greenfield; **required** frontend; **I/O concurrency**. **OOP**; **npm** + **Node.js**. Greenfield: do **not** plan TS + worker threads. Existing: **horizontal scale of a stateless TS service**.
- **Rust** — speed / efficiency / CPU-bound. **structs, `impl`, traits, composition, explicit ownership**. Not Java/TS hierarchies. Not default CRUD.
- **Kotlin** — **Author-steered** heavy OOP / new JVM. Spring Boot.
- **Java** — interop. **Kotlin + thin Java interop first.** No **Java junk drawer**.
- **Solidity** — EVM. **No alternative language discussion.** Keep repo toolchain.
- **Go** — uncommon. **Go-only SDK** or author wants Go. Not "small HTTP" alone; prefer **Rust** if efficiency matters. Framework-light; `error` returns.
- **Python** — scripting, ML, **mass data massage**. App services / APIs — **never** on greenfield.

## Frontend and thin glue `[suite-default]`

React default is **ecosystem gravity** (intentional). Prefer TanStack + Vite. Next.js **only when really justifiable**. Do not rewrite existing Next/Vue/Angular. Serverless is **glue only** (~30-line adapters). Tiny TS HTTP → **Express**, not Nest, not Next-as-backend.

## Backend frameworks `[suite-default]`

TS **opinionated long-lived HTTP** → **NestJS**. Tiny glue → **Express**. Kotlin/Java → **Spring Boot**. Rust often **no** heavy framework. Go rare, framework-light. BullMQ / RabbitMQ when architecture needs them. No second HTTP framework, DI container, or app shell without asking.

## Storage `[suite-default]`

Pick from **data nature**, not fashion.

**Postgres** default relational. **MongoDB** only when truly **document-oriented**. **Redis** cache/coordination, not the **system of record**. **SQLite** **localhost-only** / single-process — multi-user production is Postgres.

### Business logic is never in the database `[suite-default]`

```
NO business logic in the DB.
NO SQL functions / stored procedures implementing domain rules.
NEVER. NEVER. NEVER.
```

Allowed: constraints / integrity. Not: workflows, pricing, state machines, PL/pgSQL.

### Access style `[suite-default]`

Postgres: ORM for CRUD; **direct client for complex queries** ([`../data/RULES.md`](../data/RULES.md)). Mongo: native queries, not a heavy ODM. No domain logic in model hooks, ActiveRecord callbacks, or triggers-as-app.

## Errors `[suite-default]`

Unexpected failures **surface where they are detected** ([`../code-style/RULES.md`](../code-style/RULES.md)). Expected outcomes are not errors. Follow language convention: TS/Kotlin/Java throw; Go `error`; Rust `Result`/`Option`. "Don't return errors as values" means **don't return errors as values in languages where throw is the idiom** — not a ban on idiomatic `Result`/`error`.

## Tooling `[suite-default]`

TS: **Always npm**, **Node.js**, strict mode; formatter + linter required. Architecture-sized libs / greenfield doubt: **ask**.

## Layout `[common]`

**No personal global folder standard** — follow language/framework practice. Monorepo vs multi-repo follows the solution.

## When to break `[suite-default]`

Author explicitly chooses outside the tree. Brownfield: **no drive-by re-stack**. SDK lock (note / ADR [`../decisions/RULES.md`](../decisions/RULES.md)). Narrow TS worker blip — prefer horizontal scale or a compute side service. Glue only stays glue. Working delivery beats a pure re-stack.

Breaking greenfield autonomy, Python-as-app, TS-for-CPU-stall, serverless-as-core, or business-logic-in-DB without an explicit author override is **not a valid exception**.

## Done `[suite-default]`

**Proposing a stack:** problem class; CPU vs I/O; language + framework-or-none + storage + why; hard rules checked; trade-offs; **Author confirmation received**; ADR `proposed`.

**Implementing in-stack:** **Did not re-litigate** the stack. No new major framework without asking. No business logic in SQL/ORM callbacks. Language-convention errors. TS: npm + Node.

## Never

```
✗ Autonomous greenfield stack · TS + worker threads as greenfield CPU architecture
✗ Python application service · TypeScript for event-loop-stalling compute
✗ Serverless / Next routes as the system backend · business logic in the DB
✗ Mongo for relational core · Redis as primary business database
✗ Java/TS hierarchies in Rust · FP-only in TS/Kotlin OOP · fight Go/Rust error idioms
✗ Second framework without asking · Yarn/pnpm for TS · skip formatter/linter/strict
✗ Rewrite working Next/Vue/Angular · front-load Kotlin "for the future" when TS fits
```

## Looks wrong, is intentional `[suite-default]`

TS greenfield while Kotlin is a long-term direction. React because ecosystem. Express glue / Nest real TS services. Horizontal TS replicas over worker threads. Framework-optional Rust. Thin Java at interop edges. **Postgres almost always** — boring on purpose. Go rarely chosen.

