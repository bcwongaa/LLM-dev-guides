# Protocol

Every-task ritual. Git / parallel mechanics: [`../orchestration/RULES.md`](../orchestration/RULES.md) — load only when branching, spawning, or running parallel work. Rationale: [`REFERENCE.md`](REFERENCE.md).

**Scope `[suite-default]`:** bootstrap, routing, two precedence systems, ask vs decide, scope ban, done evidence, handoff, skills. Not code shape, stack, or domain design.

## Re-anchor `[suite-default]`

Re-read this file (or confirm it is still in context) at: **session start**; **before the first edit**; **after context/handoff recovery**; **before calling the work done**.

## Bootstrap `[suite-default]`

**Bootstrap (every task):** this file → protocol → only relevant guides → STATUS if present → test/lint baseline → plan if non-trivial → edit.

1. Adapter (`AGENTS.md`; Claude also `CLAUDE.md` `@AGENTS.md`).
2. This protocol.
3. Only the guides the routing table requires.
4. `docs/agent/STATUS.md` if present (and any workstream STATUS you own).
5. Baseline: run Test (and Lint); record pass/fail + failure count. Skip only if there is no test command.
6. Feature branch off the integration base (orchestration).
7. Plan if non-trivial, then edit.

```
✓  Adapter → protocol → code-style + testing (bugfix) → STATUS → baseline → branch → edit
✗  Skip guides · load every guide · “tests not worse” with no baseline
```

## Routing `[suite-default]`

Smallest set that matches the task. Mixed: every layer you will actually touch, not the rest.

| Task | Open |
|---|---|
| Start / ask / done | this file |
| Branch / PR / parallel / briefs | `../orchestration/RULES.md` |
| Code shape | `../code-style/RULES.md` |
| Bugfix | code-style + `../testing/RULES.md` |
| Layout / new deployable | `../architecture/RULES.md` |
| Language / framework / storage | `../stack/RULES.md` |
| Schema / money / time | `../data/RULES.md` |
| HTTP / events / DTOs | `../contracts/RULES.md` |
| Logs / traces / data health | `../observability/RULES.md` |
| What to test / TDD | `../testing/RULES.md` |
| Auth / PII / secrets | `../security/RULES.md` |
| Flags / expand-contract / deploy | `../release/RULES.md` |
| Standing decisions | `../decisions/` |

Missing consumer guide: do **not** invent a parallel house rule; match local code; ask if always-human; else smallest safe change.

## Instruction authority `[suite-default]`

```
org/platform policy > current-task human > project/path instructions > adopted suite > user-global > third-party skills (except vendor API how-to) > model taste
```

User-global files are personal defaults. In an adopting repo they lose to suite law and project instruction. Tooling habits stay; personal style/process rules yield.

Also always: working behavior > style purity. Smallest change that ships > drive-by improvement.

## Implementation convention `[suite-default]`

```
approved task design > nearest file > package > repository > suite default
```

Discovery: read 2–3 sibling files. Prefer the most recently merged code in that area when styles compete.

**Overrides nearby code:** correctness, safety, explicit project law, and the suite never-list. Net-new files follow the suite. Edits match the file unless the pattern is on the never-list and the fix stays in lines already being changed. Do not sweep the rest.

```
✓  New code follows the newer async convention in that package
✗  “File swallows errors, so I will too” · convert the whole file “while here”
```

## Always human `[suite-default]`

Root asks the human. Subagents escalate to parent; hard items go through the root to the human.

| Always human | Includes |
|---|---|
| Business logic / product semantics | Discount rules, who is owed what |
| Architecture | New deployable, new major boundary |
| New auth / security boundary | Permission model, PII policy |
| Destructive / irreversible data | DROP, unrecoverable delete |
| Materially ambiguous product intent | Conflicting or missing acceptance |

Hard items (destructive data, new auth, new deployable, true product ambiguity) plus business logic and architecture **always** reach the human. Parents must not rubber-stamp these.

**Root may decide** a routine schema/API/scope detail only when all of: acceptance criteria are clear; no new business rule or architecture; backward-compatible or readily reversible; rollback and verification are concrete; still inside task scope.

**May decide** inside existing stack and local convention: day-to-day code shape; continuing the stack; bugfixes strictly required to ship; tests so the suite is not worse.

When unsure: ask (root) or escalate (subagent). “Do not ask questions” is not authority to invent business logic or architecture.

```
✓  “Mongo for this new domain?” → human · rename a local helper → decide
✗  Expand “fix login” into auth redesign
```

## Subagents `[suite-default]`

Subagents **cannot** ask the human.

1. Always-human → stop; report to the **direct parent** with options + recommendation.
2. Parent is the authority for its children and owns what it approves.
3. Nested children escalate to their direct spawner only. Only the root talks to the human.
4. Peer sessions still ask the human.

Mechanics and brief templates: orchestration.

## Plan / scope `[suite-default]`

≤5 bullets before editing when: multi-file, design/API choice, unclear scope, or always-human domains. Skip trivial one-file fixes.

**NEVER** change code outside the task; "while I'm here" cleanups; expand without the human (or parent, if subagent — parent documents it; hard items still go human); touch unrelated files for taste.

A one-line change in a dependency of the edit path can be in scope — say so. Adjacent unrelated improvement is not.

## Done `[suite-default]`

1. Scope respected.
2. Relevant guides followed.
3. Tests not worse than the **recorded bootstrap baseline**. Bugfixes/behavior changes also meet the testing-guide coverage bar.
4. Lint/typecheck if the project has them; no new failures. Format nits are not a release blocker unless they break compile/tests.
5. Feature work on a branch; PR small when review-ready (orchestration).
6. Short summary **with evidence**: before/after tail of test/lint output. What changed, what was deliberately not changed, open questions.

Complete is not perfect and not “every nearby smell fixed.” Agent self-report is not evidence.

Re-check before done: scope, guides, tests vs baseline, lint/types, summary evidence, STATUS/PR handoff, git lineage.

## Handoff / skills / entry `[common]`

WIP spanning sessions/tools: `docs/agent/STATUS.md` with Goal, Done, Next, Do not touch, Open questions. PR body is what/why, how to verify, out of scope, open questions. One STATUS per workstream or clearly separated sections.

Skills are task-scoped. Suite wins for stack/style/process. Skill wins for pure vendor API how-to. Local code wins over both when the repo already does X. Do not bulk-load catalogs.

`AGENTS.md` is the map. `CLAUDE.md` is `@AGENTS.md` plus Claude mechanics. Adapters do not restate protocol, code-style, or stack law.

## When to break `[suite-default]`

Human explicitly overrides a step. Emergency prod fix — still no drive-bys; note skips. Adapter/guide missing — follow local instructions; do not block forever. Project documents a different branch model — follow local git; keep small PRs. No test command — skip baseline, say so; do not fake it.

Breaking always-human on business logic, architecture, greenfield stack, or security without a human is not a valid exception.

## Never

```
✗ Skip protocol · restate guide law in adapters/STATUS · open every guide
✗ Invent missing layers · drive-by refactors
✗ Autonomous greenfield stack, architecture, or business-rule pick
✗ “Tests not worse” with no baseline · bugfix with no repro test
✗ Treat a never-list smell as local convention
✗ Grade your own compliance by saying you followed the guides
```
