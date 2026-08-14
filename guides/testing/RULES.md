# Testing

Testing law. See [`REFERENCE.md`](REFERENCE.md).

**Scope `[suite-default]`:** priority; TDD and greenfield tests-first; divide-and-conquer; pyramid; mocks/fakes/live deps; coverage, snapshots, flakes; names, factories, isolation; brownfield pins; agent done bar. **Policy**, not a runner tutorial.

Not: [code-style](../code-style/RULES.md); runner/stack ([stack](../stack/RULES.md)); schema beyond the invariant ([data](../data/RULES.md)); product QA; load/perf.

## Complete `[suite-default]`

Suite **not worse** (passes, or failure count did not increase); new/changed logic and bugfixes covered at the right layer; names, factories, isolation followed; no new flakes or dishonest tests; greenfield started with a **harness** and **failing tests for real behavior**. Not 100% coverage. **Not worse is necessary but not sufficient** when you introduced behavior.

## 1. Priority `[suite-default]`

Test first where wrongness is expensive. **Every bugfix gets a test.**

| Higher priority | Lower priority |
|---|---|
| Business rules, money, inventory, eligibility | Pure layout / cosmetic UI |
| Invariants and state machines | Trivial getters and framework glue |
| Regressions (every bugfix gets a test) | One-off scripts and throwaway spikes |
| Authz boundaries that protect real assets | Generated boilerplate |
| Serialization / parsing at trust boundaries | Snapshot spam of large trees |

Cover what you ship, not speculative features.

## 2. TDD `[suite-default]`

**TDD is important** for non-trivial logic: **Red** (failing test states the behavior) → **Green** (smallest pass) → **Refactor** (tests stay green).

Do TDD: domain rules, calculations, state transitions; bugfixes (repro first); new public module behavior. Skip ceremony: config/copy/generated renames; one-line glue with no branch; a spike you will delete (replace with tests before keeping).

### Greenfield: tests first `[suite-default]`

1. Wire the **test harness** early (runner, one sample test in CI/local).
2. First real behavior: **failing test** before production code.
3. Grow each engine/module **behind** tests.

## 3. Divide and conquer `[suite-default]`

Test **each unit or logical engine in isolation**, then cover seams. Many small module-local tests beat one giant scenario. Engines ([architecture](../architecture/RULES.md)) must be testable without the whole product. Integration sits at **boundaries** (DB, HTTP, cache), not as a substitute for unit tests of rules.

## 4. Pyramid `[common]`

| Layer | Role | Volume |
|---|---|---|
| **Unit** | Rules, pure logic, module behavior with fakes | Most |
| **Integration** | Real local DB / adapters / contracts | Some |
| **E2E / visual** | Critical user journeys; UI when UI changed | Few |

### Visual / browser E2E `[suite-default]`

**Only when a UI exists.** Cover **critical journeys** (auth, pay, core happy path). When the task **changes UI**, verify the affected journey or screen (Playwright or project equivalent) — not the whole suite every time. Do not require full visual coverage for pure backend-only changes.

## 5. Mocks, fakes, live deps `[suite-default]`

**Mock or fake IO at the boundary.** Do not mock the unit under test into a tautology.

```
✓  fake clock / HTTP / in-memory repo · local Postgres or testcontainers
✗  mock pricing to assert pricing was called · prod or shared staging in the default suite
```

**Never use production data stores or production networks in automated tests.** Integration uses **local or ephemeral** test resources, or pure fakes.

## 6. Coverage, snapshots, flakes `[suite-default]`

**No global coverage % target.** Cover what is risky. Weak assertions at a high number lose to a smaller suite that protects money.

**Snapshots / goldens — rare.** Allowed for stable pure output (canonical serialization) when diffs are reviewed. Not the default for UI trees or churny JSON. Characterization pins (§8) are the exception.

**Flakes: fix or delete — never ignore.** Deterministic fakes, or delete a worthless test. Quarantine only with an explicit short-term plan owned by a human.

## 7. Structure `[suite-default]`

### Names describe behavior

```
✓ recent_trade_is_not_stale · cancelling_shipped_order_throws
✗ test_stale_trade_detection · test_cancel_order
```

### Factories in the test module

**Private factory functions** in the test module (or colocated support), not shared mutable fixtures or global seed state mutated in order. Factories take only parameters that **vary**; the rest are defaults.

### Isolation `[common]`

Tests must not depend on run order. Prefer no shared mutable module state between cases. Parallel-safe when the runner is (unique IDs, rolled-back transactions).

## 8. Brownfield characterization `[suite-default]`

Before modifying a **zero-coverage** path that has real behavior:

1. **Pin current behavior first.** Inputs in, observed outputs/effects asserted — even if today’s behavior looks wrong.
2. **Then change**, with the bug repro test (red) alongside the pins.
3. **Then decide:** keep pins as regressions, or update deliberately where the old behavior *was* the bug (say so in the summary).

Characterization tests are the one place snapshot-style assertions are **normal**, not rare.

**No harness at all?** **Minimum viable harness**: stack default runner, one file, no CI framework build-out. Ask before larger harness work. One-line trivial glue may skip a harness — *When to break*, not the default.

## 9. What agents must do `[suite-default]`

Behavior/bugfix: add or update tests; bugfix starts from a **repro test** when practical. Untested legacy: characterization pins first (§8), then the change. Greenfield: harness exists; failing test before real logic. UI change: critical-path or affected journey when e2e exists or is warranted. Docs/comments only: no forced new tests. No harness: minimum viable harness (§8); no heavy framework without asking.

## When to break `[suite-default]`

- Author explicitly accepts risk (spike, prototype) — time-box; do not merge as production core untested.
- No harness + one-line trivial glue: may skip a full framework; suite still not worse; ask before large harness work. Real behavior → §8, not this exception.
- Cannot fake the external system: recorded contract or isolated sandbox, **never prod**.

Working safety nets beat ritual. Dishonest tests are worse than a documented gap.

## Never

```
✗ modify untested legacy behavior with no characterization pin (§8)
✗ large untested domain core “until later”
✗ tests that only mirror implementation (assert mocks were called, not outcomes)
✗ production DB or live vendor in CI default path
✗ skip flaky tests permanently · E2E as the only layer · coverage % theater
✗ UI snapshot farm · shared mutable fixture mutated by every file
✗ names that restate the function · testing pure logic only through the UI
✗ TDD skipped on money/inventory/auth rules
```

## Looks wrong, is intentional `[suite-default]`

Fewer tests early in greenfield than a mature suite — OK if each shipped behavior is covered and the harness runs; not zero tests on core rules. Duplicated factory helpers per test file — better than a global fixture god-object. Slower integration tests — worth it for repo/contract bugs fakes miss. Deleting a flake that never caught a real bug — better than red noise. **No coverage gate in CI.** Intentional; risk-based testing is the bar.

## Done `[suite-default]`

Behavior/bugfix covered at the right layer. Legacy path: characterization pins written before the change (§8). TDD for non-trivial logic. Greenfield: harness + tests-first. Units isolated (divide and conquer). Pyramid respected (not E2E-only). IO faked at boundaries; no prod. No new flakes, permanent skips, or snapshot spam. Names describe behavior; factories local; tests isolated. Suite not worse. UI change: affected journey considered.

## Related

[protocol](../protocol/RULES.md) · [code-style](../code-style/RULES.md) · [architecture](../architecture/RULES.md) · [stack](../stack/RULES.md) · [data](../data/RULES.md) · [contracts](../contracts/RULES.md)
