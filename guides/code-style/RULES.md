# Code style

Binding code-shape law. Rationale and examples: [`REFERENCE.md`](REFERENCE.md).

**Scope `[suite-default]`:** applies to **any code you write**. Where code belongs is [`../architecture/RULES.md`](../architecture/RULES.md).

## Complete / post-code `[suite-default]`

Done when: intended behavior works; tests pass or are **not worse** than the pre-edit baseline; touched code matches this guide (no new listed anti-patterns). Not perfect. Do not fix nearby smells.

Before done: tests not worse; **never** change out-of-scope code; style only on touched code; stop.

Re-read cost, highest first: async / control flow → function purpose without its body → value shape → non-obvious reasoning.

## 1. Table of contents `[suite-default]`

Body calls **one level** below, same domain. Caller is the summary; callee names must make it read.

```
✓ initUser → initAccountRecord / initUserSettings / publishUserCreated
✗ initUser → initDb() / raw SQL / fetch('/notify')
```

`initDb()` belongs inside `initAccountRecord`.

## 2. One kind of work `[suite-default]`

Either **external I/O** or **pure domain logic**, not both. Orchestrators sequence named helpers; they do not inline validation, mutation, or transport.

## 3. Sequential first `[common]`

Write async in sequential order. Parallelize only after independence is clear and no rate-limit, fairness, or ordering forbids it. Partial-failure batches: settle-all, then inspect.

## 4. Name-first decomposition `[suite-default]`

Name before writing the body. Honest name needs “and”/“or” → split.

One-sentence outcome, not a procedure. If the summary is a procedure, it is an orchestrator — each step is a named helper.

**Second-instance rule:** extract on the second copy, not the third.

**Don’t over-extract.** A 90-line function that respects §1–§2 is fine. Fake seams and five-parameter helpers are worse. Cognitive load, not line count.

## 5. Where helpers live `[suite-default]`

| Kind | Lives as |
|---|---|
| Generic, cross-domain (`findMax`) | Free function, utility file |
| Domain, stateless, broadly useful | Static-ish method on the domain type |
| Domain, instance state | Private method |
| Nearby primitives-only calc | Free function, same file |

No domain helpers in generic utils. Don’t force private on a domain surface that belongs public.

## 6. `_` prefix `[suite-default]`

**OOP languages only** (TS, Java, Kotlin, C++, C#, Swift): `_` on methods that exist *because* a public method was decomposed. Not every private method.

Skip in Rust, Go, and module-privacy languages — visibility is the signal.

## 7. Naming

**Language conventions `[common]`.** Casing, word split, file names follow the language. Personal rules sit on top, not instead.

**Semantic prefixes `[suite-default]`:** `get(id)` → `X | null` (caller guards). `ensureGet(id)` → `X`, throws if missing (caller trusts). `isActive` → boolean. `_loadContext` → OOP machinery. See §12.

**Named constants `[common]`.** No bare magic numbers/durations. `FIFTEEN_MINUTES` is enough when context already says what it is.

**Role suffixes `[suite-default]`:** `OrderEntity`, `StatusEnum`, `CreateRequestDto`. In-memory domain types: no suffix (`TradeContext`).

**External schema typos/casing `[suite-default]`.** Keep them in the entity layer. Translate at the boundary (§11). Document the first appearance.

## 8. Null vs absent `[suite-default]`

`null` = field exists, no value yet. `undefined` = caller did not provide it. Explicit checks (`=== null`, `is None`). Empty string, zero, and null do not collapse.

## 9. Explicit construction defaults `[suite-default]`

Every field defaulted in the constructor. No `Object.assign` of untyped blobs. Required vs optional is in the signature. Defaults match the common case.

## 10. Typed update objects `[suite-default]`

Writes are a typed partial of the entity, not an untyped map.

## 11. Conversion at entity boundaries `[suite-default]`

Entity = external schema exactly. Domain type = clean. Use the language’s standard conversion (`TryFrom`/`From`, or `fromEntity` / `fromEntityOrThrow`). Infallible vs fallible are distinct.

## 12. `get` / `ensureGet` `[suite-default]`

- `get` — absence is information (normal branch).
- `ensureGet` — absence is a bug, not a branch.

Trigger is not “caller needs the value.” Trigger is “absence means a corrupted system.” `[project-example]` 404 → `get`; 500 → `ensureGet`.

404/400 live at the **entry point**. Below it, services assume existence checks passed.

`ensureGet` stays trivial: `get`, panic if null, return. No fallback, default, or legacy branch.

Trade-off: drops compiler null-tracking at the call site. Honest name + trivial body + review are the mitigation.

## 13. Errors where detected `[suite-default]`

Throw in the detecting layer. Controllers delegate and return.

Domain errors: plain user-facing sentences. Programmer invariant failures: terse/technical.

```
✗ try { doThing() } catch (e) { throw e }
✗ return new Error('...')
```

Throw. Don’t return errors. Don’t catch-and-rethrow.

## 14. Annotate opaque bindings `[suite-default]`

Rust/TS/Java/Kotlin/C#/Swift: annotate when the RHS type is not obvious (cross-module, chain, multi-line flow, ambiguous ownership). Skip literals, named constructors, trivial expressions, immediately-used bindings. Not for dynamic languages.

## 15. Comments `[common]`

Default: no comment. Do not restate the next line. Comment only to **anchor weirdness** a future reader would “fix.”

Deprecated: say what to use instead. Commented-out code may stay if re-enable is plausible; mark the restoration condition.

## Relocated — do not restate

- Caching (stale-while-revalidate), bounded polling, async job dispatch by named constant → [`guides/architecture/RULES.md`](../architecture/RULES.md)
- Two-tier data access → [`guides/data/RULES.md`](../data/RULES.md)
- Log line shape → [`guides/observability/RULES.md`](../observability/RULES.md)
- Testing policy → [`../testing/RULES.md`](../testing/RULES.md). Here: tests must not be worse after the change.

## File order `[common]`

Language-idiomatic file order. Don’t invent a personal one.

## When to break `[suite-default]`

Working code beats beautiful code. Touch only what the current task needs. Second-instance applies to the change in hand, not pre-existing duplication elsewhere.

Vendor bugs, perf-critical loops, and unchangeable contracts may violate every rule — comment why (§15) and move on.

Brownfield: net-new files follow this guide; edits match the file’s dominant pattern unless that pattern is on the never-list and the fix stays in lines already being changed. Tie-breaker: `guides/protocol/RULES.md`.

## Never

```
✗ try { ... } catch (e) { throw e }
✗ return new Error(...)
✗ if (someAsyncCall()) { ... }    // missing await; Promise is always truthy
✗ const result = doThing()        // unused capture
```

## Looks wrong, is intentional `[suite-default]`

Broadcast/publish results are **fire-and-forget**. Do not add error handling at those call sites.

Entity-layer casing/typo mismatches with the live schema are load-bearing (§7).
