# L10 — Decisions (ADRs)

How and when to record **standing decisions** so agents and future-you do not re-litigate
hard-to-reverse choices.

Durable “why we chose X” lives in short ADRs — not only in chat history or scattered PR
descriptions.

## Scope

**In scope**

- When an ADR is required or encouraged
- Short ADR format and lifecycle (status)
- Where ADRs live (this suite vs application repos)
- How agents draft; how the author accepts

**Out of scope**

- Day-to-day implementation choices (L1–L9 cover those)
- Replacing product specs or tickets
- A complete historical archive of every past project (backfill only when useful)

## Relationship to other layers

| Situation | Use |
|---|---|
| How to code / ship / secure | **L0–L9** |
| “Why is this stack / split / ledger shape law?” | **L10 ADR** |
| Conflict: ADR vs guide | Local code + accepted ADR + guides — if ADR and guide conflict, **ask** and update one |

---

## 1. When to write an ADR

Write an ADR for **hard-to-reverse** or **widely binding** choices, for example:

- greenfield **language / major framework / primary datastore** (after L3 consult)
- **new deployable** or multi-repo split (L2)
- **auth model** (session vs IdP, tenancy model) (L8)
- **money / ledger** shape (append-only vs mutable balance, etc.) (L4)
- public **API strategy** that clients will freeze on (L5)
- adopting a **platform** as default (e.g. Datadog-everywhere, flag system) (L6/L9)

**Do not** write an ADR for:

- routine feature work
- local refactors
- library picks that L3 already treats as routine within the stack
- temporary flags or one-off experiments (unless they become permanent law)

When unsure: **ask** the author whether the choice deserves an ADR (L0).

---

## 2. Where ADRs live

| Kind | Location |
|---|---|
| **Cross-project / author-global law** | This suite: `L10_DECISIONS/` |
| **Application-specific** | That app’s repo, e.g. `docs/adrs/` or `docs/decisions/` |

Use the suite for decisions that should follow you across repos (stack defaults, global
bans). Use the app repo for product-specific architecture.

File naming in this suite:

```text
L10_DECISIONS/
  README.md                 ← this process
  TEMPLATE.md               ← copy to create a new ADR
  NNNN-short-title.md       ← zero-padded sequence, kebab title
```

Example: `0001-postgres-default-relational-store.md`

In app repos, follow local naming if present; otherwise the same short template is fine.

---

## 3. Format (short)

Copy `TEMPLATE.md`. Required sections only:

1. **Status** — `proposed` | `accepted` | `superseded` | `deprecated`  
2. **Context** — forces and constraints (short)  
3. **Decision** — what we chose  
4. **Consequences** — good, bad, follow-ups  

Optional: **Alternatives considered** (bullets). No essay requirement.

---

## 4. Lifecycle

```
proposed  →  author review  →  accepted
                              ↘ superseded (link new ADR) / deprecated
```

- Agents may open PRs with **`proposed`** ADRs.
- Only the **author** (or explicit delegate) marks **`accepted`**.
- Never silently rewrite an **accepted** ADR’s decision; supersede with a new ADR if the
  world changed.

---

## 5. Agent rules

```
✓  draft proposed ADR when landing a hard-to-reverse choice
✓  link ADR from PR summary when relevant
✓  read accepted ADRs before re-opening the same debate
✗  mark accepted without author
✗  ADR for every minor dependency
✗  contradict an accepted ADR without asking + proposing supersession
```

Greenfield stack still follows **L3 + L0 consult**; the ADR **records** the accepted
choice so the next session does not re-decide from scratch.

---

## 6. Done checklist (for a new ADR)

- [ ] Choice is hard-to-reverse or cross-cutting enough to deserve an ADR  
- [ ] File named `NNNN-short-title.md` from template  
- [ ] Context / decision / consequences filled  
- [ ] Status `proposed` until author accepts  
- [ ] Does not restate whole L1–L9 — points at guides where useful  
- [ ] App-specific vs suite-global location chosen correctly  

---

## Index

| ADR | Status | Title |
|---|---|---|
| _(none yet)_ | — | Add rows as ADRs are accepted |

Keep this table updated when ADRs are added or status changes.
