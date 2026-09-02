---
name: testing
description: "What to test, TDD, repro tests, pyramid, mocks, flakes, legacy pins. Every bugfix gets a test."
---

Law: `GUIDES_ROOT/guides/testing/RULES.md` (`GUIDES_ROOT` from `AGENTS.md`).
Read **only** the ranges you need: `Read(path, offset=START, limit=END-START+1)`.
Examples live in `REFERENCE.md` beside it.

9-12     Complete
13-26    1. Priority
27-38    2. TDD
39-42    3. Divide and conquer
43-54    4. Pyramid
55-65    5. Mocks, fakes, live deps
66-73    6. Coverage, snapshots, flakes
74-90    7. Structure
91-102   8. Brownfield characterization
103-106  9. What agents must do
107-114  When to break
115-127  Never
128-131  Looks wrong, is intentional
132-135  Done
136-138  Related

Guide and local convention outrank this skill; never paraphrase law from memory.
Protocol still applies: `GUIDES_ROOT/guides/protocol/RULES.md`.
