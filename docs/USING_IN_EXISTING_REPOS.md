# Using LLM Dev Guides in an existing codebase

How to attach this suite to a **brownfield** app (or any consumer repo) so Claude, Codex,
and Grok Build share one law — without rewriting the project to match the guides.

**Read this when:** you already have a product repo and want agents to follow the suite.  
**Not this file:** day-to-day coding rules (open the guides) or greenfield product shape
(architecture + stack).

---

## 1. What you are installing

| Piece | Role |
|---|---|
| **`guides/`** | Shared law (protocol, style, stack, data, API, obs, test, security, release, ADRs) |
| **`AGENTS.md`** | Canonical shared map. Install this in every consumer repo. |
| **`CLAUDE.md`** | Claude-only import wrapper (`@AGENTS.md` + mechanics). Not a second map. |
| **Optional STATUS** | `docs/agent/STATUS.md` for multi-tool / multi-session WIP (protocol) |

`AGENTS.md` is the **map**. It must not restate code-style / stack. `CLAUDE.md` must not restate `AGENTS.md`.  
`python3 scripts/gen-adapters.py` only regenerates files **in this suite**. It is not a consumer installer.  
**Local existing code always wins** over guides when they conflict on brownfield work
(implementation convention).

```
org/platform policy > current-task human > project/path instructions > adopted suite > user-global > third-party skills (except vendor API how-to) > model taste

approved task design > nearest file > package > repository > suite default
```

Do **not** use adoption as a license to re-architecture the tree to match architecture mid-feature.

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

- `guides/protocol/` + `guides/orchestration/` and the other `guides/` domains
- `guides/decisions/` (process + any accepted ADRs)
- Prefer the whole suite so routing tables and cross-links resolve.

You do **not** need this suite’s own root maps inside the app — those are for working
*on* the suite itself. Copy the **consumer** templates from `adapters/`.

---

## 3. Install tool adapters

From this suite’s `adapters/` (see also `adapters/README.md`). Always install the shared
map. Add the Claude wrapper only if the app uses Claude Code.

| Tool | Copy from | Install as (app root) |
|---|---|---|
| All tools | `adapters/claude/AGENTS.md` (byte-identical to `adapters/codex/` and `adapters/grok/`) | `AGENTS.md` |
| Claude Code | `adapters/claude/CLAUDE.md` | `CLAUDE.md` (`@AGENTS.md` + Claude mechanics) |
| Codex | *(uses the same `AGENTS.md`)* | — |
| Grok Build | *(uses the same `AGENTS.md`)* | — |

```bash
# example from app root, suite as sibling
cp ../LLM-dev-guides/adapters/claude/AGENTS.md ./AGENTS.md
# Claude Code only — not a second map
cp ../LLM-dev-guides/adapters/claude/CLAUDE.md ./CLAUDE.md
```

Then edit **`AGENTS.md` only**:

1. Set `GUIDES_ROOT` to the path from §2.  
2. Fill **Exact commands** with this app’s real test / lint / build / dev commands.  
3. Add **project-only facts** that are not in the guides (currency rules, “never hit live DB in
   tests”, path map) — short bullets, not a second style guide.  
4. If a rich `CLAUDE.md` already exists, **merge**: move shared commands and facts into
   `AGENTS.md`; leave `CLAUDE.md` as `@AGENTS.md` plus Claude-only mechanics; delete
   duplicated style essays that now live in `guides/code-style/`.

Grok also loads `CLAUDE.md` if present. That file is Claude mechanics plus an import
Grok does not expand. Grok’s law is `AGENTS.md` — do not copy suite law into `CLAUDE.md`
to “keep them in sync.”

**Claude Code only (optional but recommended):** install the pointer-skills and
enforcement hooks from `adapters/claude/skills/` and `adapters/claude/hooks/` (see each
README). Skills route tasks to the right domain guide automatically; hooks enforce STATUS
reading, branch isolation, and the test gate mechanically.

---

## 4. Brownfield rules (read before first agent session)

| Do | Don’t |
|---|---|
| Follow **existing** layout, stack, and API style | Rewrite to Nest/Vite/etc. because stack prefers it |
| Apply code-style smell to **code you touch** | Drive-by refactors across the repo |
| Use data/release for **new** migrations | One-shot break prod schema without expand/contract |
| Use testing for new logic / bugfixes | Demand full coverage rewrite day one |
| Ask on greenfield-in-brownfield (new service, new auth) | Autonomous new deployable (architecture/protocol) |

Existing weirdness is law until you deliberately change it with a plan (and ADR if
hard-to-reverse — decisions).

---

## 5. Optional but useful

### Multi-tool handoff

Create `docs/agent/STATUS.md` when work spans sessions or tools (Grok ↔ Claude ↔ Codex).
Mandatory sections (protocol): Goal, Done, Next, Do not touch, Open questions.

### Git flow and parallel agents

`guides/orchestration/RULES.md` defines **team-style** flow for this suite: feature branch from
`develop` (else `main`), small PRs, delete branch after merge, human merges base, conflicts
via rebase + understand the other side. Parallel agents get **one branch/worktree each**;
**serialize** lockfiles and migration chains. See orchestration: *Team-style git flow*,
*Parallel agents and subagents*, *Orchestrator checklist*, *Subagent brief and result
templates*.

**Orchestrator / delegation:** the root parent loads protocol fully; every **write** child must
be briefed with `GUIDES_ROOT`, protocol (or equivalent), owned paths, decisions already made, and
“escalate always-ask to parent.” Nested children escalate to their **direct** spawner only;
only the root asks the human. Hard items (destructive data, new auth, new deployable,
product ambiguity) must not be rubber-stamped by a parent.

Project may override base branch names in its adapter if different.

### App-local ADRs

Product-specific standing decisions → e.g. `docs/adrs/` in the app (decisions).  
Author-global law stays in this suite’s `guides/decisions/`.

### Permissionless tools

If you run Claude/Codex/Grok without permission prompts, that does **not** skip protocol ask
list (stack, schema breaks, security, scope expansion) or release “human ships prod.”

---

## 6. First-session checklist (existing repo)

- [ ] Suite available at a stable path (`GUIDES_ROOT`)  
- [ ] `AGENTS.md` installed and filled  
- [ ] If using Claude Code: `CLAUDE.md` installed as `@AGENTS.md` wrapper (not a second map)  
- [ ] Exact commands match this app (test/lint/build)  
- [ ] Existing project rules merged, not clobbered  
- [ ] Agent told (via `AGENTS.md`) to open protocol then only relevant guides  
- [ ] No expectation of full architecture re-layout  
- [ ] Optional: `docs/agent/STATUS.md` template  
- [ ] Optional: point humans at this file in the app README  

### Smoke test

Ask the agent (any tool):

> Read AGENTS.md (and CLAUDE.md if present) and protocol. Summarize conflict order, which guide
> you open for a schema migration, and what a subagent does on an always-ask item. Do not
> edit code.

Expect: local code > guides; data + release (and code-style for code shape); destructive → ask human (root)
or escalate to parent (subagent); parallel writers isolated.

---

## 7. Keeping guides updated

| Attachment | Update path |
|---|---|
| Sibling / absolute path | `git pull` in the suite repo |
| Submodule | bump submodule commit in the app |
| Vendored copy | re-copy or merge from suite main |

When guides change, **consumer adapters usually need no edit** unless entrypoints or ritual
change. Do not paste new code-style rules into `AGENTS.md` or `CLAUDE.md`. Regenerating
adapters is a suite-maintainer step (`python3 scripts/gen-adapters.py --write` in this
repo), not an app-update step.

---

## 8. Minimal vs full adoption

| Level | What you do |
|---|---|
| **Minimal** | Adapters + `GUIDES_ROOT` + protocol / code-style / stack / testing for daily work |
| **Standard** | Full `guides/` path readable; STATUS when multi-tool |
| **Full** | + app ADRs, expand/contract discipline, observability bar, security on every sensitive change |

Start minimal if needed; agents still must not invent a second style system for domains
covered by a guide they can open.

---

## 9. Pointers

| Doc | Use |
|---|---|
| `README.md` | Suite index / which guide for which task |
| `guides/protocol/RULES.md` | Bootstrap, ask vs decide, done, handoff |
| `guides/orchestration/RULES.md` | Git flow, parallel agents, subagent briefs |
| `adapters/README.md` | Adapter copy rules and permissionless notes |
| `guides/decisions/RULES.md` | When to write ADRs |
| App’s own `AGENTS.md` | Commands + project facts |
| App’s own `CLAUDE.md` | `@AGENTS.md` + Claude mechanics only |

---

## Anti-patterns

```
✗ copy all of code-style into AGENTS.md or CLAUDE.md
✗ GUIDES_ROOT wrong so agents invent rules from memory
✗ “adopt guides” PR that renames half the monorepo to match architecture
✗ restating AGENTS.md law inside CLAUDE.md
✗ installing only CLAUDE.md for Claude (no AGENTS.md for @AGENTS.md to import)
✗ running scripts/gen-adapters.py as a consumer installer
✗ commit real secrets while adding .env.example
✗ expect agents to ignore local code because the guide is newer
```
