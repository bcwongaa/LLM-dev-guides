# Architecture

What pieces exist and how they are arranged. Structure follows the product's real engines — not a folder religion, premature microservice, day-one shared platform, or a remembered framework demo. Rationale: [`REFERENCE.md`](REFERENCE.md).

**Scope `[suite-default]`:** thinking order, logical vs physical, hybrid layout, new deployable/repo, prefer duplication, data ownership, FE/BE, brownfield, cache / bounded poll / named-constant dispatch. Not stack, schema, contracts, code-style, protocol, release, or auth/PII. Greenfield stack is never autonomous (`../stack/RULES.md` + `../protocol/RULES.md`).

## Complete `[suite-default]`

Mental model stated, not only a folder tree. Logical vs physical not confused. Layout hybrid or brownfield-local. New deployable / multi-repo / cross-domain rewrite has **author approval** (or is out of scope). Stack via stack guide. Not a perfect monorepo, shared-library platform, or future-proof mesh.

## Thinking order `[suite-default]`

Always **engines → model → layout → stack**: engines/capabilities → who owns what / who calls whom → modules, packages, apps → stack per piece (language → framework → storage), author confirm on greenfield. No universal monolith-first or services-first. **Start from engines and the mental model**, not tooling.

```
✓  name engines first · tiny localhost may be one FE
✗  scaffold stack/services first · viral folder template · language as step one
```

## Logical vs physical `[suite-default]`

**Logical engine / module:** capability with a clear job and ownership; may live **inside** one process. **Physical deployable / service:** built, shipped, scaled, or failed **on its own**. **Default:** split **logically** first (modules with **clear public surfaces**). Physical needs a **clear boundary reason** and **author approval** before scaffold.

```
✓  ledger/ + shipping/ in one API · propose a worker, wait for yes
✗  repo+HTTP per noun · folder called a "service" with no deploy boundary
```

## New deployable `[suite-default]`

**Propose** when **at least one** holds. **None of these auto-approve.** New service, de-facto product-split package, or new repo is protocol **always-ask**. Reasons: different scale, failure mode, or data isolation (CPU worker vs latency API; store must not share fate); different team or release cadence (ship schedule a modular monolith cannot absorb); different language/runtime required (stack forces Rust/Go/Kotlin beside a TS app). Do not split "for testability" when modules suffice.

## Hybrid layout `[suite-default]`

No universal folder tree. **Top level by business capability / engine** (or `web/` / `api/` when those are the real products). **Inside**, framework-idiomatic layers as that stack expects. Monorepo vs multi-repo: **no default**; **ask** when structural (new repo, package graph, deploy pipeline).

## Prefer duplication `[suite-default]`

Do **not** start `packages/shared` for domain types, utils, and common services. Duplicate a small helper until the **third copy hurts**. Thin boring infra only when the stack already expects it. Unavoidable share = **smallest** surface (type or pure function), not a domain service layer. Prefer explicit contracts (`../contracts/RULES.md`) over a grab-bag package. Same deployable: other module's **public API**, not private files.

## Data ownership `[suite-default]`

**One database is OK** when **table (or collection) ownership is clear**. Each engine owns its tables; others only through that engine's public module API (or defined read paths). **Separate database** when a **physical** split or real isolation requires it — not aesthetic. Schema: `../data/RULES.md`. One Postgres until a worker needs isolation. No one-DB-per-engine "for microservices purity" with no deploy split. No module UPDATEs any table ad hoc.

## Frontend and backend `[suite-default]`

Prefer **separate apps** when there is a real UI and a real backend. Prefer **TanStack + Vite**-style FE over Next SSR as universal. No serverless backends as the core. **Exception:** **very small, localhost-only** may keep **everything in the frontend**. Not the default for multi-user production. No production domain logic in Next API routes. No backend for a one-file local script.

## How engines talk `[suite-default]`

Same deployable → **in-process** public API, not fake HTTP. Different deployables → explicit remote contract (HTTP/events/gRPC, `../contracts/RULES.md`); **do not invent a mesh early**. In-process ≠ import any internal file. Keep a **public surface** per engine even when physical split is not planned. No HTTP localhost in the same process "so we can split later". No event bus on day one without a real async need.

## Always ask (structural) `[suite-default]`

Always ask: new physical deployable / service (hard to reverse; ops/contract cost); new repo or **monorepo↔multi-repo flip** (tooling/ownership cost); cross-domain rewrite or extract-service refactor (scope explosion); new shared platform package for domain code (couples early); greenfield stack (never autonomous).

May decide: add a **logical** module for a clear new capability; hybrid + framework placement; duplicate a small helper vs shared/.

## Brownfield `[suite-default]`

**Existing layout wins.** No drive-by re-architecture. Follow local package/folder convention. Apply fully on a **new** greenfield app/package/deployable — still ask on physical splits.

## Caching: stale-while-revalidate `[suite-default]`

On miss: compute, store, return. On hit: return immediately. If stale, trigger a background recompute (fire-and-forget). Callers never wait. Short-window staleness. TTLs are named constants. Cache keys encode every parameter they vary by.

## Polling for async job results `[common]`

Poll a background job with a **bounded** loop and an attempt counter. Not recursive sleep. Always have a hard failure path when attempts are exhausted.

## Async job dispatch `[suite-default]`

Dispatch by a **named constant** (enum or string key), not scattered function refs. The key-to-handler mapping is declared in one central place. Each handler lives in its own file, named after what it does.

## When to break `[suite-default]`

Author chooses a different shape. Existing structure is load-bearing — preserve it. Compliance, tenancy, or hard isolation forces early physical splits — document the reason; still prefer clear ownership. Measured operational need (scale, blast radius) justifies a deployable earlier than the logical-first default. Working system and clear ownership beat diagram purity.

## Never

```
✗ scaffold microservices before the engines are named · confuse a folder with a deployable
✗ universal folder template fighting the framework · packages/shared as the domain model
✗ fake in-process HTTP for future extraction · one DB table owned by everyone and no one
✗ multi-repo by default with no reason · rewrite brownfield layout while fixing a bug
✗ pick stacks here instead of the stack guide · localhost-only FE as the production multi-user default
```

## Looks wrong, is intentional `[suite-default]`

**Several logical engines, one deployable** — the default, not a failed microservices plan. **Duplicated helpers** beat a premature shared library. **One Postgres, many owners (by table)** when ownership is explicit. **No monorepo tool (Nx/Turborepo)** on a small multi-package repo until pain appears. **Everything in one frontend** for a truly local tool — not production backends-in-the-browser.

## Done `[suite-default]`

Also: no shared domain platform without repeated pain; table/collection ownership clear if engines share a DB; FE/BE matches stack defaults (or documented tiny localhost exception); in-process public APIs, not fake RPC; **proposed ADR** (`../decisions/RULES.md`) once a new deployable/repo split is approved; protocol scope and ask rules still held.

## Other layers

`../protocol/RULES.md` · `../code-style/RULES.md` · `../stack/RULES.md` · `../data/RULES.md` · `../contracts/RULES.md` · `../release/RULES.md` · `../security/RULES.md` · Standing decisions (ADRs) `../decisions/`
