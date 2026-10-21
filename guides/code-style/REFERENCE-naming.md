# Code style — naming reference

Binding surface: [`RULES.md`](RULES.md). RULES wins on any conflict. This file holds the rationale
and examples for §7 Naming and §12 `get` / `ensureGet`, split out of [`REFERENCE.md`](REFERENCE.md)
by topic. Section numbers match `RULES.md` and `REFERENCE.md`.

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

Magic numbers and durations get a named constant at the top of the file. The name makes
the value and unit readable at the use site — `FIFTEEN_MINUTES` is fine; a semantic name
(`SESSION_TIMEOUT`) is not required when usage context already says what it's for. The sin
is the bare inline value.

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

### Named bindings: locals and fields

The rest of §7 binds function names, type suffixes, prefixes, and constants. It does not
reach a `val`, a field, or a destructured pair. An unguided model emits the corpus median:
`store`, `record`, `data`, `item`, `first`. Those names work if you just wrote the surrounding
ten lines. They fail on a grep hit, a stack frame, a blame line, a diff hunk, or a 40-line
agent read. The next reader — human or model — never wrote the file and will not load the
module. Names are the fragment of the theory that survives that cut.

This is a **scope budget**, not a taste for long identifiers.

**Class-scope wears the type.** A field is alive for every method, so the programming sort
stays: `ledgerStore`. Never bare `store`, `service`, `db`.

**Function-scope wears the spoken domain word.** `ensureGetUser` → `user`, not `userEntity`.
One in scope, no role. Two in scope, role first: `fromAccount` / `toAccount`. Drop
Entity/Dto/Record/Service. The unit is the domain's word (`walletIdentifier` is one noun),
not stacked type morphemes.

```
✓  class LedgerService(private val ledgerStore: LedgerStore)
✓  val account = ensureRecord(accountId)                  // one in scope
✓  val fromAccount = ensureRecord(fromAccountId)          // two in scope
✗  private val store: LedgerStore
✗  val record = ensureRecord(accountId)
✗  val source = ensureRecord(sourceId)                    // role, no noun
✗  val fromExchangeAccountRecordDto = ...                 // suffixes, no information
```

**Canonical-name handoff.** A binding that exists only to produce the canonical value gives
up the plain noun: `function f(_user) { const user = normalize(_user) }`. The `_` says "not
the one you want"; the unprefixed name is reserved for the survivor. Not `rawUser` — the
value is not always raw. Not `tmpUser` — that changes the meaning. Not `user_` — trailing
sigils fight several languages. The prefixed binding dies immediately: if `_user` is still
read at the end of the function, it was never a handoff. This is a TS rendering; elsewhere
use the language's idiom (shadowing / rebinding). Distinct from the §6 method prefix and
from unused-parameter `_`.

**Leftover IO may stay generic.** `result` of `insertOne` returned on the next line, `res`/`data`
of fetch, `x` in a lambda, `cache` of redis bytes. When the value lives and is a domain object,
generic is a miss: `record` in a ledger service. When it lives as a named IO receipt, prefix it:
`depositResult`.

**Position names only after a callee that defines the order.**
`val (firstId, secondId) = ordered(idA, idB)` is lock order. `first` / `second` before that
named order are tuple slots.

**Too long is also a miss.** `destinationWalletIdentifier` is role plus a domain noun; every
word earns its place. `fromExchangeAccountRecordDto` is three sorts glued together. Length is
allowed; suffix piles are not.

**Match the file.** If the DTO already says `destination`, locals say `destination…`. A fresh
file may use domain speech (`fromAccount`). Uniqueness is not a goal — do not invent a second
vocabulary to make a grep unique. Brownfield: rename `store` only in lines the fix already
touches (never-list override, §When to break); leave the rest of the file alone.

Worked miss (compliant with every other §7 sub-rule, still wrong):

```
class LedgerService(private val store: LedgerStore) {
    fun deposit(accountId: AccountId, amount: Money) {
        val record = ensureRecord(accountId)
        store.put(record.copy(...))
    }
    fun transfer(sourceId: AccountId, destinationId: AccountId, amount: Money) {
        val source = ensureRecord(sourceId)
        val destination = ensureRecord(destinationId)
    }
}
```

`store.put(record.copy(...))` on a blame line is a riddle. The type that would answer is one
declaration up, which is the line the fragment dropped.

### Preserve typos and casing in external schemas

When a typo ships in a persistent schema (DB field, API contract), it stays in all new code
that touches that field. Silently correcting it creates a mismatch with live data. Same for
casing: if a DB column is `snake_case` and the code is TS, mirror the schema exactly in the
entity layer and apply lint suppressions if needed. The inconsistency is intentional and
load-bearing — document it where it first appears.

The translation to clean domain types happens at the boundary (see §11), not by renaming
fields silently in the entity layer.

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
