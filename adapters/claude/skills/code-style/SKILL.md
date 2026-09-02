---
name: code-style
description: "Code shape, naming, decomposition, helpers, error placement, comments. Nearly every code edit."
---

Law: `GUIDES_ROOT/guides/code-style/RULES.md` (`GUIDES_ROOT` from `AGENTS.md`).
Read **only** the ranges you need: `Read(path, offset=START, limit=END-START+1)`.
Examples live in `REFERENCE.md` beside it.

7-14     Complete / post-code
15-25    1. Table of contents
26-29    2. One kind of work
30-33    3. Sequential first
34-43    4. Name-first decomposition
44-54    5. Where helpers live
55-60    6. `_` prefix
61-86    7. Naming
87-90    8. Null vs absent
91-94    9. Explicit construction defaults
95-98    10. Typed update objects
99-102   11. Conversion at entity boundaries
103-115  12. `get` / `ensureGet`
116-128  13. Errors where detected
129-132  14. Annotate opaque bindings
133-138  15. Comments
139-145  Relocated — do not restate
146-149  File order
150-157  When to break
158-167  Never
168-176  Looks wrong, is intentional

Guide and local convention outrank this skill; never paraphrase law from memory.
Protocol still applies: `GUIDES_ROOT/guides/protocol/RULES.md`.
