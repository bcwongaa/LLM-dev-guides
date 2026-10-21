---
name: stack
description: "Language, framework, storage, or major dependency choice. Greenfield picks are never autonomous."
---

Law: `GUIDES_ROOT/guides/stack/RULES.md` (`GUIDES_ROOT` from `AGENTS.md`).
Read **only** the line ranges you need. Claude: `Read(path, offset=START, limit=END-START+1)`.
Shell: `sed -n 'START,ENDp' path`. `INDEX.tsv` beside it indexes the REFERENCE files the same way.

1-6      (preamble)
7-14     Consult vs continue
15-18    Decision order
19-30    Greenfield hard rules
31-54    Language decision tree
55-64    Language field notes
65-68    Frontend and thin glue
69-72    Backend frameworks
73-92    Storage
93-96    Errors
97-100   Tooling
101-104  Layout
105-110  When to break
111-116  Done
117-128  Never
129-132  Looks wrong, is intentional

RULES wins over REFERENCE on any conflict. Guide and local convention outrank this skill;
never paraphrase law from memory.
Protocol still applies: `GUIDES_ROOT/guides/protocol/RULES.md`.
