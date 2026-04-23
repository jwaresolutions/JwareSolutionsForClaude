# Domain: Authentication & Security
**Loaded when:** Agent is implementing login, signup, token management, authorization checks, or API key handling.
**Key concern:** Token storage. Storing tokens in the wrong place (localStorage, URL parameters) is the most common auth vulnerability in web apps.

---

## Token-Based Auth (JWT)

**JWT structure:** `header.payload.signature` -- base64-encoded, NOT encrypted.

**Rules:** Always validate signature. Always check `exp`. Never put secrets in payload. Keep access tokens short-lived (15 min) + long-lived refresh token.

### Token Storage

| Location | Security | Use for |
|---|---|---|
| `httpOnly` + `Secure` + `SameSite` cookie | Best | Web app access tokens |
| In-memory variable | Good (lost on refresh) | SPA short-lived tokens |
| `localStorage` / `sessionStorage` | XSS vulnerable | Never for auth tokens |
| URL parameters | Visible in logs | Never |

### Refresh Token Flow

Login issues access (15 min) + refresh (7 days) tokens. On 401, client sends refresh token to `/auth/refresh` for new access token. Refresh tokens must be: stored server-side (revocable), rotated on each use, bound to device.

## Password Handling

| Algorithm | Status |
|---|---|
| `argon2id` | Best -- memory-hard, GPU-resistant |
| `bcrypt` | Good -- widely supported |
| `SHA-256` / `MD5` | Broken. Never use for passwords. |

Minimum 8 chars, no maximum. No composition rules. Check against breached lists (HIBP). Rate-limit login: 5 attempts per 15 min per account.

## OAuth 2.0

**Authorization Code Flow:** Redirect to provider -> user authenticates -> callback with `code` -> server exchanges code for tokens with `client_secret`.

**PKCE (SPAs, mobile):** Generate `code_verifier`, send `SHA256(code_verifier)` as `code_challenge`. No client secret needed.

**Always validate the `state` parameter** to prevent CSRF on OAuth flow.

## Authorization

Check permissions server-side on every request. Client-side checks are UX only. Deny-by-default. Test that user A cannot access user B's data.

```python
@app.get("/admin/users")
async def list_users(user: User = Depends(get_current_user)):
    if "admin" not in user.roles:
        raise HTTPException(403, "Insufficient permissions")
```

## API Key Management

Generate with `secrets.token_urlsafe(32)`. Store hashed (SHA-256). Return raw key once, never again. Validate with `hmac.compare_digest` (timing-safe).

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Tokens in localStorage | XSS steals them | httpOnly cookies |
| JWT without signature check | Anyone forges tokens | Always verify signature |
| Not checking `exp` | Revoked users keep access | Check expiration every request |
| SHA/MD5 for passwords | Cracked in seconds | argon2id or bcrypt |
| Timing attack on comparison | Leaks valid prefix info | `hmac.compare_digest` |
| No rate limit on login | Brute force | Rate limit by account + IP |
| Client-only authorization | Trivially bypassed | Enforce server-side |
| Secrets in git | Exposed forever | Env vars, secret managers |
| No `state` in OAuth | CSRF on callback | Always validate state param |
