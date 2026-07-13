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
| L0 | `L0_AGENT_PROTOCOL.md` | How agents work in any repo that uses these guides: scope, when to open which guide, ask vs decide, definition of done | **v1** (goal blurb dropped; author accepted body) |
| L1 | `L1_CODING_STYLE.md` | Day-to-day shape of code, smells, post-code check | **v1** |
| L2 | `L2_PROJECT_BOOTSTRAP.md` | Greenfield: stack choice entry, layout, module boundaries, when a new service is allowed | not started |
| L3 | `L3_LANGUAGE_AND_FRAMEWORK.md` | Per-stack defaults, allowlists, error model, bans | **v1** |
| L4 | `L4_DATA_MODEL.md` | Schema, migrations, invariants, keys, nullability, money/time | not started |
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
| Claude | `adapters/claude/` (templates: `CLAUDE.md`, optional `.claude/rules/` stubs) | Claude Code | not started |
| Codex | `adapters/codex/` (templates: `AGENTS.md`, notes for `~/.codex` if needed) | OpenAI Codex | not started |
| Grok Build | `adapters/grok/` (templates + session bootstrap for Grok Build) | Grok Build | not started |

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

Cross-cutting conflict order (to encode in L0):

```
local codebase convention  >  these guides  >  model default taste
working behavior           >  style purity
smallest change that ships >  drive-by improvement
```

---

## Writing order

| Order | Layer | Why this order |
|---|---|---|
| 1 | L1 Coding Style | Done — template and daily maintenance |
| 2 | **L3 Language & Framework** | Stops stack invention; unblocks greenfield without full L2 |
| 3 | **Tool adapters (Claude, Codex, Grok Build)** | Multi-tool requirement; filenames agreed in L0 consult; **templates still to draft** after L0 review |
| 4 | L0 Agent Protocol | **v1** — body accepted; goal blurb dropped |
| 5 | L4 Data Model | Highest blast radius after code shape |
| 6 | L2 Project Bootstrap | Domain split / layout; depends on knowing stack defaults (L3) |
| 7 | L7 Testing | Agents over/under-test without an explicit bar |
| 8 | L5 API & Contracts | Natural after domain + data shape |
| 9 | L6 Observability | Includes DB health |
| 10 | L9 Change & Release | Migrations + deploy safety after schema rules exist |
| 11 | L8 Security & Secrets | When auth/PII pain appears or before public APIs |
| 12 | L10 Decisions | Standing process; first ADRs as real choices are recorded |

Order can change if the author prioritizes a pain point. Default above stands until then.

**Hard sequencing rule:** do **not** draft L0 until tool-adapter scope is captured in this
plan (author answers below) and adapter layout is agreed. L0 depends on knowing how each
tool is supposed to enter the suite.

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

## Later layers — stubs only until consultation

Do not draft L0, L2, L4–L10, or adapter templates until the author starts that layer’s
consult. When starting a layer, add an **Author answers** block under that layer in this
file (same pattern as L3).

### Tool adapters (Claude, Codex, Grok Build) — plan before L0

**Status:** planned; consult + layout **before** drafting L0.

**Why before L0:** L0 is the shared protocol. It must say “open your tool’s entry file,
then follow this ritual.” That only works if adapters exist as a named deliverable with
agreed entry filenames and non-goals.

#### Intent (author, 2026-07-13)

- This repo must include **specific adapters** for the tools the author will actually use:
  **Claude Code**, **Codex**, and **Grok Build**.
- Goal: switch tools freely without being locked to one product’s instruction format, while
  keeping **one** mental model (the L-guides).
- Adapters are templates shipped from this repo into real projects (or referenced as the
  canonical pattern).

#### Open consult questions (answer before drafting adapters or L0)

1. **Layout:** prefer `adapters/{claude,codex,grok}/` with copy-paste templates, or also
   root-level example files in this repo?
2. **Claude:** how much of `.claude/rules/` and hooks is template vs “leave to each app”?
3. **Codex:** is root `AGENTS.md` the only required surface, or also `~/.codex/AGENTS.md`
   personal defaults?
4. **Grok Build:** current entry mechanism (project instructions file, session preamble,
   config)? Capture whatever is real at draft time — do not invent a fake CLAUDE.md twin.
5. **Handoff:** is a short `STATUS.md` / PR comment the cross-tool continuity mechanism,
   or something else?
6. **Sync rule:** when L1–L10 change, adapters only change if entrypoints/commands change —
   never re-copy style rules into adapters.

#### Draft non-goals (until author overrides)

- No full restatement of L1/L3 inside any adapter.
- No adapter-specific coding style.
- No requirement that all three tools are installed in every environment — only that this
  repo documents how each one should attach when used.

### L0 Agent Protocol — consult in progress (2026-07-13)

How agents open guides, scope discipline, ask vs decide, definition of done across layers.
Must include: multi-tool bootstrap (read adapter entry → L0 ritual → relevant L*), conflict
order, and handoff when switching Claude ↔ Codex ↔ Grok Build.

#### Author answers (2026-07-13) — round 1

| Topic | Choice |
|---|---|
| **L0 primary job** | **Router + protocol only** — how agents start, which guide to open, ask vs decide, definition of done. No style/stack content in L0. |
| **Ask vs decide** | **Conservative** — greenfield stack, new services, schema/API breaks, security, ambiguous product intent → always ask. Day-to-day code shape may follow L1/L3. |
| **Definition of done** | **Standard** — scope respected, relevant guide followed, tests not worse, lint/typecheck if available, short summary of what changed. |
| **Multi-tool entry** | **Thin adapters point at L0** — each tool has a thin entry file; L0 is the shared ritual. No style restated in adapters. |
| **Skills vs guides** | **Guides win except vendor APIs** — stack/style from guides; third-party skill may override only pure vendor API usage patterns. Full hierarchy still: local code > L* > skills (except vendor API how-to) > model taste. |
| **Cross-tool handoff** | **Both STATUS + PR** — STATUS for WIP; PR description when review-ready. |

#### Author answers (2026-07-13) — round 2

| Topic | Choice |
|---|---|
| **Bootstrap** | Adapter → L0 → relevant L* → **STATUS if present** → then edit. |
| **Guide routing** | **Short routing table only** in L0. Missing layer = do not invent rules; ask or follow local code. |
| **Scope / drive-by** | **Hard ban** — no unrelated files, no “while I’m here,” no task expansion without asking. |
| **STATUS location** | Not repo root — **`docs/` or `.agent/STATUS.md`** (exact path still TBD in round 3). |
| **L0 density** | **L1-like** — rules, ✓/✗, anti-patterns, when to break; still no style/stack. |
| **Adapter filenames** | **CLAUDE.md + AGENTS.md + Grok note** — Claude: `CLAUDE.md`; Codex: `AGENTS.md`; Grok: `AGENTS.md` and/or short project instruction pointing at L0. |

#### Author answers (2026-07-13) — round 3

| Topic | Choice |
|---|---|
| **STATUS path** | **`docs/agent/STATUS.md`** |
| **Missing layer** | Follow **local code** + **ask if high-impact** (conservative ask-list). Do not invent house rules. |
| **Plan before code** | **Only if non-trivial** — multi-file, design choice, or unclear scope → ≤5 bullet plan first. Trivial one-file can skip. |
| **STATUS mandatory fields** | Goal, Done, Next, Do not touch, Open questions. (Not required: verify commands, tool last used.) |
| **L0 v1 scope** | **Nothing else** — ready to draft from these answers. |

#### Draft notes

- File: `L0_AGENT_PROTOCOL.md` — **v1** from rounds 1–3; no style/stack content; no separate
  “The goal” section (opening paragraph is job-only).
- Adapters remain next deliverable; L0 references thin entry files by name.

### L2 Project Bootstrap — consult later

Greenfield layout, domain boundaries, monolith-first rules.

### L4 Data Model — consult later

Schema, migrations, invariants.

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

- [ ] L0–L9 each have a v1 the author accepts as “sounds like me”
- [ ] L10 has format + process (and ideally one real decision)
- [ ] **Adapters v1:** Claude, Codex, and Grok Build templates exist and stay thin (point at L*; no forked style)
- [ ] README routes tasks → layers **and** which adapter to install for which tool
- [ ] Cross-links between guides are consistent (L1 does not own domain split; L3 owns stack defaults; etc.)
- [ ] Delete `GUIDE_PLAN.md`
