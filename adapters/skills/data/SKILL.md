---
name: data
description: "Schema, migrations, keys, nullability, invariants, money, time, Postgres/Mongo/Redis."
---

Law: `GUIDES_ROOT/guides/data/RULES.md` (`GUIDES_ROOT` from `AGENTS.md`).
Read **only** the line ranges you need. Claude: `Read(path, offset=START, limit=END-START+1)`.
Shell: `sed -n 'START,ENDp' path`. `INDEX.tsv` beside it indexes the REFERENCE files the same way.

1-6    (preamble)
7-10   Complete
11-18  1. One meaning per field
19-22  2. Validate at trust boundaries
23-30  3. Invariants in the right place
31-34  4. Identifiers
35-38  5. Units, precision, and rounding
39-42  6. Time has different meanings
43-46  7. Normalize; earn every JSON field
47-57  8. Postgres
58-61  9. Mongo
62-65  10. Redis
66-69  11. Lifecycle, archive, and deletion
70-73  12. Migrations change data, not just files
74-77  13. Transactions and concurrent writers
78-88  Never
89-92  Looks wrong, is intentional
93-96  When to break
97-99  Done

RULES wins over REFERENCE on any conflict. Guide and local convention outrank this skill;
never paraphrase law from memory.
Protocol still applies: `GUIDES_ROOT/guides/protocol/RULES.md`.
