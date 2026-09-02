---
name: data
description: "Schema, migrations, keys, nullability, invariants, money, time, Postgres/Mongo/Redis."
---

Law: `GUIDES_ROOT/guides/data/RULES.md` (`GUIDES_ROOT` from `AGENTS.md`).
Read **only** the ranges you need: `Read(path, offset=START, limit=END-START+1)`.
Examples live in `REFERENCE.md` beside it.

9-16   1. One meaning per field
17-20  2. Validate at trust boundaries
21-28  3. Invariants in the right place
29-32  4. Identifiers
33-36  5. Units, precision, and rounding
37-40  6. Time has different meanings
41-44  7. Normalize; earn every JSON field
45-55  8. Postgres
56-59  9. Mongo
60-63  10. Redis
64-67  11. Lifecycle, archive, and deletion
68-71  12. Migrations change data, not just files
72-75  13. Transactions and concurrent writers
76-86  Never
87-90  Looks wrong, is intentional
91-94  When to break
95-97  Done

Guide and local convention outrank this skill; never paraphrase law from memory.
Protocol still applies: `GUIDES_ROOT/guides/protocol/RULES.md`.
