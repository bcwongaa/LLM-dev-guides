# L8 — Security and Secrets

Hard rules so agents do not ship secrets in git, trust the client’s `role`, open IDOR
holes, or invent crypto. Broad coverage, still **rule-dense** — not a compliance course or
pen-test methodology manual.

**The goal:** reduce the blast radius of LLM-generated code: credentials, authz, PII,
injection, and unsafe outbound calls. Security is part of “done,” not a later audit.

## Scope of this guide

**In scope**

- Secrets handling and config
- Authentication and authorization boundaries
- IDOR / tenancy / resource ownership
- PII minimums (practical, not full legal policy)
- Passwords and credential storage
- Injection, XSS, CSRF
- SSRF and user-controlled URLs
- Dependencies / supply chain hygiene
- Admin and privileged actions
- Webhooks and untrusted inbound (with L5)

**Out of scope**

| Concern | Where it lives |
|---|---|
| Wire principal placement (light) | **L5** |
| Don’t log secrets (also) | **L6** — L8 owns the broader secret/PII law |
| Schema-level access quirks | **L4** |
| Deploy of secret material | **L9** (config by env; human ships prod) |
| Standing security architecture decisions | **L10** |
| Full threat models, SOC2, legal retention schedules | Human / org process |
| Framework choice for auth libraries | **L3** + author |

If unsure whether something is security-sensitive: **ask** (L0).

## What “complete” means

A change touching auth, user data, money, admin, or external input is complete when:

1. No secrets committed or shipped to clients.
2. Sensitive actions are **server-authorized** for the principal — not client-claimed.
3. Resource access is **scoped** (no IDOR-by-default).
4. Untrusted input cannot inject SQL/HTML/commands; outbound fetches are guarded.
5. New dependencies follow hygiene rules (including delay on brand-new packages).
6. Tests cover authz/IDOR regressions when those paths change (L7).

---

## 1. Secrets

**Secrets never belong in git as real values**, in frontend bundles, or in logs (L6).

| OK | Not OK |
|---|---|
| Env vars / platform secret manager at runtime | API keys in source |
| CI secrets store | Secrets in Docker layers as the only copy of truth without manager |
| **`.env.example`** with **placeholders** for easier setup | Committed `.env` with real tokens |
| Docs: “set `STRIPE_SECRET` in env” | Slack-pasted prod keys into the repo |

```
✓  .env.example → STRIPE_SECRET=sk_test_xxx_placeholder
✓  read secrets from process env / vault at boot
✗  sk_live_… in code, PR, or client JavaScript
✗  commit .env because “local only”
```

Rotate if a secret may have leaked. Prefer short-lived credentials when the platform allows.

Agent rule: if you need a secret to run something, **ask** or use existing project env —
do not invent or commit one.

---

## 2. Authentication

- Establish the **principal** on the server (session, bearer validation, etc. — project
  convention).
- **Never** treat body/query fields like `userId`, `isAdmin`, `role` as proof of identity.
- Session tokens and cookies: `HttpOnly` / `Secure` / `SameSite` per project norms; do not
  store long-lived tokens in localStorage without an explicit approved design.
- Logout / invalidation must mean something server-side when sessions are server-backed.

```
✓  middleware verifies session → principal on request context
✗  if (body.role === 'admin') allow
✗  “security by obscure URL”
```

---

## 3. Authorization (every sensitive action)

**Server-side check on every sensitive action.** Middleware that only checks “logged in”
is not enough for resource operations.

```
✓  load order by id **and** owner/tenant matches principal (or explicit admin grant)
✓  canCancel(order, principal) before mutate
✗  GET /orders/:id with no ownership filter
✗  trust client-sent organizationId without membership check
```

Fail **closed** when authz is uncertain (deny), not open.

---

## 4. IDOR, tenancy, and query scoping

**Every query that loads or mutates a user/tenant resource must be scoped** to what the
principal may access.

```
✓  WHERE id = $1 AND user_id = $principal
✓  admin path uses separate authz + audit, not “skip the filter”
✗  findById(req.params.id) with no principal constraint
✗  list endpoints that return other tenants’ rows
```

Multi-tenant systems: tenant id comes from the **principal** (or verified membership), not
from an untrusted header the client can forge — unless that header is cryptographically
bound by your gateway and documented.

---

## 5. PII and sensitive data

- **Collect the minimum** needed for the feature.
- **Do not log PII freely** (L6); prefer opaque ids in logs.
- At rest: hash or encrypt **sensitive** fields when the product stores them (passwords
  always hashed; tokens encrypted or vaulted; payment raw PANs → never store if a PSP can
  hold them).
- Access to exports/dumps of personal data is an **admin/privileged** path (see §10).

Full legal retention schedules are out of scope; when retention is product-critical, ask
the author rather than inventing policy.

---

## 6. Passwords and credentials

- **Never store plaintext passwords.**
- Use a **proven** library or IdP (argon2/bcrypt/scrypt via maintained libs, or hosted auth).
- **No home-grown crypto** (hashing, JWT “encryption”, token formats).
- Reset flows: single-use, time-limited tokens; do not email passwords.

```
✓  IdP or well-known password hasher with parameters reviewed once
✗  MD5/SHA1 password “hash”
✗  implement your own JWT crypto
```

---

## 7. Injection, XSS, CSRF

| Threat | Rule |
|---|---|
| **SQL / NoSQL injection** | Parameterized queries / bound params only; never string-build queries from user input |
| **Command injection** | No shelling out with user strings; allowlisted args if unavoidable |
| **XSS** | Encode/escape output; prefer framework auto-escape; never `dangerouslySetInnerHTML` with untrusted HTML without a sanitizer policy |
| **CSRF** | For cookie-session browser APIs, use the **framework’s CSRF** (or SameSite + careful design); state-changing GETs forbidden |

```
✓  orm/sql`…${userId}` or $1 bindings
✗  `WHERE id = '${req.params.id}'`
✗  render user HTML raw into admin pages
```

---

## 8. SSRF and outbound fetches

**Do not fetch user-controlled URLs** without an allowlist or equivalent guard (block
link-local, metadata IPs, internal networks unless explicitly required and locked down).

```
✓  webhook egress only to known vendor hosts
✓  image URL host allowlist
✗  GET req.body.url and server-side fetch whatever it says
✗  “preview any link” without SSRF controls
```

Same spirit for redirect targets and file importers.

---

## 9. Dependencies and supply chain

- Prefer the **existing stack** and known libraries (L3).
- **Do not add architecture-sized or sensitive auth/crypto deps without asking.**
- Prefer **delaying brand-new packages**: if a dependency is **fresh** (very new publish /
  low adoption), **prefer waiting ~3 days** (and sanity-check the package) before adding it
  — reduces “just published malware / hijack” risk. Not a perfect control; still verify
  name, publisher, and need.
- Lockfiles committed where the ecosystem uses them; don’t casually force unpinned latest
  on sensitive apps.
- Remove unused deps when you touch that area (no drive-by across the monorepo).

```
✓  use project’s existing HTTP client / auth lib
✓  wait and re-check a one-day-old utility package
✗  npm install cool-auth-2 with 12 downloads, published today, mid-feature
✗  copy-paste a Gist crypto helper into production
```

---

## 10. Admin and privileged actions

- **Separate authz** from normal user paths (role/permission checked server-side).
- **Audit log** sensitive admin actions (who, what, when, target ids) — without logging
  secrets.
- No `isAdmin: true` from the client body.
- Admin tools that run dangerous jobs follow L9 (approval, no silent data destruction).

```
✓  requireAdmin(principal) + write entry on balance adjust
✗  hide /admin in the UI and assume URLs are enough
```

---

## 11. Webhooks and external callbacks

Align **L5**: verify signatures, treat body as untrusted, handle idempotently.  
Do not disable verification “for testing” in production configs.

---

## 12. What agents must ask

Always ask (also L0) before:

- New auth system / IdP / session model  
- Changing password/crypto approach  
- Broadening who can access PII or money  
- Disabling authz, CSRF, or webhook verification  
- Storing new classes of sensitive PII  
- Adding a high-risk dependency or “temporary” secret in repo  

---

## 13. Anti-patterns

```
✗ secrets in git, images as sole secret store, or frontend
✗ trust client role / userId / tenant header without binding
✗ findById without ownership/tenant scope
✗ string-built SQL or shell with user input
✗ plaintext passwords or home-grown crypto
✗ log tokens, passwords, full card data
✗ server-side fetch of arbitrary user URLs
✗ brand-new unvetted dependency for auth
✗ admin power via obscurity
✗ disable security controls in prod to “unblock”
```

---

## 14. Intentional patterns that may look like mistakes

**`.env.example` in git.** Correct — placeholders only, never real secrets.

**Waiting days before adopting a brand-new npm package.** Intentional supply-chain caution.

**Denying by default when authz is ambiguous.** Correct fail-closed behavior.

**IdP instead of local passwords.** Often better; not required if local auth is proven and
hashed correctly.

**Strict IDOR checks that make “global admin list” a separate code path.** Clearer than a
boolean that skips filters ad hoc.

---

## When to break these rules

- Author explicitly approves a controlled exception (e.g. temporary internal tool on a
  locked network) — document blast radius and expiry.
- Emergency incident response may rotate secrets and tighten access faster than normal
  process — still no committing secrets; still prefer human approval for prod data access.
- Legacy brownfield: do not expand insecure patterns; fix on touch when in scope (L0/L1).

Working secure defaults beat theoretical perfect compliance docs agents ignore.

---

## Done checklist

- [ ] No real secrets in git/client; `.env.example` placeholders only if present
- [ ] Principal established server-side; client roles not trusted
- [ ] Sensitive actions authorized server-side
- [ ] Resource queries scoped (IDOR/tenant)
- [ ] PII minimized; not freely logged; sensitive at-rest handling considered
- [ ] Passwords/credentials via proven approach — no plaintext / home-grown crypto
- [ ] Parameterized queries; safe output encoding; CSRF where cookie sessions apply
- [ ] No unguarded user-controlled server-side fetch (SSRF)
- [ ] New deps justified; fresh packages delayed ~3 days when practical
- [ ] Admin paths: separate authz + audit
- [ ] Webhooks verified when applicable
- [ ] Security-sensitive tests added/updated (L7)
- [ ] Asked on L0 security / auth model changes

## Relationship to other layers

| Topic | Layer |
|---|---|
| Always ask on security | **L0** |
| Code shape | **L1** |
| Stack / packages | **L3** |
| Data at rest shape | **L4** |
| Wire auth light, webhooks | **L5** |
| Telemetry redaction | **L6** |
| Authz/IDOR tests | **L7** |
| Config by env, prod ship | **L9** |
| ADRs for major auth choices | **L10** |
