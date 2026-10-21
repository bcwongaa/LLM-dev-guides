# Setup

Fixture: `evals/fixtures/billing/`. It has customers, invoices, a public customer DTO
(`api.CustomerDTO`), and an existing authorization boundary (`authz.RequireOwner`). The runner
installs the current consumer adapters with `GUIDES_ROOT` pointing at this suite.

The fixture intentionally does not define:

- whether invoice count or paid amount drives loyalty;
- whether the discount is retroactive, reversible, or time-limited;
- who may read or change the discount;
- whether the value is derived or persisted.
