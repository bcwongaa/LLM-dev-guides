# Security

Hard rules so agents do not ship secrets, trust the client `role`, open IDOR holes, or invent crypto. Rationale: [`REFERENCE.md`](REFERENCE.md). New auth / security boundary is **always-human**: [`../protocol/RULES.md`](../protocol/RULES.md).

**Scope `[suite-default]`:** Secrets handling, authn/authz, IDOR / tenancy, PII, credentials, injection / XSS / CSRF, SSRF, supply chain, admin, webhooks. Not a compliance course or pen-test methodology.

Do not restate: wire principal / webhooks → [contracts](../contracts/RULES.md); log redaction → [observability](../observability/RULES.md); schema access → [data](../data/RULES.md); auth-lib / stack → [stack](../stack/RULES.md); secret deploy / dangerous jobs → release; ADRs → decisions; authz tests → testing. Unsure if sensitive → **ask** (protocol).

## Complete `[suite-default]`

Auth, user data, money, admin, or external input is done when: no secrets committed or shipped to clients; sensitive actions are **server-authorized** for the principal; access is **scoped**; no SQL/HTML/command injection; outbound fetches guarded; new-dep hygiene (delay brand-new packages); authz/IDOR tests when those paths change (`testing`).

## 1. Secrets `[common]`

**Secrets never belong in git as real values**, in frontend bundles, or in logs. Runtime: env / vault / CI. `.env.example` placeholders only. Rotate if leaked; prefer short-lived credentials. Need a secret to run something → **ask** or use existing project env — do not invent or commit one.

```
✓  .env.example → STRIPE_SECRET=sk_test_xxx_placeholder · read env / vault at boot
✗  sk_live_… in code, PR, or client JS · commit .env because “local only”
```

## 2. Authentication `[common]`

Establish the **principal** on the server (session, bearer — project convention). **Never treat body/query** fields like `userId`, `isAdmin`, `role` as proof of identity. Cookies: `HttpOnly` / `Secure` / `SameSite` per project norms. No long-lived tokens in localStorage without an approved design. Server-backed logout must invalidate server-side.

```
✓  middleware verifies session → principal on request context
✗  if (body.role === 'admin') allow · “security by obscure URL”
```

## 3. Authorization `[common]`

Server-side check on **every sensitive action**. “Logged in” is not enough for resource operations. Fail **closed** when authz is uncertain.

```
✓  load by id **and** owner/tenant matches principal · canCancel(order, principal) before mutate
✗  GET /orders/:id with no ownership filter · trust client organizationId
```

## 4. IDOR, tenancy, query scoping `[common]`

Every query that loads or mutates a user/tenant resource **must be scoped** to what the principal may access. Tenant id from the **principal** (or verified membership), not an untrusted client header — unless the gateway cryptographically binds it and that is documented.

```
✓  WHERE id = $1 AND user_id = $principal · admin = separate authz + audit, not “skip the filter”
✗  findById(req.params.id) with no principal constraint · list other tenants’ rows
```

## 5. PII `[suite-default]`

**Collect the minimum** needed for the feature. Do not log PII freely (observability); prefer opaque ids. At rest: hash or encrypt **sensitive** fields (passwords always hashed; tokens encrypted or vaulted; raw PANs → never store if a PSP can hold them). Personal-data exports/dumps are an **admin/privileged** path (§10). Product-critical retention → ask; do not invent legal policy.

## 6. Passwords and credentials `[common]`

**Never store plaintext** passwords. Proven library or IdP (argon2/bcrypt/scrypt via maintained libs, or hosted auth). **No home-grown crypto**. Reset: single-use, time-limited tokens; do not email passwords.

```
✓  IdP or well-known password hasher with parameters reviewed once
✗  MD5/SHA1 password “hash” · implement your own JWT crypto
```

## 7. Injection, XSS, CSRF `[common]`

- **SQL / NoSQL:** Parameterized queries / bound params only; never string-build from user input
- **Command:** no shelling out with user strings; allowlisted args if unavoidable
- **XSS:** encode/escape; prefer framework auto-escape; never `dangerouslySetInnerHTML` with unsanitized HTML
- **CSRF:** cookie-session browser APIs use framework CSRF (or SameSite + careful design); no state-changing GETs

```
✓  orm/sql`…${userId}` or $1 bindings
✗  `WHERE id = '${req.params.id}'` · render user HTML raw into admin pages
```

## 8. SSRF `[common]`

**Do not fetch user-controlled URLs** without an allowlist or equivalent guard (block link-local, metadata IPs, internal networks unless required and locked down). Same for redirect targets and file importers.

```
✓  webhook egress only to known vendor hosts · image URL host allowlist
✗  GET req.body.url and fetch it · “preview any link” without SSRF controls
```

## 9. Dependencies / supply chain `[suite-default]`

Prefer the **existing stack** ([stack](../stack/RULES.md)). Do not add architecture-sized or sensitive auth/crypto deps without asking. Fresh packages (new publish / low adoption): prefer **waiting ~3 days**; still verify name, publisher, need. Commit lockfiles; don’t force unpinned latest on sensitive apps. Remove unused deps on touch — no drive-by.

```
✓  project’s existing HTTP client / auth lib · wait and re-check a one-day-old package
✗  npm install cool-auth-2 published today, 12 downloads · paste a Gist crypto helper
```

## 10. Admin / privileged `[common]`

**Separate authz** from normal user paths (server-side). **Audit log** sensitive admin actions (who, what, when, target ids) — no secrets. No `isAdmin: true` from the client. Dangerous admin jobs follow `release` (approval, no silent destruction).

```
✓  requireAdmin(principal) + write entry on balance adjust
✗  hide /admin in the UI and assume URLs are enough
```

## 11. Webhooks `[common]`

Align contracts: **verify signatures**, treat body as untrusted, handle idempotently. Do not disable verification “for testing” in production configs.

## 12. What agents must ask `[suite-default]`

Always ask — protocol; new auth / security boundary remains **always-human** — before: **New auth system** / IdP / session model; changing password/crypto; broadening who can access PII or money; disabling authz, CSRF, or webhook verification; storing new classes of sensitive PII; a high-risk dependency or “temporary” secret in repo. Root asks; subagents escalate. Parents must not rubber-stamp new auth.

## Never `[suite-default]`

```
✗ secrets in git, image-only store, or frontend · trust client role / userId / tenant header
✗ findById without ownership/tenant scope · string-built SQL or shell with user input
✗ plaintext passwords or home-grown crypto · log tokens, passwords, full card data
✗ fetch arbitrary user URLs · brand-new unvetted auth dep · admin power via obscurity
✗ disable security controls in prod to “unblock”
```

## Looks wrong, is intentional `[suite-default]`

**`.env.example` in git** — placeholders only. **Waiting days** before a brand-new package — supply-chain caution. **Denying by default** when authz is ambiguous — fail-closed. **IdP instead of local passwords** — often better; local auth is fine if proven and hashed. **Strict IDOR** with a separate “global admin list” path — clearer than a skip-filter boolean.

## When to break `[suite-default]`

Author approves a **controlled exception** (e.g. temporary internal tool on a locked network) — document blast radius and expiry. Incident response may rotate secrets and tighten access faster than normal — still no committing secrets; still prefer human approval for prod data access. Brownfield: do not expand insecure patterns; fix on touch when in scope. Breaking always-human on new auth without a human is not a valid exception.

## Done `[suite-default]`

Complete, plus: admin authz + audit; webhooks verified when applicable; **Security-sensitive tests** added/updated (`testing`); asked on protocol security / auth model changes.
