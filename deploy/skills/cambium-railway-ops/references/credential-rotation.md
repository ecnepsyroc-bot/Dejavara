# Railway Credential Rotation

## Postgres Superuser Password

### Regeneration

1. Railway dashboard > Postgres service > Database tab > **Regenerate**
2. If `DATABASE_URL` is a Variable Reference (`${{Postgres.DATABASE_URL}}`): Cambium auto-picks up the new password on next deploy. **No action needed.**
3. If `DATABASE_URL` was hardcoded: **immediate outage**. Fix by setting the Variable Reference and triggering a redeploy.

### Blast Radius

| Scenario | Impact |
|----------|--------|
| Variable Reference | Zero — auto-resolves on next deploy |
| Hardcoded string | Full outage until manually updated |

## JWT Signing Key

**Location:** `JWT_SECRET_KEY` Railway environment variable

**Rotation:** Manual — change the value in Railway Variables, trigger redeploy.

**Blast radius:** All existing JWT tokens become invalid. Users must re-login. Cookie-based sessions are unaffected (they use DataProtection keys, not JWT).

## Admin Password Recovery

When `ADMIN_DEFAULT_PASSWORD` env var is set (non-empty), startup **always overwrites** the admin password and clears lockout. There is no hash-gate or conditional logic — this is a deliberate emergency override.

### Recovery Procedure

1. Set `ADMIN_DEFAULT_PASSWORD=<new-password>` in Railway Variables
2. Redeploy (automatic on variable change)
3. Watch logs for: `"Admin password reset from ADMIN_DEFAULT_PASSWORD env var"`
4. Test login at `cambium.luxifysystems.com`
5. **Remove the env var immediately** — it resets password on every deploy

### Blast radius

Admin password overwritten on every deploy while the env var exists. No impact on other users.

## cambium_sync Role

**Purpose:** External backup/sync scripts only. Not used by the Cambium API.

**Rotation:** Manual — update the password in Railway Postgres, then update any scripts that use this role.

**Blast radius:** Backup sync fails. No impact on application.

## Cloudflare Tunnel

**Purpose:** Shop LAN access to Cambium API.

**Rotation:** Via Cloudflare dashboard.

**Blast radius:** Shop floor can't reach Cambium until tunnel is re-established.

## Security Rules

- **Never paste Railway credentials into chat sessions** — use Railway CLI or dashboard
- **Never store credentials in git** — use environment variables
- **BCrypt hashes contain `$` signs** — never pass through bash inline, use `.sql` files with `psql -f`
- **Railway PG password rotates** — always check dashboard if auth fails
