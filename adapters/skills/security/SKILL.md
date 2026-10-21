---
name: security
description: "Auth, permissions, PII, secrets, IDOR and tenancy, injection, SSRF, supply chain."
---

Law: `GUIDES_ROOT/guides/security/RULES.md` (`GUIDES_ROOT` from `AGENTS.md`).
Read **only** the line ranges you need. Claude: `Read(path, offset=START, limit=END-START+1)`.
Shell: `sed -n 'START,ENDp' path`. `INDEX.tsv` beside it indexes the REFERENCE files the same way.

1-8      (preamble)
9-12     Complete
13-21    1. Secrets
22-30    2. Authentication
31-39    3. Authorization
40-48    4. IDOR, tenancy, query scoping
49-52    5. PII
53-61    6. Passwords and credentials
62-73    7. Injection, XSS, CSRF
74-82    8. SSRF
83-91    9. Dependencies / supply chain
92-100   10. Admin / privileged
101-104  11. Webhooks
105-108  12. What agents must ask
109-118  Never
119-122  Looks wrong, is intentional
123-126  When to break
127-129  Done

RULES wins over REFERENCE on any conflict. Guide and local convention outrank this skill;
never paraphrase law from memory.
Protocol still applies: `GUIDES_ROOT/guides/protocol/RULES.md`.
