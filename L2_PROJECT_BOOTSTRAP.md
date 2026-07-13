# L2 — Project Bootstrap

How to shape a system: which engines exist, how they sit in a mental model, where code
lives, and when a new deployable is justified.

**The goal:** agents stop inventing folder religions, premature microservices, or “shared
platform” packages on day one. Structure should follow the product’s real engines — not a
universal template and not whatever framework demo the model remembers.

## Scope of this guide

**In scope**

- Greenfield thinking order (engines → model → layout → stack)
- Logical engines/modules vs physical deployables
- Domain/capability cuts and hybrid folder principles
- When to propose a new service, package, or repo
- Shared code policy (prefer duplication)
- Data ownership across engines
- Frontend vs backend placement defaults
- Brownfield: do not re-architecture on touch

**Out of scope**

| Concern | Where it lives |
|---|---|
| Language / framework / storage **choice** | **L3** |
| Schema, invariants, migrations | **L4** |
| HTTP/events/DTO wire contracts | **L5** |
| Day-to-day code shape | **L1** |
| Agent protocol, ask vs decide, handoff | **L0** |
| CI, deploy pipeline, flags, rollback choreography | **L9** |
| Auth/PII product rules | **L8** |

L3 answers “what stack.” L2 answers “what pieces exist and how they are arranged.”  
Greenfield stack selection remains **never autonomous** (L3 + L0).

## What “complete” means

A bootstrap or structural change is complete when:

1. The **mental model** (engines and their jobs) is stated, not only a folder tree.
2. **Logical** vs **physical** boundaries are not confused.
3. Layout follows **hybrid** cuts (capability outside, framework layers inside) or the
   existing repo’s local convention in brownfield.
4. Any **new deployable, multi-repo split, or cross-domain rewrite** was **approved** by
   the author (or explicitly out of scope).
5. Stack for each piece was chosen via **L3** (consult on greenfield), not invented in L2.

Complete does **not** mean a perfect monorepo, shared library platform, or future-proof
service mesh.

---

## 1. Thinking order (greenfield)

Always in this order:

```
1. What engines / capabilities does the product need?
2. Mental model — how those pieces relate (who owns what, who calls whom)
3. Layout — where code lives (modules, packages, apps)
4. Stack per piece — L3 (language → framework → storage), with author confirm on greenfield
```

```
✓  “We need a pull engine, a ledger, a shipping workflow, and an admin UI” → model → layout → stacks
✓  Very small localhost tool → one FE app may hold everything (see §7)
✗  “Scaffold Nest + Next + Redis + five services” before naming the engines
✗  Pick folders from a viral monorepo template, then invent domains to fill them
✗  Choose Kotlin vs TS as the first step without knowing what is being built
```

There is **no universal “monolith first” or “services first.”** Shape depends on the
product. The constant is: **start from engines and the mental model**, not from tooling.

---

## 2. Logical engine vs physical deployable

These are different ideas. L2 requires both words to stay distinct.

| Term | Meaning |
|---|---|
| **Logical engine / module** | A capability with a clear job and ownership (pricing, ledger, inventory, auth). May live **inside** one process. |
| **Physical deployable / service** | Something that is built, shipped, scaled, or failed **on its own** (separate process, package, or repo). |

**Default:** split **logically** first (modules with clear public surfaces).  
**Physical** deployables need a **clear boundary reason** and **author approval** before
scaffold.

```
✓  ledger/ and shipping/ modules in one API process; in-process calls between them
✓  Propose a separate worker deployable because pull load must scale alone — wait for yes
✗  New Git repo + HTTP API for every noun in the product brief
✗  Call it a “service” when it is only a folder with no deploy boundary
```

---

## 3. When a new deployable may be proposed

An agent may **propose** a new deployable (or multi-repo cut) when **at least one** holds:

| Reason | Example signal |
|---|---|
| Different scale, failure mode, or data isolation need | CPU-heavy worker vs latency-sensitive API; store that must not share fate |
| Different team or release cadence | Independent ship schedule that a modular monolith cannot absorb |
| Different language/runtime required | L3 forces Rust/Go/Kotlin beside a TS app |

**None of these auto-approve.** Scaffolding a new service, package boundary that is a
de-facto product split, or new repo is an **L0 always-ask** structural move.

```
✓  “Boundary: ledger must not share failure domain with marketing site — propose separate deployable?”
✗  Create services/foo and wire gRPC because clean architecture diagrams look that way
✗  Split “for testability” when modules and tests would suffice
```

---

## 4. Hybrid layout (principles only)

L2 does **not** prescribe a universal folder tree. Follow **language/framework common
practice** (L3) inside each piece.

**Hybrid rule:**

1. **Top level by business capability / engine** (or by app: `web/`, `api/` when those are
   the real products).
2. **Inside** a capability, use framework-idiomatic layers (controllers, services,
   repositories, etc. as that stack expects).

```
✓  billing/…, inventory/…, each with internal layers the framework expects
✓  apps/web + apps/api when FE and BE are separate products (default when both exist)
✗  Only top-level controllers/, services/, repositories/ as the primary cut for a multi-domain system
✗  Copy a Nest/Spring demo tree and force every domain into technical buckets only
✗  Invent a house-wide folder standard that fights the framework
```

Monorepo vs multi-repo: **no default.** Choose case by case; **ask** when the choice is
structural (new repo, new package graph, new deploy pipeline).

---

## 5. Prefer duplication over shared libraries

Do **not** start a `packages/shared` platform for domain types, utils, and “common
services.”

```
✓  Duplicate a small helper in two modules until the third copy hurts
✓  Thin, boring infra only when the stack already expects it (e.g. single logging setup in one app)
✗  shared/ with User, Money, Order, and half the product on day one
✗  Deep imports across domain internals (billing reaching into inventory’s private tables/modules)
```

When sharing becomes unavoidable, share the **smallest** surface (often a type or pure
function), not a domain service layer. Prefer **explicit contracts** later (L5) over a
grab-bag shared package.

Cross-domain calls **inside one deployable:** use the other module’s **public API**
(functions/types it exports), not its private files.

---

## 6. Data ownership

**One database is OK** for multiple logical engines when **table (or collection) ownership
is clear**.

- Each engine owns its tables; others read/write only through that engine’s public module
  API (or defined read paths), not by sprinkling foreign updates everywhere.
- **Separate database** when a **physical** deployable split or real isolation need
  requires it — not as an aesthetic default.

Schema rules and migrations: **L4**. L2 only requires ownership clarity in the mental
model.

```
✓  pulls and ledger tables owned by their modules; clear who may write
✓  One Postgres for the modular API until a worker genuinely needs isolation
✗  Every engine gets its own DB “for microservices purity” with no deploy split
✗  Any module UPDATEs any table ad hoc with no owner
```

---

## 7. Frontend and backend

Align with **L3**:

- Prefer **separate apps** when there is a real UI and a real backend.
- Prefer **TanStack + Vite**-style frontend defaults over treating Next SSR as universal
  (L3). Do not invent serverless backends as the core (L3).

**Exception:** **very small, localhost-only** projects may keep **everything in the
frontend** (no separate backend app) when that matches the product. That is a conscious
small-tool shape, not the default for multi-user production systems.

```
✓  web/ + api/ for a product with users, auth, and durable data
✓  Single Vite app for a local-only utility with no server
✗  Stuff production domain logic into Next API routes as the system backend (L3 ban)
✗  Force a separate backend for a one-file local script
```

---

## 8. How engines talk

| Placement | Default |
|---|---|
| Same deployable | **In-process** calls to the other module’s public API |
| Different deployables | Explicit remote contract (HTTP/events/gRPC) — **L5**; do not invent a mesh early |

```
✓  inventory.reserve(…) from checkout module in the same process
✗  HTTP localhost calls between two modules in the same Node process “so we can split later”
✗  Event bus between every domain on day one without a real async need
```

In-process does **not** mean “import any internal file.” Keep a **public surface** per
engine even when physical split is not planned.

---

## 9. Always ask (structural)

In addition to L0’s global ask-list, L2 treats these as **always ask** before doing:

| Move | Why |
|---|---|
| New physical deployable / service | Hard to reverse; ops and contract cost |
| New repo or monorepo↔multi-repo flip | Tooling and ownership cost |
| Cross-domain rewrite or “extract service” refactor | Scope explosion |
| New shared platform package for domain code | Couples everything early |
| Greenfield stack for a piece | L3 — never autonomous |

May decide without asking (inside existing shape):

- Add a **logical** module/folder for a clear new capability in an existing app
- Place files using hybrid + framework convention
- Duplicate a small helper instead of creating shared/

---

## 10. Brownfield

**Existing layout wins.**

- Do not drive-by re-architecture to match this guide.
- Follow local package and folder conventions (L0/L1 scope).
- Apply L2 fully when adding a **new** greenfield app, package, or deployable — still ask
  on physical splits.

```
✓  Fix a bug in the existing tree without renaming the monorepo
✓  New greenfield sibling service only after author approves
✗  Mid-feature: “reorganize into engines as in L2”
```

---

## 11. Anti-patterns

```
✗ scaffold microservices before the engines are named
✗ confuse a folder with a deployable
✗ universal folder template fighting the framework
✗ packages/shared as the domain model
✗ fake in-process HTTP for “future extraction”
✗ one DB table owned by everyone and no one
✗ multi-repo by default with no reason
✗ rewrite brownfield layout while fixing a bug
✗ pick stacks in L2 instead of L3
✗ treat “localhost-only FE app” as the default for production multi-user products
```

---

## 12. Intentional patterns that may look like mistakes

**Several logical engines, one deployable.** Not a failed microservices plan — the default
until a physical reason appears.

**Duplicated helpers across modules.** Preferable to a premature shared library.

**One Postgres, many owners (by table).** Valid when ownership is explicit.

**No monorepo tool (Nx/Turborepo) on a small multi-package repo.** Add tooling when pain
appears; L2 does not require it.

**Everything in one frontend for a local tool.** Allowed when the product is truly small
and local; not a license for production backends-in-the-browser.

---

## When to break these rules

- Author explicitly chooses a different shape for this product.
- An existing codebase’s structure is load-bearing; preserve it.
- Compliance, tenancy, or hard isolation forces early physical splits — still document the
  reason; still prefer clear ownership.
- A measured operational need (scale, blast radius) justifies a deployable earlier than the
  “logical first” default.

Working system and clear ownership beat diagram purity.

---

## Done checklist

- [ ] Engines/capabilities named; mental model stated (even briefly)
- [ ] Logical vs physical boundaries not mixed up
- [ ] Layout is hybrid or matches brownfield local convention
- [ ] No new deployable / multi-repo / cross-domain rewrite without author yes
- [ ] Stacks chosen via L3 (greenfield confirmed)
- [ ] No new shared domain platform package without real repeated pain
- [ ] Table/collection ownership clear if multiple engines share a DB
- [ ] FE/BE split matches L3 defaults (or documented tiny localhost exception)
- [ ] In-process engines use public module APIs, not fake RPC
- [ ] L0 scope and ask rules still held

## Relationship to other layers

| Topic | Layer |
|---|---|
| Protocol, ask vs decide, handoff | **L0** |
| Code shape | **L1** |
| Language, framework, storage choice | **L3** |
| Schema, migrations, invariants | **L4** |
| Wire contracts between deployables | **L5** |
| Release / expand-contract of systems | **L9** |
| Security / secrets | **L8** |
| Standing decisions (ADRs) | **L10** |
