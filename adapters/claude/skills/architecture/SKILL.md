---
name: architecture
description: "System layout: modules vs deployables, folders, new service or package, data ownership, caching."
---

Law: `GUIDES_ROOT/guides/architecture/RULES.md` (`GUIDES_ROOT` from `AGENTS.md`).
Read **only** the ranges you need: `Read(path, offset=START, limit=END-START+1)`.
Examples live in `REFERENCE.md` beside it.

7-10   Complete
11-19  Thinking order
20-28  Logical vs physical
29-32  New deployable
33-36  Hybrid layout
37-40  Prefer duplication
41-44  Data ownership
45-48  Frontend and backend
49-52  How engines talk
53-58  Always ask (structural)
59-62  Brownfield
63-66  Caching: stale-while-revalidate
67-70  Polling for async job results
71-74  Async job dispatch
75-78  When to break
79-88  Never
89-92  Looks wrong, is intentional
93-96  Done
97-99  Other layers

Guide and local convention outrank this skill; never paraphrase law from memory.
Protocol still applies: `GUIDES_ROOT/guides/protocol/RULES.md`.
