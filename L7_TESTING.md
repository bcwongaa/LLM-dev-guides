# L7 — Testing

What must be tested, when, and how agents should behave around the suite — so confidence
comes from the right tests, not from volume, mocks-of-mocks, or a coverage percentage.

**The goal:** agents stop under-testing business rules, over-testing chrome, skipping TDD
on real logic, and leaving flaky or dishonest tests behind. Testing is part of building,
not a cleanup phase.

## Scope of this guide

**In scope**

- What to test and priority order
- TDD rhythm and greenfield “tests first”
- Divide-and-conquer (test units/engines in isolation)
- Pyramid: unit / integration / E2E
- Mocks, fakes, live dependencies
- Flakes, snapshots, coverage philosophy
- Test naming, factories, and structure (moved from L1)
- Agent definition of done for tests

**Out of scope**

| Concern | Where it lives |
|---|---|
| Day-to-day non-test code shape | **L1** |
| Stack and test-runner choice (Jest vs …) | **L3** / project tooling |
| Schema correctness beyond “test the invariant” | **L4** |
| Full product QA / manual test plans | Human process |
| Load/perf benchmarking standards | Later / project-local |

This guide is **policy**, not a tutorial for a specific runner.

## What “complete” means

Work that touches behavior is complete when:

1. **Tests are not worse** than before (suite passes, or failure count did not increase).
2. **New or changed logic** and **bugfixes** have automated coverage at the right layer.
3. Tests follow structure rules here (names, factories, isolation).
4. No new flaky, skipped-without-plan, or dishonest tests were introduced.
5. Greenfield work started with a **harness** and **failing tests for real behavior**, not
   only scaffolding.

Complete does **not** mean 100% coverage, E2E for every click, or perfect foresight of
every future case.

---

## 1. Priority: what must be tested

Test first and hardest where wrongness is expensive:

| Higher priority | Lower priority |
|---|---|
| Business rules, money, inventory, eligibility | Pure layout / cosmetic UI |
| Invariants and state machines | Trivial getters and framework glue |
| Regressions (every bugfix gets a test) | One-off scripts and throwaway spikes |
| Authz boundaries that protect real assets | Generated boilerplate |
| Serialization / parsing at trust boundaries | Snapshot spam of large trees |

```
✓  ledger balance rules, cancel-shipped-order, pricing eligibility
✓  a failing test that reproduces the bug before the fix
✗  40 tests that only assert a React component className
✗  “we’ll add tests later” on core domain in a greenfield app
```

**Not knowing every case at project setup is normal.** You do not need a complete matrix
on day one. You **do** need enough tests around the behavior you implement that you are
not forced to re-learn and re-break the same code on every revisit. Prefer durable
coverage of what you ship over speculative tests for features that do not exist yet.

---

## 2. TDD and rhythm

**TDD is important** for non-trivial logic.

```
Red    → write a failing test that states the behavior
Green  → smallest code that passes
Refactor → clean structure without changing behavior; tests stay green
```

| Do TDD | May skip ceremony |
|---|---|
| Domain rules, calculations, state transitions | Pure config renames, copy, generated files |
| Bugfixes (repro first) | Trivial one-line glue with no branch |
| New public module behavior | Exploring a spike you will delete (still replace with tests before keeping) |

```
✓  failing test for “cancelling shipped order throws” → implement → pass
✗  implement a pricing engine, then invent tests that only mirror the implementation
✗  strict TDD theater on a one-line constant rename
```

### Greenfield: tests first

When starting a new project or major package:

1. Wire the **test harness** early (runner, one sample test that runs in CI/local).
2. For the first real behavior, write a **failing test** before production code.
3. Grow the app **behind** tests for each engine/module you add.

It is fine if early tests are incomplete relative to the future product. It is **not**
fine to build a large untested core and “add coverage later.”

---

## 3. Divide and conquer

Test **each unit or logical engine in isolation**, then cover seams.

- Prefer many small tests of pure or module-local behavior over only one giant scenario.
- Each engine (L2) should be testable without standing up the entire product.
- Integration tests sit at **boundaries** (DB, HTTP, cache), not as a substitute for unit
  tests of rules.

```
✓  pure function tests for fee calculation; separate test for repository mapping
✓  module public API tested with fakes for IO
✗  only one E2E that clicks through the whole app as the sole safety net
✗  every test boots the full framework and network stack
```

This pairs with L2: logical engines with public surfaces are easier to test in isolation.

---

## 4. Pyramid: unit, integration, E2E

| Layer | Role | Volume |
|---|---|---|
| **Unit** | Rules, pure logic, module behavior with fakes | Most |
| **Integration** | Real local DB / adapters / contracts | Some |
| **E2E / visual** | Critical user journeys; UI when UI changed | Few |

```
✓  dozens of fast unit tests; a handful of DB tests; a few critical path e2e
✗  E2E-first for every rule
✗  zero integration tests when the bug class is always “SQL/ORM mismatch”
```

### Visual / browser E2E (when a UI exists)

- Cover **critical journeys** (auth, pay, core happy path).
- When the task **changes UI**, verify the affected journey or screen (Playwright or
  project equivalent) — not necessarily the whole suite every time.
- Do not require full visual coverage for pure backend-only changes.

---

## 5. Mocks, fakes, and live dependencies

**Mock or fake IO at the boundary.** Do not mock the unit under test into a tautology.

```
✓  fake clock, fake HTTP client, in-memory repo behind an interface
✓  local Postgres / testcontainers for repository contract tests
✗  mock the pricing function to assert the pricing function was called
✗  hit production or shared staging as part of the default suite
✗  suite that requires the developer’s personal VPN and live third-party accounts
```

**Never use production data stores or production networks in automated tests.**  
Integration uses **local or ephemeral** test resources, or pure fakes.

Prefer the lightest double that still makes the test meaningful. Heavy mocking of every
collaborator usually means the unit is too large or the test asserts implementation
details.

---

## 6. Coverage, snapshots, flakes

### Coverage percentage

**No global coverage % target** as the definition of quality. Cover what is risky. A high
number with weak assertions is worse than a smaller suite that protects money and
invariants.

### Snapshots / goldens

**Rare.** Allowed for stable pure output (e.g. canonical serialization) when diffs are
reviewed. Avoid as the default for UI trees or large JSON blobs that churn constantly.

### Flakes

**Fix or delete — never ignore.**

```
✓  fix timing with deterministic fakes; delete a worthless test
✓  quarantine only with an explicit short-term plan owned by a human
✗  it.skip without reason
✗  “retry 3 times in CI” as the permanent design for a race
✗  leave a red test “because it fails only sometimes”
```

A flaky test is a failing test with worse manners. It trains people to ignore the suite.

---

## 7. Test structure (names, factories, isolation)

These rules used to live in L1 §20; **L7 owns them**.

### Names describe behavior verified

```
✓ recent_trade_is_not_stale
✓ cancelling_shipped_order_throws
✗ test_stale_trade_detection
✗ test_cancel_order
```

### Factories in the test module

Build data with **private factory functions** in the test module (or colocated test
support), not shared mutable fixtures or global seed state that tests mutate in order.

Each factory takes only the parameters that **vary** across cases; everything else is a
sensible default.

```
✓
function makeOrder(overrides: Partial<Order> = {}): Order {
  return {
    id: 'ord_test_1',
    userId: 'user_test_1',
    status: 'pending',
    total: 100,
    ...overrides,
  }
}

test('cancelling_shipped_order_throws', () => {
  const order = makeOrder({ status: 'shipped' })
  expect(() => cancelOrder(order)).toThrow(OrderAlreadyShippedError)
})
```

### Isolation

- Tests must not depend on run order.
- Prefer no shared mutable module state between cases.
- Parallel-safe when the runner is parallel (unique IDs, transactions rolled back, etc.).

---

## 8. Brownfield: characterization tests before change

Changing **untested legacy code** is where agents cause silent regressions. Before
modifying a zero-coverage path that has real behavior:

1. **Pin current behavior first.** Write a characterization test that captures what the
   code does **today** — inputs in, observed outputs/effects asserted — even if today’s
   behavior looks wrong. The pin proves your change altered only what you meant to alter.
2. **Then change**, with the bug repro test (red) alongside the pins.
3. **Then decide** what the pins become: keep as regression tests, or update deliberately
   where the old behavior *was* the bug (say so in the summary).

Characterization tests are the one place snapshot-style assertions are **normal**, not
rare — capturing an ugly real output verbatim is the point.

**No harness at all?** Introduce the **minimum viable harness**: the stack’s default
runner, zero config beyond running one file, no CI framework build-out. Ask before larger
harness work (scope rule); a one-line fix in trivial glue may proceed without a harness —
that is the documented exception in *When to break these rules*, not the default.

```
✓  pin formatLegacyInvoice() with 3 real-shaped inputs → fix date bug → 1 pin updated deliberately, 2 unchanged
✓  no runner in repo: add the stack’s default runner + the pin file, nothing more
✗  refactor a 400-line untested module “carefully” with zero tests before or after
✗  block a one-line typo fix on standing up a full test framework
```

---

## 9. What agents must do

| Situation | Behavior |
|---|---|
| Change behavior / fix bug | Add or update tests; bugfix starts from a repro test when practical |
| Change untested legacy code | Characterization pins first (§8), then the change |
| Greenfield feature | Harness exists; failing test before implementation for real logic |
| UI change | Critical-path or affected journey check when e2e exists or is warranted |
| Touch only docs/comments | No forced new tests |
| Project has no harness | Minimum viable harness (§8); do not invent a heavy framework without asking; for greenfield, propose harness first |

**Definition of done (tests):** tests not worse **and** new logic / regressions covered at
an appropriate layer.

Aligns with L0/L1 “tests not worse,” and strengthens it: **not worse is necessary but not
sufficient** when you introduced behavior.

---

## 10. Anti-patterns

```
✗ modify untested legacy behavior with no characterization pin (§8)
✗ large untested domain core “until later”
✗ tests that only mirror implementation (assert mocks were called, not outcomes)
✗ production DB or live vendor in CI default path
✗ skip flaky tests permanently
✗ E2E as the only layer
✗ coverage % theater without strong assertions
✗ UI snapshot farm that always needs updating
✗ shared mutable fixture mutated by every file
✗ test names that restate the function name without the behavior
✗ testing everything through the UI for pure logic
✗ TDD skipped on money/inventory/auth rules
```

---

## 11. Intentional patterns that may look like mistakes

**Fewer tests early in greenfield than a mature suite.** Normal if each shipped behavior
is covered and the harness runs. Not an excuse for zero tests on core rules.

**Duplicated factory helpers per test file.** Preferable to a global fixture god-object
(same spirit as L2: prefer duplication until pain is real).

**Integration test that is slower than unit tests.** Worth it for repository and contract
bugs that unit fakes never catch.

**Deleting a flaky test** when it never caught a real bug. Better than a red-noise suite.

**No coverage gate in CI.** Intentional; risk-based testing is the bar.

---

## When to break these rules

- Author explicitly accepts risk (spike, prototype) — time-box and do not merge as
  production core without tests.
- Legacy brownfield has no harness; fixing a one-line bug in trivial glue may not require
  introducing a full framework — still do not leave the suite worse; ask before large
  harness work if out of scope. For anything with real behavior, §8 (characterization
  pins + minimum viable harness) is the bar, not this exception.
- External systems cannot be faked meaningfully; use a recorded contract or sandbox with
  isolation, never prod.

Working safety nets beat ritual. Dishonest tests are worse than a documented gap.

---

## Done checklist

- [ ] Behavior change or bugfix has appropriate automated coverage
- [ ] Untested legacy path: characterization pins written before the change (§8)
- [ ] TDD used for non-trivial logic (red first when practical)
- [ ] Greenfield: harness + tests-first for real behavior
- [ ] Units/engines tested in isolation where possible (divide and conquer)
- [ ] Pyramid respected (not E2E-only)
- [ ] IO mocked/faked at boundaries; no prod dependencies
- [ ] No new flakes, permanent skips, or snapshot spam
- [ ] Names describe behavior; factories local; tests isolated
- [ ] Suite not worse; lint/typecheck still clean if project has them
- [ ] UI change: critical/affected journey considered

## Relationship to other layers

| Topic | Layer |
|---|---|
| Protocol / done bar / scope | **L0** |
| Non-test code shape (L1 §20 now points here) | **L1** |
| Engines/modules testable in isolation | **L2** |
| Runner/tooling defaults | **L3** / project |
| Data invariants under test | **L4** |
| Contract tests at the wire | **L5** |
| Authz / IDOR regressions | **L8** |
| Safe rollout of test impact | **L9** |
