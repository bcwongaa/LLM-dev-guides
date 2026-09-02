---
name: observability
description: "Logs, metrics, traces, request IDs, DB and pool health, data-health checks."
---

Law: `GUIDES_ROOT/guides/observability/RULES.md` (`GUIDES_ROOT` from `AGENTS.md`).
Read **only** the ranges you need: `Read(path, offset=START, limit=END-START+1)`.
Examples live in `REFERENCE.md` beside it.

7-10     Complete
11-21    1. Greenfield: instrument early
22-39    2. Logs
40-43    3. Correlation / request IDs
44-47    4. Metrics (minimum bar)
48-51    5. Tracing
52-55    6. Database and pool health
56-79    7. Data observability: when the data can be wrong while the system is up
80-83    8. Health: liveness vs readiness
84-89    9. What agents must do
90-102   Never
103-106  Looks wrong, is intentional
107-110  When to break
111-113  Done

Guide and local convention outrank this skill; never paraphrase law from memory.
Protocol still applies: `GUIDES_ROOT/guides/protocol/RULES.md`.
