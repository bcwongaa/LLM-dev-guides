# Decisions

Standing-decision process. Rationale: [`REFERENCE.md`](REFERENCE.md). New ADR: copy [`TEMPLATE.md`](TEMPLATE.md).

**Scope `[suite-default]`:** when an ADR is required, short format, lifecycle, suite vs app location, agent draft vs author accept. Not day-to-day implementation, product specs, or a complete historical archive.

## Relationship `[suite-default]`

| Situation | Use |
|---|---|
| How to code / ship / secure | other domain guides |
| Why this stack / split / ledger is law | an ADR here |
| ADR vs guide conflict | local code + accepted ADR + guides — if ADR and guide conflict, **ask** and update one |

Consult first, then record:

| Choice | Open |
|---|---|
| Language / framework / datastore | [`../stack/RULES.md`](../stack/RULES.md) |
| Deployable / multi-repo split | [`../architecture/RULES.md`](../architecture/RULES.md) |
| Schema / money / ledger | [`../data/RULES.md`](../data/RULES.md) |
| Public API clients will freeze on | [`../contracts/RULES.md`](../contracts/RULES.md) |
| Auth / tenancy | [`../security/RULES.md`](../security/RULES.md) |
| Platform APM default | [`../observability/RULES.md`](../observability/RULES.md) |
| Flags / platform-as-default | [`../release/RULES.md`](../release/RULES.md) |
| Ask vs decide | [`../protocol/RULES.md`](../protocol/RULES.md) |

## When to write `[suite-default]`

Write an ADR for **hard-to-reverse** or **widely binding** choices — the rows above.

**Do not** write an ADR for: routine feature work; local refactors; library picks the stack guide already treats as routine; temporary flags or one-off experiments (unless they become permanent law).

When unsure: **ask** (protocol).

## Where ADRs live `[suite-default]`

| Kind | Location |
|---|---|
| Cross-project / author-global law | this suite: `guides/decisions/` |
| Application-specific | that app: `docs/adrs/` or `docs/decisions/` |

Suite = stack defaults and global bans that should follow you. App = product-specific architecture.

```text
guides/decisions/
  RULES.md / REFERENCE.md / TEMPLATE.md
  NNNN-short-title.md       ← zero-padded sequence, kebab title
```

Example: `0001-postgres-default-relational-store.md`

App repos: follow local naming if present; otherwise this template.

## Format `[suite-default]`

Copy `TEMPLATE.md`. Required:

1. **Status** — `proposed` | `accepted` | `superseded` | `deprecated`
2. **Context** — forces and constraints (short)
3. **Decision** — what we chose
4. **Consequences** — good, bad, follow-ups

Optional: **Alternatives considered** (bullets). No essay.

## Lifecycle `[suite-default]`

```
proposed  →  author review  →  accepted
                              ↘ superseded (link new ADR) / deprecated
```

- Agents may open PRs with **`proposed`** ADRs.
- Only the **author** (or explicit delegate) marks **`accepted`**.
- Never silently rewrite an **accepted** ADR’s decision; supersede with a new ADR if the world changed.

## Agent rules `[suite-default]`

```
✓  draft proposed ADR when landing a hard-to-reverse choice
✓  link ADR from PR summary when relevant
✓  read accepted ADRs before re-opening the same debate
✗  mark accepted without author
✗  ADR for every minor dependency
✗  contradict an accepted ADR without asking + proposing supersession
```

Greenfield stack still follows **stack + protocol consult**; the ADR **records** the accepted choice so the next session does not re-decide from scratch.

## Done `[suite-default]`

- [ ] Choice is hard-to-reverse or cross-cutting enough to deserve an ADR
- [ ] File named `NNNN-short-title.md` from template
- [ ] Context / decision / consequences filled
- [ ] Status `proposed` until author accepts
- [ ] Does not restate whole other guides — points at them where useful
- [ ] App-specific vs suite-global location chosen correctly

## Index `[suite-default]`

Keep an index when ADRs exist. Update it when ADRs are added or status changes.

| ADR | Status | Title |
|---|---|---|
| [0001](0001-two-precedence-systems.md) | proposed | Two precedence systems |
| [0002](0002-no-consumer-installer.md) | proposed | No consumer installer, updater, or package |
| [0003](0003-agents-md-canonical-map.md) | proposed | AGENTS.md is the canonical thin map; maps are generated |
| [0004](0004-size-policy.md) | proposed | Size policy instead of fixed budgets |
| [0005](0005-no-compatibility-aliases.md) | proposed | Destructive deprecation, no compatibility aliases |
| [0006](0006-no-playbooks.md) | proposed | No playbooks |
| [0007](0007-cursor-out-of-v2.md) | proposed | Cursor is out of scope for v2 |
| [0008](0008-three-first-class-tools.md) | proposed | Claude Code, Codex, and Grok Build are first-class tools |
| [0009](0009-postgres-default-relational-store.md) | proposed | Postgres is the default relational store |
| [0010](0010-no-python-application-services.md) | proposed | No Python application services |
| [0011](0011-typescript-npm-node.md) | proposed | TypeScript uses npm and Node.js |
| [0012](0012-no-business-logic-in-database.md) | proposed | No business logic in the database |

## When to break `[suite-default]`

Human says this choice does not need an ADR. Backfill only when useful. App repo already has an ADR convention — follow local naming; keep status + context + decision + consequences.

## Never

```
✗ Mark accepted without the author
✗ Silently rewrite an accepted ADR
✗ ADR for every minor dependency or routine feature
✗ Contradict an accepted ADR without asking + proposing supersession
✗ Restate stack / architecture / data / contracts / security / observability / release law inside an ADR
```
