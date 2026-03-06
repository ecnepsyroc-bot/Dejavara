# Railway Disaster Recovery Runbook

## When to Use This

- Railway PostgreSQL is corrupted or inaccessible
- Schema drift is causing mass 500 errors on the API
- Need to restore from a known-good backup
- Credential rotation cascade (see `cambium-railway-ops` skill)
- After a destructive deploy that overwrites table structure

## Prerequisites

- `RAILWAY_DATABASE_URL` environment variable set (get from Railway dashboard > Variables)
- `pg_dump` / `pg_restore` installed (PostgreSQL 17 preferred: `C:\Program Files\PostgreSQL\17\bin\`)
- Access to `C:\Backups\Railway\` or a recent dump file
- Railway dashboard access for credential verification

## Procedure 1: Take a Backup Before Any Risky Operation

**Script:** `Cambium/scripts/backup-railway.ps1`

```powershell
# Set connection string (get from Railway dashboard)
$env:RAILWAY_DATABASE_URL = 'postgresql://postgres:<pw>@trolley.proxy.rlwy.net:44567/railway'

# Run backup
.\Cambium\scripts\backup-railway.ps1
```

**Output:** `C:\Backups\Railway\cambium-railway-{yyyyMMdd-HHmmss}.dump`

**When:** Before pushing to main (Railway auto-deploys), before credential rotation, before schema changes.

## Procedure 2: Schema Drift — Check What's Missing

**Script:** `Cambium/scripts/check-railway-schema.sql`

Schema drift is the #1 production risk. EF Core SELECT queries include all mapped columns — if Railway DB is missing even one column, the entire query crashes with a generic 500 error.

```powershell
# Run schema check
$env:PGPASSWORD = "<pw>"
"C:\Program Files\PostgreSQL\17\bin\psql" `
  "sslmode=require sslrootcert=nonexistent host=trolley.proxy.rlwy.net port=44567 user=postgres dbname=railway" `
  -f Cambium\scripts\check-railway-schema.sql
```

**Look for:** Any column marked `*** MISSING ***`. Fix those before pushing code.

**SSL quirk:** `sslrootcert=nonexistent` is required because `root.crt` in `%APPDATA%/postgresql/` forces certificate verification that fails against Railway's proxy.

## Procedure 3: Schema Drift — Apply Emergency Repair

**Script:** `Cambium/scripts/fix-railway-emergency.sql`

Use this when Railway's DB got damaged by a deploy. The script is idempotent (safe to run multiple times).

```powershell
$env:PGPASSWORD = "<pw>"
"C:\Program Files\PostgreSQL\17\bin\psql" `
  "sslmode=require sslrootcert=nonexistent host=trolley.proxy.rlwy.net port=44567 user=postgres dbname=railway" `
  -f Cambium\scripts\fix-railway-emergency.sql
```

**What it does:**
1. Marks ALL known EF migrations as applied (prevents MigrateAsync destruction)
2. Creates missing tables (purchase_orders, po_line_items, etc.)
3. Adds missing columns to users table
4. Creates indexes

**After running:** The API startup generates the admin password hash at runtime, so just restart the Railway deployment.

## Procedure 4: Full Restore from Dump

Use when the database is unrecoverable and you need to restore from a backup file.

### Step 1: Terminate existing connections

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'railway' AND pid <> pg_backend_pid();
```

### Step 2: Restore

```powershell
$env:PGPASSWORD = "<pw>"
"C:\Program Files\PostgreSQL\17\bin\pg_restore" `
  --clean --no-acl --no-owner `
  --host=trolley.proxy.rlwy.net --port=44567 `
  --username=postgres --dbname=railway `
  "C:\Backups\Railway\cambium-railway-XXXXXXXX-XXXXXX.dump"
```

**Flags explained:**
- `--clean` — Drop existing objects before restore
- `--no-acl` — Skip access privileges (Railway manages these)
- `--no-owner` — Skip ownership (everything runs as `postgres`)

### Step 3: Verify

Run the schema check (Procedure 2) to confirm all columns are present.

## Procedure 5: Credential Rotation (Railway Password Regenerated)

When Railway regenerates the PostgreSQL password:

1. **Get new `DATABASE_URL`** from Railway dashboard > Variables
2. **Update local environment:** `$env:RAILWAY_DATABASE_URL = '<new_url>'`
3. **Verify connection:** Run schema check (Procedure 2)
4. **Update `cambium_sync` role** if it exists (used by SyncCli)

**Variable Reference rule:** `DATABASE_URL` in Railway must reference `${{Postgres.DATABASE_URL}}` — never hardcode. See `cambium-railway-ops` skill for full rotation procedures.

**BCrypt + bash trap:** BCrypt password hashes contain `$` signs (`$2a$11$...`). Never pass them via inline bash commands — use `.sql` files with `psql -f` instead.

## Known Railway State

- **109 of 164 tables present** (55 missing = unshipped features, expected)
- **Critical tables:** `users` (14 cols), `factory_orders` (18 cols)
- **`cambium_sync` role** exists (password stored in Railway Variables)
- **Auto-deploy:** Every `git push origin main` triggers a Railway redeploy
- **Connection:** `trolley.proxy.rlwy.net:44567` (external proxy)
- **Migrations:** All marked as applied via `__EFMigrationsHistory` — `MigrateAsync` is disabled

## Post-Recovery Verification Checklist

- [ ] Run `check-railway-schema.sql` — no `*** MISSING ***` columns
- [ ] API responds: `curl https://cambium-production.up.railway.app/api/health`
- [ ] Login works: test with a known user account
- [ ] Check Railway deploy logs for startup errors
- [ ] Laminate inventory accessible: `curl https://cambium-production.up.railway.app/api/laminates/stats`
- [ ] Schema counts match expectations (109 tables, 14 user columns, 18 FO columns)
