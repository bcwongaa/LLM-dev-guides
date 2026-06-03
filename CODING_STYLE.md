# A Coding Style for LLM-Assisted Development

A living document of coding patterns and the reasoning behind them.

**The goal:** when an LLM writes code, the person responsible for reading it later still has
to understand it. This document exists so LLM-generated code is shaped consistently enough
that re-reading it doesn't cost a translation pass. Every rule earns its place by reducing
the friction of opening a file cold months after it was written.

Priorities, in order of cost when re-reading code:
1. Tracing async / control flow
2. Understanding what a function does without reading its body
3. Knowing the shape of a value
4. Recovering the reasoning behind a non-obvious choice

The rules below are roughly ordered by how much they serve those priorities.

---

## 1. Functions read like a table of contents

A function's body should call functions at **one level of abstraction below it**, and they
should all belong to **the same domain**. The reader of the outer function gets a summary;
the detail lives one level down.

```
✓
initUser(input)
  → initAccountRecord(input)
  → initUserSettings(input)
  → publishUserCreated(input)

✗
initUser(input)
  → initDb()                      ← infrastructure, wrong level
  → INSERT INTO accounts ...      ← raw SQL, wrong level
  → initUserSettings(input)
  → fetch('/notify', ...)         ← transport detail, wrong level
```

`initDb()` isn't wrong — it's just in the wrong place. It belongs *inside* `initAccountRecord`,
where checking-and-opening-the-connection is contextually relevant to the work being done.
Mixing levels in one function turns a table of contents into a transcript.

**Both halves of the call have to read well.** The caller is the summary; the callee names
are what makes the summary make sense. A clean caller calling vaguely-named helpers is not
a clean function.

---

## 2. One function does one kind of work

A function is either coordinating **external I/O** (fetching, writing, publishing, calling APIs)
or doing **pure domain logic** (validating, calculating, transforming). Not both.

```
✓
async function processOrder(orderId) {
  const order   = await fetchOrder(orderId)
  const checked = validateOrder(order)         // pure
  await writeOrder(checked)                    // I/O
  await publishOrderProcessed(checked)         // I/O
}

✗
async function processOrder(orderId) {
  const order = await fetchOrder(orderId)
  if (order.total < 0) throw new Error('...')   // validation mixed in
  if (!order.items.length) throw new Error('...')
  order.processedAt = new Date()                // mutation mixed in
  await writeOrder(order)
}
```

The mixed version is a smell because debugging a validation rule means re-reading the I/O
around it to be sure nothing else is changing. The split version lets `validateOrder` be
read in isolation.

---

## 3. Sequential first, parallel second

Default to writing async code in the order it would run sequentially. Reach for parallelism
**only after** identifying independent calls that are worth speeding up — and only when there
is no rate limit, fairness, or ordering concern that would forbid it.

```
✓ first pass
const user    = await fetchUser(id)
const account = await fetchAccount(id)
const prefs   = await fetchPreferences(id)

✓ after noticing all three are independent
const [user, account, prefs] = await Promise.all([
  fetchUser(id),
  fetchAccount(id),
  fetchPreferences(id),
])
```

Parallelism is a second-pass optimization, not the default shape of code. An LLM that
fans out everything that *could* be fanned out produces code where the control flow no
longer matches the dependency structure of the underlying operation, which is harder to
reason about during debugging.

For batch operations where partial failure is acceptable, use a settle-all pattern and
inspect results afterward rather than letting one failure abort the rest.

---

## 4. Decomposition: name-first, not size-first

§1 and §2 already do most of the work — a function that calls one-level-below helpers in
one domain, doing one kind of work, will land at a reasonable size on its own. This section
covers what to check **before writing the body** and when to override the defaults.

**The naming test.** Before writing a function body, name it. If the name needs "and" or
"or" to be accurate, the function is doing more than one thing. Split it before writing
any code.

```
✗ processOrderAndNotifyUser    ← split into processOrder + the notify step
✗ validateOrRejectPayment      ← validatePayment, with rejection raised inside
✓ processOrder
✓ validatePayment
```

**The one-sentence summary test.** A function's purpose should fit in one sentence that
names an outcome ("processes an order"), not a procedure ("fetches the order, validates
it, writes it, publishes an event"). If the only honest summary is the procedure, the
function is the *orchestrator* — which is fine — but each step in the procedure should be
a named helper call, not inlined logic.

**The second-instance rule.** The moment something is written a second time, extract.
Not the third. This is the most-violated rule in practice because the second instance
always feels premature.

```
✗ second copy of "compute end-of-day price with timezone shift"
   appearing in a different method                              ← extract now

✓ extracted into priceAtClose(symbol, date) on first repeat
```

**Don't over-extract.** Some operations are inherently long and have no clean internal
seam — a tight numerical loop with per-feature parallel work, a constructor wiring many
components together, a `select!` arm whose per-event handling is irreducibly multi-step.
A 90-line function that respects §1 and §2 is fine. Inventing fake helper boundaries to
shorten it makes the code worse, not better. The goal is cognitive load when reading, not
line count.

If you're writing a function and reaching for an extraction that would force you to thread
five parameters into the helper just to give it the context it needs, that's the signal
to leave it inlined.

---

## 5. Where helpers live

Decision rule for any extracted helper:

| Helper kind | Lives as |
|---|---|
| Generic, reusable across domains (`findMax`, `chunk`) | Free function, separate utility file |
| Domain-specific, stateless, broadly useful in the domain | Static-ish method on the domain type (`PortfolioEntity.bestPerformingDayFromArray`) |
| Domain-specific, uses instance state | Private method on the class |
| Pure calculation taking primitives, used only nearby | Free function, same file |

```
✓ generic, separate file
function findMax(xs: number[]): number { ... }

✓ domain-specific, static on the entity
class PortfolioEntity {
  static bestPerformingDayFromArray(history: Day[]): Day { ... }
}

✓ pure calculation, same file as caller
function drawdownPct(values: number[]): number { ... }
function reportDrawdowns(portfolio) {
  return portfolio.histories.map(h => drawdownPct(h.values))
}

✗ domain-specific helper hidden in a generic utils file
// utils.ts
function calculatePortfolioRebalanceWeights(...) { ... }
```

A helper "private" only because no one else happens to call it is fine staying public if
that's the language's idiom. Don't hide things that legitimately belong to the domain
type's surface.

---

## 6. The `_` prefix (OOP languages only)

In TypeScript, Java, Kotlin, C++, C#, Swift — anywhere private methods are a first-class
concept — prefix a method with `_` when it is **machinery behind a public method** on the
same class. It signals: "this is the extract-method refactor made visible; not part of the
public contract."

```
✓
class OrderService {
  async processOrder(user, orderId) {
    const order = await this._loadAndValidate(user, orderId)
    await this._executeAndRecord(order)
  }
  private async _loadAndValidate(...) { ... }
  private async _executeAndRecord(...) { ... }
}
```

Skip in Rust, Go, and other languages where module-level privacy serves the same purpose.
In those languages, the visibility keyword (or its absence) is the signal; an underscore
prefix is noise.

Not every private method gets a `_`. Reserve it for ones that exist *because* a public
method was decomposed. Stand-alone private methods that are their own concern keep their
plain name.

---

## 7. Naming

### Follow the language's own conventions

Casing, word separation, and file naming follow the language standard — not a personal
convention imposed across languages. camelCase / PascalCase in TS and JS, snake_case
throughout in Python and Rust, and whatever the idiomatic module/file naming is for the
language. Personal naming choices sit *on top of* the language standard, not in place of it.

### Semantic prefixes signal intent

These apply regardless of language:

```
✓
get(id)         → returns X | null. Callers must guard.
ensureGet(id)   → returns X, throws if missing. Callers trust the result.
isActive(x)     → returns boolean.
_loadContext()  → internal machinery (OOP languages).
```

`get` vs `ensureGet` is the most consequential of these — it's a system-design choice
expressed as a naming convention. See §12 for the full pattern.

### Constants are named, not inlined

Magic numbers and durations get a named constant at the top of the file. The name describes
what it represents, not just the value.

```
✓
const FIFTEEN_MINUTES = 15 * 60
const THREE_MINUTES   = 3 * 60

✗
if (elapsed > 900) { ... }   // what is 900?
```

### Suffix types with their role

```
✓
OrderEntity        ← DB row shape
StatusEnum         ← enum
CreateRequestDto   ← transfer object
TradeContext       ← in-memory domain type (no suffix)
```

### Preserve typos and casing in external schemas

When a typo ships in a persistent schema (DB field, API contract), it stays in all new code
that touches that field. Silently correcting it creates a mismatch with live data. Same for
casing: if a DB column is `snake_case` and the code is TS, mirror the schema exactly in the
entity layer and apply lint suppressions if needed. The inconsistency is intentional and
load-bearing — document it where it first appears.

The translation to clean domain types happens at the boundary (see §11), not by renaming
fields silently in the entity layer.

---

## 8. Null vs absent

```
✓
null       → "this field exists in the domain but has no value yet"
undefined  → "this was not provided by the caller"
```

These are distinct states. Null checks are explicit — `x === null`, `x is None` — not
coerced by truthiness. An empty string, a zero, and a null are three different things
and shouldn't collapse into one branch.

---

## 9. Explicit defaults at construction

When constructing objects from external data (DB rows, API responses, incoming requests),
every field is explicitly defaulted in the constructor. The shape of the object is fully
determined at construction time, not later.

```
✓
constructor(data: OrderEntityInit) {
  this.id        = data.id                       // required
  this.userId    = data.userId                   // required
  this.isActive  = data.isActive  ?? true
  this.deletedAt = data.deletedAt ?? null
  this.retries   = data.retries   ?? 0
}

✗
constructor(data: any) {
  Object.assign(this, data)                      // shape is now anyone's guess
}
```

Required fields are separated from optional fields at the constructor signature level,
making it impossible to construct an invalid object without a type error.

**The defaults carry real information.** `isActive ?? true` means "new orders are active
unless the caller says otherwise" — that default exists *because* callers shouldn't have
to specify `isActive: true` every time they create an order. Most configs are either
irrelevant to the caller or correct 99% of the time at their default; that's exactly what
makes constructor defaults useful. Choose defaults that match the common case so callers
write less, not more.

---

## 10. Typed update objects

When building an object to write back to storage, construct it as a typed partial of the
entity rather than an untyped map. Catches field name drift and extra fields at compile time.

```
✓ TypeScript
const update: Partial<OrderEntity> = {
  status:    'completed',
  updatedAt: now(),
}
await orderRepo.update(id, update)

✗
await orderRepo.update(id, {
  status:    'completed',
  upadtedAt: now(),                              // typo, no compile error
})
```

Use the type system to verify write objects rather than relying on runtime schema validation.

---

## 11. Conversion at entity boundaries

DB/API types (entities) are separated from in-memory domain types. The boundary is an
explicit, typed conversion — using the language's standard conversion interface, not a
bespoke `convert()` method.

- **Infallible** conversion — simple field mapping, no error path.
- **Fallible** conversion — when parsing can fail (e.g., a string field into a numeric).

```
✓ Rust
impl TryFrom<OrderEntity> for Order {
  type Error = OrderParseError;
  fn try_from(e: OrderEntity) -> Result<Self, Self::Error> { ... }
}

✓ TypeScript
function orderFromEntity(e: OrderEntity): Order { ... }
function orderFromEntityOrThrow(e: OrderEntity): Order { ... }
```

The entity mirrors the external schema exactly (including typos and casing — see §7).
The domain type is clean. Using the language's standard conversion interface means it
composes naturally with error propagation.

---

## 12. The `get` / `ensureGet` pattern

The retrieval layer has two variants of every read:

```
get(id)         → returns X | null
ensureGet(id)   → returns X, throws if missing
```

This looks like a naming convention. It's actually a stance on where validation lives,
how invariants are enforced, and what kind of failures the system tolerates.

### The principle

**The happy path doesn't branch on expected absence.** If a function legitimately has two
code paths — "the thing exists" and "the thing doesn't exist" — those are two paths, and
they should look like two paths. They shouldn't be smuggled into a single function with a
guard clause at the top pretending it's one flow.

By the time a function is calling `ensureGet`, the caller has already committed: "this
value is required to do the work." If the value isn't there, the system is in a state it
shouldn't be in — a referenced record is gone, a foreign key dangles, an upstream lied.
That's a 500, not a branch.

### The rule

```
✓ get — absence is information, a normal branch
async function findExistingDraft(userId) {
  const draft = await this.getDraft(userId)
  if (draft === null) return startNewDraft(userId)   // expected, normal path
  return continueDraft(draft)
}

✓ ensureGet — absence is a bug, not a branch
async function cancelOrder(orderId) {
  const order = await this.ensureGetOrder(orderId)   // if missing, system is broken
  if (order.status === 'shipped') throw new OrderAlreadyShippedError(orderId)
  await this._executeCancellation(order)
}

✗ ensureGet misapplied
async function findExistingDraft(userId) {
  const draft = await this.ensureGetDraft(userId)    // missing = normal! converts a 404 into a 500
  return continueDraft(draft)
}
```

**The trigger for `ensureGet` is not "the caller needs the value."** The trigger is
"absence indicates a corrupted system, not a normal user/data state." These usually
coincide, but not always. When in doubt: would the right HTTP response be a 404 (use
`get`) or a 500 (use `ensureGet`)?

### Where 404s and 400s live

User-facing existence checks (404) and input validation (400) happen at the **entry
point** — the controller, request handler, message consumer. The layer that knows the
user's intent.

Below the entry point, every service method operates under the assumption that upstream
existence checks passed. If something is missing at this depth, that's a bug.
`ensureGet` is the syntactic enforcement of that boundary.

```
✓
class OrderController {
  async getOrder(req, res) {
    const order = await this.service.getOrder(req.params.id)   // get, not ensureGet
    if (order === null) return res.status(404).send('not found')
    return res.json(order)
  }

  async cancelOrder(req, res) {
    const order = await this.service.getOrder(req.params.id)   // get, not ensureGet
    if (order === null) return res.status(404).send('not found')
    await this.service.cancelOrder(order.id)                   // service uses ensureGet internally
    return res.status(204).send()
  }
}
```

### Why this is worth a section, not a footnote

Three operational properties make the pattern earn its place:

**1. Locality of blame.** A panic at `ensureGetOrder(orderId)` names the lookup, the ID,
and the stack frame. The diagnostic is the failure. Without `ensureGet`, a missing record
produces a null-pointer error several layers deeper, and debugging means walking the call
graph backward to find which `get` returned null and got passed along.

**2. Bad-data containment.** `ensureGet` is a write barrier. Code paths that depend on a
missing value cannot proceed to the write step — the panic short-circuits them. Without
it, you can build an update object with `undefined` in a field, pass it down, and write
garbage to storage. The pattern shifts the question from "was validation done before
writing?" to "did the read succeed at all?" Getting past the read is enforced
by the function name.

**3. Forces the 404-vs-500 split to happen at the right layer.** Without this pattern,
every layer independently decides whether a null is user-facing (404) or system-broken
(500), and the answers drift over time. With it, the entry point owns the 404 decision
and everything below operates on confirmed-existing values.

### Constraints on `ensureGet` implementations

**Keep them trivial.** Call `get`, panic if null, return. No branches. No fallback. No
"well, in this case return a default."

```
✓
async ensureGetOrder(id: OrderId): Promise<Order> {
  const order = await this.getOrder(id)
  if (order === null) throw new OrderNotFoundError(id)
  return order
}

✗
async ensureGetOrder(id: OrderId): Promise<Order> {
  const order = await this.getOrder(id)
  if (order === null) {
    if (this.isLegacyId(id)) return await this.getLegacyOrder(id)   // NO
    return DEFAULT_ORDER                                            // NO
  }
  return order
}
```

The moment `ensureGet` has logic in it, the contract — "this returned, therefore the
value exists" — becomes unreliable, and callers downstream lose the type-level guarantee
they were trusting. If you need branching, that's a different method with a different
name.

### Trade-off acknowledged

`ensureGet` discards the type system's null-tracking at the call site. `getOrder`
returning `Order | null` forces the caller through a compiler-checked guard.
`ensureGetOrder` returning `Order` removes that evidence. The compiler now trusts the
function name to be honest about its contract.

This is fine when the name is honest and the implementation stays trivial (above). It
becomes a footgun when either drifts. The mitigation is the trivial-implementation rule
plus discipline at code review: `ensureGet` is a load-bearing claim, not a convenience.

---

## 13. Errors are raised where they're detected

Errors are thrown in the layer that detects the problem — not bubbled up to a top-level
handler for translation. The handler/controller layer stays thin: it delegates and returns.

```
✓
class OrderService {
  async cancel(orderId) {
    const order = await this.ensureGetOrder(orderId)
    if (order.status === 'shipped') {
      throw new OrderAlreadyShippedError(orderId)   // raised here
    }
    ...
  }
}

✗
class OrderController {
  async cancel(req, res) {
    const order = await this.service.getOrder(req.params.id)
    if (!order) return res.status(404).send('not found')          // translation
    if (order.status === 'shipped') return res.status(409).send('...') // translation
    ...
  }
}
```

**Two anti-patterns specifically:**

```
✗ no-op catch
try { doThing() } catch (e) { throw e }
// does nothing — error propagates identically without it

✗ returning errors as values
function process(x): Result | Error {
  if (bad(x)) return new Error('...')
  return new Result(...)
}
// callers can ignore the failure and treat it as success
```

Throw. Don't return errors. Don't catch-and-rethrow.

**Error message style:** plain, user-facing sentences for domain errors. Internal invariant
violations (programmer errors) can be terser and more technical — they shouldn't surface to
users anyway.

---

## 14. Explicit type annotations on let-bindings (strongly-typed languages)

Annotate when the right-hand side doesn't make the type obvious. The reader shouldn't have
to chase a return type back through the call site just to reason about the next several lines.

```
✓ explicit
const ctx: TradeContext | null = await this.loadTradingContext()
if (ctx === null) return

✓ omitted — type is obvious
const n = 5
const s = new String()
const sum = a + b      // both numeric

✗ inferable but opaque
const ctx = await this.loadTradingContext()   // what's the type?
```

**Annotate when:**
- The value comes from a cross-module call and its type matters downstream.
- The expression is a chain (`.read().await.as_ref().map(...)`) where the wrapping type
  is non-obvious.
- The binding flows through several lines.
- The same name could plausibly hold one of several types (Vec vs slice, owned vs reference).

**Skip when:**
- The RHS is a literal.
- A constructor names the type.
- The expression is trivially typed.
- The binding is used immediately on the next line.

Applies to Rust, TypeScript, Java, Kotlin, C#, Swift. Doesn't apply to dynamically-typed
languages — there the annotation is unverified at runtime.

---

## 15. Comments anchor weirdness, nothing else

**Default: no comment.** Most code does not need a comment. A well-named function called by
a well-named caller is self-documenting. `initUser` does not need `// Create a user` above
it. The vast majority of comments an LLM wants to write fall into this category and should
be deleted.

```
✗ restating the code
// Create a user
await initUser(input)

// Increment counter
counter += 1

// Check if order is shipped
if (order.status === 'shipped') { ... }

// Loop through items
for (const item of items) { ... }
```

These add no information. They make the file longer to scan and they go stale silently
when the code changes underneath them. They are noise.

**The exception is anchoring weirdness.** When the code contains something that will look
wrong to a future reader — a hardcoded value with no obvious source, a deliberate violation
of a nearby pattern, a workaround for an external constraint — leave a comment so the next
person doesn't "fix" it.

```
✓ hardcoded value that looks arbitrary
// Vendor caps batch size at 47 (not 50) — empirically tested 2024-03.
const BATCH_SIZE = 47

✓ deliberate violation of a pattern
// Sequential intentionally — vendor rate-limits to 1 req/sec per IP.
for (const id of ids) {
  await fetchVendor(id)
}

✓ workaround for external constraint
// API treats `null` as "use last value"; pass `undefined` to actually clear.
await vendor.updatePrice(productId, newPrice ?? undefined)

✓ business rule that isn't visible in the code
// Regulatory requirement: settlement window is 2 business days, not calendar days.
const settlementDeadline = addBusinessDays(tradeDate, 2)
```

**The test for a comment:** if a future reader, encountering this code cold, would look
at it and think "that looks wrong, let me fix it" — a comment prevents the mistake.
Otherwise, no comment.

**When something is deprecated, the comment says what to use instead** — not just that
it's deprecated.

**Commented-out code is sometimes left in place** for dead features or temporarily
disabled jobs. It's not cleaned up if there's a reasonable chance it gets re-enabled.
Mark it with a note explaining the condition for restoration.

---

## 16. Caching: stale-while-revalidate

Architectural default, not a style rule, but lives here for completeness:

1. On miss: compute, store, return.
2. On hit: return immediately. If stale, trigger a background recompute (fire-and-forget).

Callers never wait for a cache refresh. Staleness is tolerated for a short window. TTLs are
named constants. Cache keys are composed strings that encode every parameter they vary by.

---

## 17. Polling for async job results

When waiting for a background job to produce a result, poll with a bounded loop and an
attempt counter. Not recursive sleep. Always have a hard failure path when attempts are
exhausted.

```
✓
const MAX_ATTEMPTS = 30
const POLL_INTERVAL_MS = 1000

for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
  const result = await getResult(jobId)
  if (result !== null) return result
  await sleep(POLL_INTERVAL_MS)
}
throw new JobTimeoutError(jobId)
```

---

## 18. Async job dispatch via central mapping

Async jobs are dispatched by a named constant (enum value or string key), not by direct
function references scattered across the codebase. The key-to-handler mapping is declared
in one central place. Each handler lives in its own file, named after what it does.

Makes all job types visible at a glance and lets new ones be added without touching dispatch
infrastructure.

---

## 19. Two tiers of data access

- **Wrapper methods** for common CRUD — named, typed, reusable.
- **Direct storage-client access** for complex queries — aggregations, multi-filter finds,
  sorts, limits.

Complex queries go directly against the storage client rather than being forced through a
generic wrapper that can't express them cleanly. The wrapper is for convenience, not
enforcement.

---

## 20. Test structure

Function names describe the **behavior verified**, not the operation tested.

```
✓ recent_trade_is_not_stale
✓ cancelling_shipped_order_throws
✗ test_stale_trade_detection
✗ test_cancel_order
```

Test data is built by **private factory functions** inside the test module, not fixtures
or shared state. Each factory takes only the parameters that vary across test cases;
everything else is hardcoded to a sensible default.

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

---

## 21. Log format

Consistent structure across every log line:

```
[timestamp][context] message
```

- **timestamp**: millisecond-precision UTC
- **context**: subsystem name for the producing task (`btc`, `rest`, `worker`)
- **blank line after each entry** for terminal readability

Stdout for informational, stderr for errors. No logging framework.

---

## File ordering

Within a file, follow the language's idiomatic order. Don't invent a personal one.

---

## When to break these rules

**Working code beats beautiful code.** A horrible-looking function that ships is better
than an elegant rewrite that introduces a bug. Style and structure inconsistencies in
working code are left alone unless there's a reason to touch them.

**The bar for touching code is: does this need to change to ship the current task?**
If not, leave it. The extract-on-second-instance rule (§4) applies to code in the change
you're already making, not to pre-existing duplication elsewhere.

**Sometimes constraints force ugliness.** A workaround for a vendor bug, a perf-critical
loop, a contract you can't change — these may violate every rule in this document. That's
fine. Leave a comment (§15) explaining why, and move on.

---

## Anti-patterns: never do these

```
✗ try { ... } catch (e) { throw e }
   no-op — the error propagates identically without it

✗ return new Error(...)
   errors should be thrown, never returned as values

✗ if (someAsyncCall()) { ... }
   missing await — the Promise object is always truthy

✗ const result = doThing()
   ...and result is never read; either use it or don't capture it
```

---

## Intentional patterns that may look like mistakes

**Discarded results on broadcast/publish calls.** Side-effect calls to external systems
(Redis pub/sub and similar) intentionally do not check return values. These are
fire-and-forget — silent failure risk is accepted. Don't add error handling to these
call sites.

**Casing and typo mismatches at the entity layer.** See §7. These are load-bearing.
