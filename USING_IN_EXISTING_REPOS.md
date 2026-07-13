# Using LLM Dev Guides in an existing codebase

How to attach this suite to a **brownfield** app (or any consumer repo) so Claude, Codex,
and Grok Build share one law — without rewriting the project to match the guides.

**Read this when:** you already have a product repo and want agents to follow L0–L10.  
**Not this file:** day-to-day coding rules (open the L\* guides) or greenfield product shape
(L2 + L3).

---

## 1. What you are installing

| Piece | Role |
|---|---|
| **L0–L10** | Shared law (protocol, style, stack, data, API, obs, test, security, release, ADRs) |
| **Adapters** | Thin tool entry files (`CLAUDE.md`, `AGENTS.md`) that **point at** the guides |
| **Optional STATUS** | `docs/agent/STATUS.md` for multi-tool / multi-session WIP (L0) |

Adapters are **maps**. They must not restate L1/L3.  
**Local existing code always wins** over guides when they conflict on brownfield work
(L0 conflict order).

```
local codebase convention  >  these guides  >  third-party skills  >  model taste
```

Do **not** use adoption as a license to re-architecture the tree to match L2 mid-feature.

---

## 2. Choose how the consumer sees the guides

Pick one pattern. All work; pick what fits git and team habits.

### A. Sibling clone (simple, local)

```text
~/projects/
  LLM-dev-guides/     ← this suite
  my-app/             ← existing product
    CLAUDE.md
    AGENTS.md
```

In adapters: `GUIDES_ROOT=../LLM-dev-guides`

**Pros:** no vendoring; always pull latest.  
**Cons:** path differs per machine; CI agents need the suite checked out too.

### B. Git submodule

```bash
cd my-app
git submodule add https://github.com/<you>/LLM-dev-guides.git docs/llm-dev-guides
# or vendor/LLM-dev-guides
```

`GUIDES_ROOT=docs/llm-dev-guides` (or your path).

**Pros:** version pinned; reproducible.  
**Cons:** submodule UX; remember `submodule update`.

### C. Vendored copy (subtree or plain copy)

Copy or subtree-merge the suite into e.g. `docs/llm-dev-guides/`.

**Pros:** no extra clone.  
**Cons:** must re-copy/merge when guides change.

### D. Monorepo package

If `my-app` already lives in a monorepo, place the suite as a top-level folder and point
`GUIDES_ROOT` relatively (e.g. `../../LLM-dev-guides` or `packages/llm-dev-guides`).

### What to include

Agents need **read access** to at least:

- `L0_AGENT_PROTOCOL.md` … `L9_CHANGE_AND_RELEASE.md`
- `L10_DECISIONS/` (process + any accepted ADRs)
- Prefer the whole suite so routing tables and cross-links resolve.

You do **not** need this suite’s own root `CLAUDE.md` / `AGENTS.md` inside the app —
those are for working *on* the suite itself.

---

## 3. Install tool adapters

From this suite’s `adapters/` (see also `adapters/README.md`):

| Tool | Copy from | Install as (app root) |
|---|---|---|
| Claude Code | `adapters/claude/CLAUDE.md` | `CLAUDE.md` |
| Codex | `adapters/codex/AGENTS.md` | `AGENTS.md` |
| Grok Build | `adapters/grok/AGENTS.md` | same `AGENTS.md` (share with Codex) |

```bash
# example from app root, suite as sibling
cp ../LLM-dev-guides/adapters/claude/CLAUDE.md ./CLAUDE.md
cp ../LLM-dev-guides/adapters/codex/AGENTS.md ./AGENTS.md
```

Then edit **both** (keep them equivalent maps):

1. Set `GUIDES_ROOT` to the path from §2.  
2. Fill **Exact commands** with this app’s real test / lint / build / dev commands.  
3. Add **project-only facts** that are not in L\* (currency rules, “never hit live DB in
   tests”, path map) — short bullets, not a second style guide.  
4. If a rich `CLAUDE.md` already exists, **merge**: keep project commands and facts; add
   the bootstrap block (read L0 → relevant L\*); delete duplicated style essays that now
   live in L1.

Grok also loads `CLAUDE.md` if present — keep `CLAUDE.md` and `AGENTS.md` in sync.

---

## 4. Brownfield rules (read before first agent session)

| Do | Don’t |
|---|---|
| Follow **existing** layout, stack, and API style | Rewrite to Nest/Vite/etc. because L3 prefers it |
| Apply L1 smell to **code you touch** | Drive-by refactors across the repo |
| Use L4/L9 for **new** migrations | One-shot break prod schema without expand/contract |
| Use L7 for new logic / bugfixes | Demand full coverage rewrite day one |
| Ask on greenfield-in-brownfield (new service, new auth) | Autonomous new deployable (L2/L0) |

Existing weirdness is law until you deliberately change it with a plan (and ADR if
hard-to-reverse — L10).

---

## 5. Optional but useful

### Multi-tool handoff

Create `docs/agent/STATUS.md` when work spans sessions or tools (Grok ↔ Claude ↔ Codex).
Mandatory sections (L0): Goal, Done, Next, Do not touch, Open questions.

### Git flow and parallel agents

L0 defines **team-style** flow for this suite: feature branch from `develop` (else `main`),
small PRs, delete branch after merge, human merges base, conflicts via rebase + understand
the other side. Parallel agents get **one branch/worktree each** — see L0 sections
*Team-style git flow* and *Parallel agents and subagents*. Project may override base branch
names in its adapter if different.

### App-local ADRs

Product-specific standing decisions → e.g. `docs/adrs/` in the app (L10).  
Author-global law stays in this suite’s `L10_DECISIONS/`.

### Permissionless tools

If you run Claude/Codex/Grok without permission prompts, that does **not** skip L0 ask
list (stack, schema breaks, security, scope expansion) or L9 “human ships prod.”

---

## 6. First-session checklist (existing repo)

- [ ] Suite available at a stable path (`GUIDES_ROOT`)  
- [ ] `CLAUDE.md` and/or `AGENTS.md` installed and filled  
- [ ] Exact commands match this app (test/lint/build)  
- [ ] Existing project rules merged, not clobbered  
- [ ] Agent told (via adapter) to open L0 then only relevant L\*  
- [ ] No expectation of full L2 re-layout  
- [ ] Optional: `docs/agent/STATUS.md` template  
- [ ] Optional: point humans at this file in the app README  

### Smoke test

Ask the agent (any tool):

> Read AGENTS.md/CLAUDE.md and L0. Summarize conflict order and which guide you open for a
> schema migration. Do not edit code.

Expect: local code > guides; L4 + L9 (and L1 for code shape); ask on destructive steps.

---

## 7. Keeping guides updated

| Attachment | Update path |
|---|---|
| Sibling / absolute path | `git pull` in the suite repo |
| Submodule | bump submodule commit in the app |
| Vendored copy | re-copy or merge from suite main |

When L\* change, **adapters usually need no edit** unless entrypoints or ritual change.
Do not paste new L1 rules into `CLAUDE.md`.

---

## 8. Minimal vs full adoption

| Level | What you do |
|---|---|
| **Minimal** | Adapters + `GUIDES_ROOT` + L0/L1/L3/L7 for daily work |
| **Standard** | Full L0–L9 path readable; STATUS when multi-tool |
| **Full** | + app ADRs, expand/contract discipline, obs bar (L6), security (L8) on every sensitive change |

Start minimal if needed; agents still must not invent a second style system for domains
covered by a guide they can open.

---

## 9. Pointers

| Doc | Use |
|---|---|
| `README.md` | Suite index / which L for which task |
| `L0_AGENT_PROTOCOL.md` | Bootstrap, ask vs decide, done, handoff |
| `adapters/README.md` | Adapter copy rules and permissionless notes |
| `L10_DECISIONS/README.md` | When to write ADRs |
| App’s own `CLAUDE.md` / `AGENTS.md` | Commands + project facts only |

---

## Anti-patterns

```
✗ copy all of L1 into CLAUDE.md
✗ GUIDES_ROOT wrong so agents invent rules from memory
✗ “adopt guides” PR that renames half the monorepo to match L2
✗ different CLAUDE.md vs AGENTS.md law
✗ commit real secrets while adding .env.example
✗ expect agents to ignore local code because the guide is newer
```
