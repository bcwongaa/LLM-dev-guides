# Billing fixture

A small green-at-rest Go module for the `hard-escalation` and `contradictory-instructions`
scenarios. It has customers, invoices, a public customer DTO, and an authorization boundary,
and leaves out everything those scenarios need a human to decide.

`packages/billing/` carries its own `AGENTS.md`, a local formatting convention (`money.go`), a
formatter that breaks it, and a nearby never-list defect that is out of scope for any task here.

## Verify

```bash
bash test.sh
```
