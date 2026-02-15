# PostgreSQL Failover Sync

One-way database sync pattern for hot standby / disaster recovery.

## When to Use
- Primary → Replica sync for failover readiness
- Cloud backup of on-prem PostgreSQL
- Cross-environment data mirroring (dev → staging, prod → DR)

## Architecture

```
┌─────────────────┐     pg_dump      ┌─────────────────┐
│  PRIMARY (SSOT) │  ──────────────► │  REPLICA (DR)   │
│  Cambium-server │   every N min    │  Railway/Cloud  │
│  PostgreSQL 16  │                  │  PostgreSQL 17  │
└─────────────────┘                  └─────────────────┘
```

**SSOT = Single Source of Truth.** All writes go to primary. Replica is read-only mirror.

## The Schema Nuke Pattern

Standard `pg_restore --clean` fails when:
- Tables have changed structure
- Constraints block drops
- Sequences are out of sync

**Solution:** Drop entire schema, restore fresh.

```sql
-- Kill active connections first
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'railway' AND pid <> pg_backend_pid();

-- Nuke and restore
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
-- Then pg_restore
```

## Sync Script (Windows Batch)

```batch
@echo off
echo %date% %time% - Starting sync >> C:\tmp\sync-log.txt

REM === DUMP PRIMARY ===
set PGPASSWORD=<primary_password>
"C:\Program Files\PostgreSQL\16\bin\pg_dump" ^
  -U <user> -p <port> -d <database> ^
  -Fc -f C:\tmp\backup.dump

if %ERRORLEVEL% NEQ 0 (
    echo %date% %time% - Dump FAILED >> C:\tmp\sync-log.txt
    exit /b 1
)

REM === KILL REPLICA CONNECTIONS ===
set PGPASSWORD=<replica_password>
"C:\Program Files\PostgreSQL\16\bin\psql" ^
  -h <replica_host> -p <replica_port> -U postgres -d <database> ^
  -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '<database>' AND pid <> pg_backend_pid();" ^
  >> C:\tmp\sync-log.txt 2>&1

REM === DROP AND RESTORE ===
"C:\Program Files\PostgreSQL\16\bin\psql" ^
  -h <replica_host> -p <replica_port> -U postgres -d <database> ^
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" ^
  >> C:\tmp\sync-log.txt 2>&1

"C:\Program Files\PostgreSQL\16\bin\pg_restore" ^
  --no-owner --single-transaction ^
  -h <replica_host> -p <replica_port> -U postgres -d <database> ^
  C:\tmp\backup.dump 2>> C:\tmp\sync-log.txt

echo %date% %time% - Sync completed >> C:\tmp\sync-log.txt
```

## Key Flags

| Flag | Purpose |
|------|---------|
| `-Fc` | Custom format (compressed, parallel-ready) |
| `--no-owner` | Skip ownership (cloud DBs use different users) |
| `--single-transaction` | Atomic restore (all or nothing) |
| `--clean` | Drop before create (use with schema nuke for reliability) |
| `--if-exists` | Don't error on missing objects |

## Cross-Auth (JWT Token Sharing)

For tokens issued on primary to validate on replica:

1. **JWT signing keys MUST match** on both systems
2. Set same `Jwt:Key` in both appsettings / environment
3. `Issuer` and `Audience` must also match

```json
{
  "Jwt": {
    "Key": "<same-256-bit-key-on-both>",
    "Issuer": "Cambium",
    "Audience": "CambiumUsers"
  }
}
```

## Scheduling

**Windows Task Scheduler:**
- Action: Start a program
- Program: `C:\tmp\cambium-sync.bat`
- Trigger: Every 20 minutes (or desired RPO)
- Run whether user is logged on or not

**Linux cron:**
```bash
*/20 * * * * /path/to/sync.sh >> /var/log/sync.log 2>&1
```

## Gotchas

1. **EF Migrations table** — Exclude if replica runs its own migrations:
   ```
   --exclude-table='__EFMigrationsHistory'
   ```

2. **Connection limits** — Railway free tier has low connection limits. Kill before restore.

3. **Password escaping** — Special characters in PGPASSWORD may need escaping in batch files.

4. **Short paths** — Use `C:\Progra~1\Postgr~1\16\bin\` to avoid space issues in batch.

5. **Version mismatch** — pg_dump from newer version won't restore to older. OK to restore UP (PG16 → PG17).

## Recovery Procedure

When primary fails:
1. Point DNS/load balancer to replica
2. Promote replica to read-write (if using streaming replication)
3. For sync-based: replica is already independent, just update connection strings

## Post-Sync Verification

**Always verify critical columns after sync.** Schema drift causes API 500 errors.

### Quick Verification Query

```sql
-- Check specific columns exist
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name IN ('jobs', 'users', 'resources')
ORDER BY table_name, ordinal_position;

-- Check row counts
SELECT schemaname, relname, n_live_tup
FROM pg_stat_user_tables
WHERE n_live_tup > 0
ORDER BY n_live_tup DESC;
```

### Fix Missing Columns

```sql
-- Add missing column (idempotent)
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS fo_folder_path varchar(500);
```

### When psql Isn't Available

Use Node.js `pg` package. See `postgres-remote-ops` skill for details.

```bash
node -e "const{Client}=require('pg');const c=new Client({connectionString:'postgresql://...'});c.connect().then(()=>c.query('SELECT COUNT(*) FROM jobs')).then(r=>console.log(r.rows)).finally(()=>c.end())"
```

## Monitoring

Check sync health:
```sql
-- On replica: when was last sync?
SELECT MAX(updated_at) FROM some_frequently_updated_table;
```

Log review:
```batch
type C:\tmp\sync-log.txt | findstr /i "fail error"
```

## Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| API 500 "column X does not exist" | Column added to SSOT after backup | `ALTER TABLE ADD COLUMN IF NOT EXISTS` |
| Restore hangs | Active connections on replica | Kill connections before restore |
| Permission denied | Different user on replica | Use `--no-owner` flag |
| Foreign key errors | Table order wrong | Use `-Fc` format + `--single-transaction` |
| Sync script times out | OpenClaw gateway limit | Use batch file + Task Scheduler |
