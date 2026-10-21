---
name: release
description: "Feature flags, expand/contract migrations, rollback, deploy safety, hotfix. Human ships prod."
---

Law: `GUIDES_ROOT/guides/release/RULES.md` (`GUIDES_ROOT` from `AGENTS.md`).
Read **only** the line ranges you need. Claude: `Read(path, offset=START, limit=END-START+1)`.
Shell: `sed -n 'START,ENDp' path`. `INDEX.tsv` beside it indexes the REFERENCE files the same way.

1-8      (preamble)
9-12     Relocated — do not restate
13-16    Complete
17-38    1. Expand / contract
39-53    2. API and behavior rollout
54-67    3. Feature flags and runtime config
68-81    4. Rollback reality
82-90    5. Environments and artifacts
91-101   6. What agents may do vs must ask
102-110  7. Hotfix / emergency
111-116  8. Release checklist
117-120  When to break
121-134  Never
135-146  Looks wrong, is intentional
147-149  Done

RULES wins over REFERENCE on any conflict. Guide and local convention outrank this skill;
never paraphrase law from memory.
Protocol still applies: `GUIDES_ROOT/guides/protocol/RULES.md`.
