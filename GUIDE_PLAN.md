# Plan: LLM Dev Guides (temporary)

**Status:** working plan. Delete this file when the suite is stable and the README is the
only index.

**Goal:** a layered set of agent-facing guides that match the author's native mental
model — not a generic “best practices” library. Agents follow these so output is
consistent with how the author would have written and decided.

**Multi-tool requirement:** this repo is not Claude-only. The author will use **Claude**,
**Codex**, and **Grok Build** (and possibly others later) on the same projects. Shared
law lives in the L0–L10 guides; **tool-specific adapters** are first-class deliverables
so each agent loads the same truth through its native entry file. Adapters stay thin —
they must not fork style or stack rules.

**Method:** one guide at a time. For each guide after L1:

1. Consult the author (questions + options, no draft yet).
2. Capture answers in this plan (or a short notes block).
3. Draft the guide in the author's voice (✓/✗, decision trees, anti-patterns, when to break).
4. Author reviews; revise until it feels native.
5. Mark the layer **done** below; move to the next.

L1 already exists as a proof of concept and is the template for tone and structure.

---

## Suite layout (L0–L10)

**File naming:** `L{n}_{SNAKE_NAME}.md` (or `L10_DECISIONS/` for the ADR directory).
Underscores only — no spaces in paths.

| Layer | File | Job | Status |
|---|---|---|---|
| L0 | `L0_AGENT_PROTOCOL.md` | How agents work in any repo that uses these guides: scope, when to open which guide, ask vs decide, definition of done | **v1** |
| L1 | `L1_CODING_STYLE.md` | Day-to-day shape of code, smells, post-code check | **v1** |
| L2 | `L2_PROJECT_BOOTSTRAP.md` | Greenfield: layout, domain/engine split, when a new service is allowed | **v1 draft** (author review) |
| L3 | `L3_LANGUAGE_AND_FRAMEWORK.md` | Per-stack defaults, allowlists, error model, bans | **v1** |
| L4 | `L4_DATA_MODEL.md` | Schema, migrations, invariants, keys, nullability, money/time | **v1 draft** (file on disk; author review / plan notes backfill) |
| L5 | `L5_API_AND_CONTRACTS.md` | HTTP/events/DTOs, versioning, error shapes, idempotency | not started |
| L6 | `L6_OBSERVABILITY.md` | Logs, metrics, traces, DB health / slow queries / pools | not started |
| L7 | `L7_TESTING.md` | What to test, factories, flake policy, unit vs integration | not started |
| L8 | `L8_SECURITY_AND_SECRETS.md` | Auth boundaries, PII, secret handling | not started |
| L9 | `L9_CHANGE_AND_RELEASE.md` | Expand/contract migrations, flags, rollback, deploy safety | not started |
| L10 | `L10_DECISIONS/` (ADRs) | Long-lived “why we chose X”; one file per decision | not started |

### Tool adapters (first-class, not optional)

**Job:** thin, tool-native entry files that bootstrap each agent into the shared L0–L10
suite. **No second style system.** Adapters point at guides; they do not restate L1/L3.

| Adapter | Planned location | Tool | Status |
|---|---|---|---|
| Claude | `adapters/claude/` (`CLAUDE.md` + `NOTES.md`) | Claude Code | **v1** |
| Codex | `adapters/codex/` (`AGENTS.md` + `NOTES.md`) | OpenAI Codex | **v1** |
| Grok Build | `adapters/grok/` (`AGENTS.md` + `NOTES.md`) | Grok Build | **v1** |

**Rules for adapters:**

1. **Single source of truth** — coding style, stack, data, testing live only in `L*.md`.
2. **Thin map** — each adapter: how to load the suite, which file is the entrypoint, exact
   commands pattern, handoff pointer, “do not invent a parallel guide.”
3. **Tool-only mechanics stay in the adapter** — hooks, path-scoped auto-load, MCP names,
   CLI flags, config paths (`~/.claude`, `~/.codex`, Grok config). Not in L1–L10.
4. **Same conflict order** as L0 (local code > these guides > model taste).
5. **Consuming repos** copy or symlink adapter templates into their root (`CLAUDE.md`,
   `AGENTS.md`, etc.); this repo is the canonical template source.

Optional later (not in the core suite until needed):

- `examples/` — golden paths from real code
- `templates/` — ADR template, migration checklist
- adapters for other tools (Cursor, Gemini, …) only if the author actually uses them

---

## Design principles (all guides)

Copy what worked in L1:

1. **Ranked priorities or a clear job statement** at the top (why this file exists).
2. **Decision trees and defaults**, not essays.
3. **✓ / ✗ examples** with short rationale.
4. **Anti-patterns** and **intentional patterns that look like mistakes**.
5. **When to break the rules**.
6. **Scope boundary** — what this guide does *not* cover (pointer to another L).
7. **Done checklist** for work in that domain (where applicable).

Cross-cutting conflict order (**encoded in L0**; skills tier included):

```
local codebase convention  >  these guides (L0–L10)
third-party skills         >  model default taste
  (skills may win only on pure vendor API usage; stack/style stay with guides)

working behavior           >  style purity
smallest change that ships >  drive-by improvement
```

---

## Writing order

### Historical (what actually shipped)

| Order | Layer | Status |
|---|---|---|
| 1 | L1 Coding Style | **v1** |
| 2 | L3 Language & Framework | **v1** |
| 3 | L0 Agent Protocol (+ multi-tool consult) | **v1** |
| 4 | Tool adapters (Claude, Codex, Grok) | **v1** |
| 5 | L4 Data Model | **v1 draft** on disk (ahead of original order; needs author sign-off) |

### Forward (from here)

| Order | Layer | Why |
|---|---|---|
| **now** | **L2 Project Bootstrap** | **v1 draft** — author review |
| next | L4 author sign-off | Mark **v1** after review; optional small fixes from L4 review |
| then | L7 Testing | Agents over/under-test without an explicit bar |
| then | L5 API & Contracts | Natural after domain + data shape |
| then | L6 Observability | Includes DB health |
| then | L9 Change & Release | Migrations + deploy safety after schema rules exist |
| then | L8 Security & Secrets | When auth/PII pain appears or before public APIs |
| then | L10 Decisions | Standing process; first ADRs as real choices are recorded |

Order can change if the author prioritizes a pain point.

**Process rule (current):** do not draft a new layer until that layer’s consult is started
and answers are captured in this plan. **Exception already taken:** L4 was drafted with a
full file before plan notes; treat as **v1 draft** pending author review, not as a license
to skip consult on L2+.

---

## Workflow per guide (author-native)

```
Consult  →  Notes in this plan  →  Draft guide  →  Author review  →  Revise  →  Mark done
```

**Consult means:** the agent asks what the author already believes, what is non-negotiable,
what was learned from production pain, and what is explicitly out of scope. No full draft
until the author has answered enough that the draft can sound like them.

**Draft means:** same density as L1. Prefer shorter docs with hard rules over long tutorials.

**Delete this plan when:** L0–L9 have v1 text, L10 has a template + at least one real ADR
(or an empty `L10_DECISIONS/README.md` explaining the format), **Claude / Codex / Grok Build
adapters have v1 templates**, and `README.md` is the sole index.

---

## L1 — notes (done)

- Source: distilled from author's codebase; proven for daily maintenance / smell.
- Added: scope (any coding, including greenfield code; domain division out of scope),
  definition of complete, post-code check (tests not worse, never out-of-scope changes).
- Domain separation deferred to L2.

---

## L3 — Language & Framework (current)

**Job:** per-stack defaults so agents do not invent frameworks, mix error models, or pick
stacks alone. Not a language tutorial. **Greenfield stack choice is never autonomous**
unless the author explicitly overrides.

**Status:** **v1** in `L3_LANGUAGE_AND_FRAMEWORK.md`.

### Author answers (2026-07-11)

#### Readable / in-scope languages

TypeScript, Rust, Kotlin, Java, Solidity, Go, Python.

#### Known frameworks / infra (capability, not endorsement)

- Frameworks: NestJS, ExpressJS, Spring Boot, Hardhat, React, Vue, Angular, BullMQ, RabbitMQ
- Storage: Postgres, MongoDB, Redis

#### Framing correction

“Default framework” is the wrong question. Choice is **use-case → language → then
framework (or none)**. No universal “always Nest / always Spring.” Some choices are still
actively opposed (see below).

#### Language verdicts

**TypeScript**
- Default for most greenfield; **must** on frontend.
- Write in **OOP** style; rely on strong typing. `:any` and ignored quality skew the
  codebase over time.
- Weak for serious calculation and parallelism (event loop / V8 / Node).
- **Worker threads in TS/JS are already the wrong design** if parallelism is foreseeable —
  pick another language up front.

**Rust**
- Prefer when cutting-edge efficiency, speed, memory safety matter.
- Mental model is **FP-oriented; do not force OOP**.
- Compile time usually fine; author does not foresee massive apps where it dominates.

**Kotlin**
- Intended long-term replacement for much of what people default to TypeScript for on
  backends: syntax and mental model close to TS.
- Drawback: not dynamic; JVM ecosystem — JS libraries need JVM equivalents (research cost).

**Java**
- Stable, legacy-bloated; strongest when **business-logic stability** matters more than
  Rust-class perf/memory pressure.
- Practical role: modules in a Spring Boot project when a **Java dependency** is painful
  to consume from Kotlin — fall back to Java and import natively.

**Solidity**
- Required for EVM work. No alternative discussion.

**Go**
- Second choice after Rust when speed/systems needs matter but Rust is too harsh, and
  Kotlin is not the right fit.
- Also compelling for **small services** when a **Go-only SDK** is the driver.

**Python**
- **Scripting**, **ML**, or **mass data massage** only.
- Against for general application services: hard to read in long human context; ecosystem
  conventions often fight clear structure.

#### Frontend

- **React** unless strong reason for Vue or Angular (popularity/ecosystem, not technical
  superiority).
- Prefer **TanStack + Vite** style tooling over treating **Next.js SSR** as the universal
  good default. SSR is not universally justified.
- **Against serverless backends** (e.g. Next.js API/backend as the app backend):
  non-singleton nature causes more problems than it solves. Rare cases may still fit.

#### Backend (TS / JVM)

- TS backend: **NestJS** favored when a framework is used — highly opinionated, analogous
  to Spring Boot on Kotlin/Java.
- Express known but not the opinionated default.
- Kotlin/Java: **Spring Boot** as the known heavy backend shape.
- Framework optional where language culture is “stdlib + small libs” (e.g. many Go/Rust
  services).

#### Storage

- **Postgres**: almost always the relational default; only rare niche loses.
- **MongoDB**: only when data is truly dynamic / document-oriented.
- **Redis**: cache and/or loose inter-service communication in a microservice setup.

#### Decision tree (suggestions only — always consult on greenfield)

Order: **language first → framework (or none) → storage by data nature**.

1. Computation-heavy or parallelism needed → **avoid TypeScript, Perl, Python entirely**.
2. Execution speed very critical → **Rust** preferred, **Go** second.
3. Heavy OOP backend → **Kotlin** preferred; **Java** only when needed (deps / stability).
4. Python only for scripting, ML, or mass data massage.
5. EVM → Solidity (Hardhat in known toolchain).
6. Frontend UI → React default; Vue/Angular only with good reason; prefer TanStack + Vite
   over defaulting to Next SSR; no serverless backend by default.
7. DB: Postgres almost always; Mongo only if unstructured/document-shaped; Redis for
   cache or loose service comms.

**Hard process rule:** greenfield stack selection is **never autonomous**. Agent proposes
using the tree above; author decides — unless author explicitly says to proceed without
asking.

#### Errors (vs L1)

- L1’s “raise where detected” still has merit for unexpected failures.
- **Expected** outcomes are not errors — model them as normal control flow.
- Prefer **language convention** over fighting it (Go `error`, Rust `Result`, etc.).
  L3 overrides L1 where language idiom conflicts with “always throw.”

#### Packages / tools

- Complexity-dependent: **ask** whether author wants to dictate specific packages.
- TypeScript package manager: **always npm**.
- Strict mode, formatter, linter: **required when the ecosystem supports them**.
- Nothing universally banned or mandatory beyond the above; **slight doubt → ask**.

#### Layout

- Follow **language/framework common practice**, not a personal global folder standard.

#### Data access

- **Postgres: ORM preferred**.
- **Mongo: native queries**.
- L1 §19 (CRUD wrappers + direct client for complex queries) **still true**.

#### Mental model vs monorepo

- **Mental model first** (how the solution is thought).
- Multiple stacks or monorepo both fine depending on the solution being built.

### Draft notes

- File: `L3_LANGUAGE_AND_FRAMEWORK.md` (**v1**)
- Challenge-response incorporated:
  - TS default vs Kotlin direction: intentional tradeoff; port later (incl. AI) accepted
  - Rust: structs/impl/traits, not “pure FP”
  - Worker threads: absolute on greenfield plan only; day-to-day prefer horizontal
    stateless TS; not absolute in brownfield
  - Serverless: glue only; ~30-line glue → Express
  - Next: greenfield only if really justifiable; never rewrite existing for taste
  - **No business logic in DB / no SQL functions for domain — NEVER**
  - Greenfield hard ban list explicit (Python app, TS-for-CPU-stall, serverless core,
    npm+Node)
  - Go: rare; Express-or-Rust covers most motivation
  - Java: Kotlin + thin interop first
  - Consult only greenfield/new stack; else continue existing weirdness
  - Parallelism = CPU-bound / event-loop stall, not I/O concurrency
  - Layout: LLM/framework judgment for now; per-framework sub-guides later

---

## Layer notes (by status)

When starting a layer: add **Author answers** here (same pattern as L0/L3). Do not draft
L2, L5–L10 until that layer’s consult is started. L0/adapters/L4 already have files.

### Tool adapters (Claude, Codex, Grok Build) — v1 (done)

**Status:** **v1** under `adapters/` + suite root `CLAUDE.md` / `AGENTS.md`.

- Thin maps only; permissionless assumed; shared `AGENTS.md` for Codex + Grok
- See `adapters/README.md`

### L0 Agent Protocol — v1 (done)

**Status:** **v1** in `L0_AGENT_PROTOCOL.md` (consult 2026-07-13; goal blurb dropped).

Summary of law: router only; conservative ask; standard done bar; thin adapters; STATUS at
`docs/agent/STATUS.md`; skills lose on stack/style. Full answers remain above in git
history / see file itself for the protocol.

#### Author answers (2026-07-13) — kept for archive

| Topic | Choice |
|---|---|
| Job | Router + protocol only |
| Ask vs decide | Conservative |
| Done | Standard |
| Entry | Thin adapters → L0 |
| Skills | Guides win except pure vendor API how-to |
| Handoff | `docs/agent/STATUS.md` + PR |
| Bootstrap | Adapter → L0 → L\* → STATUS if present |
| Drive-by | Hard ban |
| Plan | Non-trivial only |
| Density | L1-like |

### L4 Data Model — v1 draft (file exists; sign-off pending)

**Status:** full draft in `L4_DATA_MODEL.md` (appeared before plan notes). **Not** “not
started.”

- Author should review for voice; optional follow-ups from review: destructive = L0 ask,
  `timestamptz` default, append-only/ledger pattern, soft-delete uniqueness example
- No formal consult block was captured before draft — treat review as the sign-off step
- After accept: mark **v1** here and in README

### L2 Project Bootstrap — v1 draft (2026-07-13)

Greenfield layout, domain/engine split, when a new service is allowed. Stack *choice*
stays **L3**; data shape **L4**.

#### Author answers (2026-07-13) — rounds 1–3

| Topic | Choice |
|---|---|
| **L2 job** | Greenfield layout + domain split only |
| **System shape** | No universal monolith-first; depends on product |
| **Thinking order** | Engines/services needed → mental model → layout → L3 stack per piece |
| **Engine vs service** | Logical engines/modules vs physical deployables; logical first |
| **New deployable** | Propose when boundary clear; **always ask** before scaffold |
| **Boundary reasons** | Scale/failure/data ownership; team/cadence; different runtime (L3) — none auto-approve |
| **Domain separation** | Hybrid: top-level by capability; framework layers inside |
| **Folders** | Principles only |
| **Monorepo** | Case by case; ask when it matters |
| **Shared code** | Prefer duplication over shared libs |
| **Data ownership** | One DB OK with clear table ownership; separate DB when deployable/isolation needs it |
| **In-process talk** | Direct module/public API calls; no fake HTTP inside one process |
| **FE/BE** | Separate apps by default (L3); tiny localhost-only may be FE-only |
| **Brownfield** | Follow local layout; no drive-by re-architecture |
| **Density** | L1-like + structural ask list |

#### Draft notes

- File: `L2_PROJECT_BOOTSTRAP.md` — **v1 draft** for author voice review

### L5 API & Contracts — consult later

HTTP/events/DTOs, versioning, errors at the wire.

### L6 Observability — consult later

Logs/metrics/traces + DB health.

### L7 Testing — consult later

What/how to test; factories; flakes.

### L8 Security & Secrets — consult later

Auth, PII, secrets.

### L9 Change & Release — consult later

Flags, expand/contract, rollback.

### L10 Decisions — consult later

ADR format and when to write one.

---

## README role

`README.md` should become a **router**: which guide for which task. Keep it short. Full
rationale lives in each L-file. Until the suite is done, README can point at this plan.

---

## Definition of done for the suite (then delete this plan)

- [x] L0 **v1**
- [x] L1 **v1**
- [x] L3 **v1**
- [x] **Adapters v1** (Claude, Codex, Grok — thin; point at L\*)
- [ ] L4 author accepts as **v1** (draft on disk)
- [ ] L2 author accepts as **v1** (draft on disk)
- [ ] L5–L9 each have a v1 the author accepts as “sounds like me”
- [ ] L10 has format + process (and ideally one real decision)
- [ ] README routes tasks → layers **and** which adapter to install for which tool
- [ ] Cross-links between guides are consistent (L1 ≠ domain split; L3 = stack; L4 = data; etc.)
- [ ] Delete `GUIDE_PLAN.md`
