---
name: contracts
description: "HTTP endpoints, events, DTOs, versioning, pagination, idempotency, wire error shapes."
---

Law: `GUIDES_ROOT/guides/contracts/RULES.md` (`GUIDES_ROOT` from `AGENTS.md`).
Read **only** the ranges you need: `Read(path, offset=START, limit=END-START+1)`.
`INDEX.tsv` beside it indexes `REFERENCE.md` the same way.

9-12     Complete
13-22    1. Transport: external vs internal
23-26    2. Default external style: boring REST/JSON
27-30    3. DTOs are not domain or DB models
31-34    4. Validate at the boundary
35-38    5. Errors at the wire
39-42    6. Success bodies
43-46    7. Versioning and breaking changes
47-50    8. Idempotency and retries
51-54    9. Pagination
55-58    10. Identifiers on the wire
59-62    11. Partial updates (PATCH)
63-66    12. Events and message payloads
67-70    13. Webhooks and third-party callbacks
71-74    14. Authn / authz at the boundary (light)
75-78    15. Service-to-service contracts
79-89    Never
90-93    Looks wrong, is intentional
94-99    When to break
100-102  Done

Guide and local convention outrank this skill; never paraphrase law from memory.
Protocol still applies: `GUIDES_ROOT/guides/protocol/RULES.md`.
