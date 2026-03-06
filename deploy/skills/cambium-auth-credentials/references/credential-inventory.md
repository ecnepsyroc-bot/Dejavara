# Credential Inventory

Complete inventory of credentials in the Cambium ecosystem. **Read this before rotating any credential.**

## Credential Table

| Credential | Type | Lives In | Rotates When | Blast Radius | Recovery Procedure |
|------------|------|----------|--------------|--------------|-------------------|
| **Postgres superuser** | DB password | Railway Variables via `${{Postgres.DATABASE_URL}}` | Manual regeneration in Railway Database tab | **Zero** if Variable Reference in use; **full outage** if hardcoded | Ensure `DATABASE_URL = ${{Postgres.DATABASE_URL}}` in Cambium Variables |
| **cambium_sync** | DB role password | External scripts only | Manual | Backup sync scripts fail; API unaffected | Re-create role: `CREATE ROLE cambium_sync WITH LOGIN PASSWORD 'WugWOsTpdDzUuS6Y4KuGCWTLFUuggOZH' SUPERUSER;` |
| **JWT signing key** | HMAC-SHA256 key | `JWT_SECRET_KEY` env var or `Jwt:Key` config | Manual | All tokens invalid — **all users must re-login** | Redeploy with new key; no other recovery needed |
| **Admin password** | BCrypt hash | `users` table `password_hash` column | `ADMIN_DEFAULT_PASSWORD` env var on startup OR UI change | Admin locked out of Railway | Set env var + redeploy + remove env var immediately |
| **Cloudflare tunnel token** | Auth token | Cloudflare dashboard → Tunnel config | Manual (rare) | Shop LAN unreachable from external networks | Regenerate in Cloudflare dashboard; update tunnel config |
| **Railway session** | OAuth token | Developer machine (`~/.railway`) | Manual logout or token expiry | Can't deploy or manage Railway services | Re-authenticate via `railway login` |

## Detailed Breakdown

### Postgres Superuser

**What it is:** The `postgres` user password for Railway PostgreSQL.

**Where it lives:** Railway Database service. The Cambium service accesses it via Variable Reference `${{Postgres.DATABASE_URL}}`.

**When it rotates:**
- Manually, via Railway dashboard → Database → Settings → Regenerate Password
- Never automatically (Railway doesn't auto-rotate)

**Blast radius:**
- **If using Variable Reference:** Zero. The reference auto-updates.
- **If hardcoded:** Full outage. `28P01 password authentication failed` errors until fixed.

**Recovery:**
1. Check if `DATABASE_URL` in Cambium Variables is `${{Postgres.DATABASE_URL}}`
2. If not, delete and recreate with the Variable Reference
3. Redeploy

### cambium_sync Role

**What it is:** A PostgreSQL role with a **fixed password** for external backup/sync scripts.

**Where it lives:** Created directly in Railway PostgreSQL. Password documented in MEMORY.md.

| Property | Value |
|----------|-------|
| Username | `cambium_sync` |
| Password | `WugWOsTpdDzUuS6Y4KuGCWTLFUuggOZH` |
| Privileges | SUPERUSER (for pg_dump/pg_restore) |

**Used by:**
- Pi backup script (`/mnt/data/backups/cambium/backup-from-railway.sh`)
- cambium-server sync scheduled task

**NOT used by:**
- Cambium API (uses postgres superuser via DATABASE_URL)

**When it rotates:** Only if manually changed or Railway DB is recreated.

**Blast radius:** Backup scripts fail silently. API unaffected.

**Recovery:**
```sql
-- Connect to Railway PostgreSQL as postgres user
CREATE ROLE cambium_sync WITH LOGIN PASSWORD 'WugWOsTpdDzUuS6Y4KuGCWTLFUuggOZH' SUPERUSER;
```

### JWT Signing Key

**What it is:** The symmetric key used to sign and verify JWT tokens (HS256).

**Where it lives:**
1. `JWT_SECRET_KEY` env var (production)
2. `Jwt:Key` in appsettings (development fallback)

**When it rotates:** Only if manually changed.

**Blast radius:** All existing JWT tokens become invalid. Users see 401 errors and must re-login.

**Recovery:** No recovery needed — users re-login and get new tokens. Just ensure all instances use the same key.

**Best practice:** Set `JWT_SECRET_KEY` once in Railway Variables and never change it.

### Admin Password

**What it is:** The BCrypt password hash for the `admin` user in the `users` table.

**Where it lives:** PostgreSQL `users` table, `password_hash` column.

**When it changes:**
1. User changes via UI (Settings → Change Password)
2. `ADMIN_DEFAULT_PASSWORD` env var set on startup (emergency override)

**Blast radius:** Admin user locked out. Cannot access admin functions on Railway.

**Recovery:**
1. Set `ADMIN_DEFAULT_PASSWORD=<new-password>` in Railway Variables
2. Wait for redeploy
3. Verify login works
4. **Remove the env var immediately**
5. Redeploy again to confirm removal

See [admin-seeding.md](admin-seeding.md) for full details.

### Cloudflare Tunnel Token

**What it is:** Authentication token for the Cloudflare Tunnel connecting shop LAN to Cloudflare.

**Where it lives:** Cloudflare dashboard → Zero Trust → Access → Tunnels.

**When it rotates:** Manually, if tunnel is deleted/recreated.

**Blast radius:** Shop floor devices can't reach Railway API. External users unaffected (they go directly to Railway).

**Recovery:** Regenerate tunnel in Cloudflare dashboard; update `cloudflared` config on shop server.

### Railway Session (Developer)

**What it is:** OAuth token for Railway CLI authentication.

**Where it lives:** `~/.railway/` on developer machine.

**When it expires:** After extended inactivity or manual logout.

**Blast radius:** Can't run `railway` CLI commands. Can still access Railway dashboard via browser.

**Recovery:**
```bash
railway login
# Opens browser for OAuth flow
```

## Pre-Rotation Checklist

Before rotating any credential:

1. [ ] Identify the blast radius from the table above
2. [ ] Identify who/what will be affected
3. [ ] Schedule rotation during low-traffic period if blast radius > 0
4. [ ] Have recovery procedure ready
5. [ ] Test recovery procedure if possible (staging environment)
6. [ ] Notify affected parties if user-facing
7. [ ] Monitor for errors after rotation
