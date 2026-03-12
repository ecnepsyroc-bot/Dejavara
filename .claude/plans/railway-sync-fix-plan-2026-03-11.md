# Railway Sync Fix Plan

**Created:** 2026-03-11
**Status:** ✅ COMPLETED (2026-03-11 21:12)
**Scope:** Fix 32 FK constraint warnings + prevent future permission issues + improve monitoring

## Implementation Summary

**External review identified:** Phases 1-4 were already implemented. Only remaining issue was Phase 3b covering only 3 of 69 FK-referenced tables.

**Fix applied:** Expanded Phase 3b to pre-create PKs for all 69 FK-referenced tables before post-data restore.

**Result:**
- FK constraint warnings: 32 → 0
- Expected "multiple PK" warnings: 69 (harmless — PKs created in Phase 3b, then post-data tries again)
- Sync completes successfully with all constraints intact

---

---

## Problem Summary

### Issue 1: FK Constraint Restore Failures (32 warnings)

When `pg_restore` runs on Railway, it fails to create 32 foreign key constraints with errors like:

```
ERROR: there is no unique constraint matching given keys for referenced table "organizations"
```

**Root Cause:** The restore process attempts to create FK constraints before the referenced PK/unique constraints exist. This is a **restore ordering issue**, not a schema issue — the constraints exist on cambium-server.

**Affected FK Relationships:**
| FK Table | FK Column | References | Issue |
|----------|-----------|------------|-------|
| `source_documents` | `organization_id` | `organizations.id` | PK not yet created |
| `user_email_settings` | `user_id` | `users.user_id` | PK not yet created |
| `user_preferences` | `user_id` | `users.user_id` | PK not yet created |
| `audit_logs` | `user_id` | `users.user_id` | PK not yet created |
| `directory_contacts` | `organization_id` | `organizations.id` | PK not yet created |
| ... (27 more) | ... | ... | ... |

### Issue 2: shop_user Permission Loss

Migrations run as `postgres` user, creating tables owned by `postgres`. The `shop_user` (used by sync script) loses access to new tables until manually granted.

### Issue 3: Silent Sync Failures

The sync script logs "Dump FAILED" without capturing the actual PostgreSQL error, making diagnosis difficult.

---

## Proposed Solution

### Phase 1: Fix pg_restore Constraint Ordering

**Problem:** pg_restore creates constraints in an order that fails on Railway.

**Solution:** Use pg_restore's `--section` flag to restore in explicit order:

```batch
REM Phase 1: Pre-data (tables, sequences, but NOT constraints)
pg_restore --no-owner --no-privileges --section=pre-data -h %RAILWAY_HOST% ...

REM Phase 2: Data
pg_restore --no-owner --no-privileges --section=data -h %RAILWAY_HOST% ...

REM Phase 3: Post-data (indexes, constraints, triggers)
pg_restore --no-owner --no-privileges --section=post-data -h %RAILWAY_HOST% ...
```

**Alternative:** Use `--disable-triggers` to defer constraint checks during restore, then manually enable:

```batch
pg_restore --no-owner --no-privileges --disable-triggers -h %RAILWAY_HOST% ...
```

**Recommended approach:** The `--section` method is cleaner and more explicit.

### Phase 2: Add Automatic Permission Grants

**Problem:** New tables created by migrations don't have `shop_user` permissions.

**Solution:** Add a post-migration hook in `CambiumDbContext.cs` or create a dedicated migration.

**Option A: Post-migration SQL in startup (Preferred)**

Add to `Program.cs` after `Database.Migrate()`:

```csharp
// After migrations, ensure shop_user has access to all objects
if (!app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<CambiumDbContext>();
    await db.Database.ExecuteSqlRawAsync(@"
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO shop_user;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO shop_user;
    ");
}
```

**Option B: Explicit migration**

Create migration `20260311_GrantShopUserPermissions.cs`:

```csharp
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.Sql(@"
        DO $$
        BEGIN
            IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'shop_user') THEN
                GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO shop_user;
                GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO shop_user;
                ALTER DEFAULT PRIVILEGES IN SCHEMA public
                    GRANT ALL PRIVILEGES ON TABLES TO shop_user;
                ALTER DEFAULT PRIVILEGES IN SCHEMA public
                    GRANT ALL PRIVILEGES ON SEQUENCES TO shop_user;
            END IF;
        END $$;
    ");
}
```

**Recommendation:** Use Option A (Program.cs) because:
- Runs on every startup, catches any permission gaps
- Doesn't require Railway to have shop_user role
- Idempotent — safe to run multiple times

### Phase 3: Improve Sync Script Error Logging

**Current script problem:**
```batch
if %ERRORLEVEL% NEQ 0 (
    echo %date% %time% - Dump FAILED >> C:\tmp\sync-log.txt
    exit /b 1
)
```

**Fixed script:**
```batch
REM Capture pg_dump output and errors
C:\Progra~1\Postgr~1\18\bin\pg_dump -U shop_user -p 5432 -d cambium -Fc -f C:\tmp\cambium-backup.dump 2>&1 | findstr /V "^$" >> C:\tmp\sync-log.txt
if %ERRORLEVEL% NEQ 0 (
    echo %date% %time% - pg_dump FAILED with code %ERRORLEVEL% >> C:\tmp\sync-log.txt
    exit /b 1
)

REM ... similar for pg_restore
C:\Progra~1\Postgr~1\18\bin\pg_restore --no-owner --no-privileges --section=pre-data ... 2>&1 >> C:\tmp\sync-log.txt
C:\Progra~1\Postgr~1\18\bin\pg_restore --no-owner --no-privileges --section=data ... 2>&1 >> C:\tmp\sync-log.txt
C:\Progra~1\Postgr~1\18\bin\pg_restore --no-owner --no-privileges --section=post-data ... 2>&1 >> C:\tmp\sync-log.txt
```

### Phase 4: Add Sync Health Monitoring

**Option A: Healthcheck endpoint in CambiumApi**

Add endpoint that compares Railway vs local timestamps:

```csharp
[HttpGet("/api/health/sync")]
public async Task<IActionResult> CheckSyncHealth()
{
    var lastUpdate = await _db.Projects
        .MaxAsync(p => p.UpdatedAt);

    var staleness = DateTime.UtcNow - lastUpdate;

    return Ok(new {
        lastUpdate,
        stalenessMinutes = staleness.TotalMinutes,
        healthy = staleness.TotalMinutes < 60
    });
}
```

**Option B: Pi-based monitoring script**

Add to Pi's cron to check Railway staleness:

```bash
#!/bin/bash
# /mnt/data/scripts/check-railway-sync.sh

LAST_UPDATE=$(psql -h trolley.proxy.rlwy.net -p 44567 -U cambium_sync -d railway \
    -t -c "SELECT MAX(updated_at) FROM projects;")

STALENESS_HOURS=$(( ($(date +%s) - $(date -d "$LAST_UPDATE" +%s)) / 3600 ))

if [ $STALENESS_HOURS -gt 2 ]; then
    echo "ALERT: Railway sync is $STALENESS_HOURS hours stale" | \
        /mnt/data/scripts/send-notification.sh
fi
```

---

## Implementation Files

| File | Action | Description |
|------|--------|-------------|
| `cambium-server:C:\tmp\sync-to-railway.cmd` | MODIFY | Improve restore ordering + error logging |
| `Cambium/Cambium/src/Cambium.Api/Program.cs` | MODIFY | Add post-migration permission grants (line ~1163) |
| `Cambium/Cambium/src/Cambium.Api/Controllers/HealthController.cs` | MODIFY | Add sync health endpoint to existing controller |
| `Phteah-pi:/mnt/data/scripts/check-railway-sync.sh` | CREATE | Add monitoring script |

---

## Detailed Implementation

### File 1: `sync-to-railway.cmd` (Full Replacement)

```batch
@echo off
setlocal enabledelayedexpansion

set LOG=C:\tmp\sync-log.txt
set DUMP=C:\tmp\cambium-backup.dump
set RAILWAY_HOST=trolley.proxy.rlwy.net
set RAILWAY_PORT=44567
set RAILWAY_USER=cambium_sync
set RAILWAY_DB=railway
set RAILWAY_PASS=WugWOsTpdDzUuS6Y4KuGCWTLFUuggOZH
set PG_BIN=C:\Program Files\PostgreSQL\18\bin

echo ============================================== >> %LOG%
echo %date% %time% - Starting sync >> %LOG%

REM ============================================
REM PHASE 1: Dump from cambium-server (PG 16)
REM ============================================
set PGPASSWORD=shop_password
echo %date% %time% - Dumping from cambium-server... >> %LOG%
"%PG_BIN%\pg_dump" -U shop_user -p 5432 -d cambium -Fc -f %DUMP% 2>> %LOG%
if !ERRORLEVEL! NEQ 0 (
    echo %date% %time% - pg_dump FAILED with exit code !ERRORLEVEL! >> %LOG%
    exit /b 1
)
echo %date% %time% - Dump completed successfully >> %LOG%

REM ============================================
REM PHASE 2: Prepare Railway (drop and recreate schema)
REM ============================================
set PGPASSWORD=%RAILWAY_PASS%
echo %date% %time% - Preparing Railway schema... >> %LOG%
"%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% -c "REVOKE CONNECT ON DATABASE railway FROM PUBLIC; SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'railway' AND pid <> pg_backend_pid(); DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >> %LOG% 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %date% %time% - Schema prep FAILED >> %LOG%
    exit /b 1
)

REM ============================================
REM PHASE 3: Restore in sections (correct ordering)
REM ============================================
echo %date% %time% - Restoring pre-data (tables, types)... >> %LOG%
"%PG_BIN%\pg_restore" --no-owner --no-privileges --section=pre-data -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% %DUMP% 2>> %LOG%

echo %date% %time% - Restoring data... >> %LOG%
"%PG_BIN%\pg_restore" --no-owner --no-privileges --section=data -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% %DUMP% 2>> %LOG%

echo %date% %time% - Restoring post-data (indexes, constraints)... >> %LOG%
"%PG_BIN%\pg_restore" --no-owner --no-privileges --section=post-data -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% %DUMP% 2>> %LOG%

REM Note: pg_restore returns non-zero for warnings, so we don't fail on it

REM ============================================
REM PHASE 4: Re-enable connections
REM ============================================
echo %date% %time% - Re-enabling connections... >> %LOG%
"%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% -c "GRANT CONNECT ON DATABASE railway TO PUBLIC;" >> %LOG% 2>&1

echo %date% %time% - Sync completed >> %LOG%
exit /b 0
```

### File 2: `Program.cs` Addition

Add in **SCOPE 4** (post-migration scope), after the admin seeding block ends at line ~1162, before the data verification block:

```csharp
    // Grant shop_user permissions on all tables (only matters on cambium-server)
    // This catches any tables created by migrations that shop_user can't access
    try
    {
        await dbContext.Database.ExecuteSqlRawAsync(@"
            DO $$
            BEGIN
                IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'shop_user') THEN
                    EXECUTE 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO shop_user';
                    EXECUTE 'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO shop_user';
                END IF;
            END $$;
        ");
        Log.Information("shop_user permissions verified");
    }
    catch (Exception ex)
    {
        // Expected to fail on Railway (no shop_user role) - don't block startup
        Log.Debug(ex, "shop_user grant skipped (expected on Railway)");
    }
```

### File 3: `HealthController.cs` (Add Method to Existing Controller)

The existing `HealthController.cs` already has endpoints for `/api/health`, `/api/health/db`, and `/api/health/status`.

**Add this method** after the existing `GetStatus()` method (around line 148):

```csharp
    /// <summary>
    /// Sync freshness check - how stale is the data on this instance?
    /// </summary>
    [HttpGet("sync")]
    public async Task<IActionResult> GetSyncHealth()
    {
        try
        {
            var lastProjectUpdate = await _context.Projects
                .MaxAsync(p => (DateTime?)p.UpdatedAt) ?? DateTime.MinValue;

            var lastLaminateUpdate = await _context.Laminates
                .MaxAsync(l => (DateTime?)l.UpdatedAt) ?? DateTime.MinValue;

            var lastUpdate = lastProjectUpdate > lastLaminateUpdate
                ? lastProjectUpdate
                : lastLaminateUpdate;

            var staleness = DateTime.UtcNow - lastUpdate;

            return Ok(new
            {
                lastDataUpdate = lastUpdate,
                stalenessMinutes = Math.Round(staleness.TotalMinutes, 1),
                stalenessHours = Math.Round(staleness.TotalHours, 2),
                healthy = staleness.TotalMinutes < 60,
                status = staleness.TotalMinutes < 30 ? "fresh"
                       : staleness.TotalMinutes < 60 ? "stale"
                       : "critical",
                timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Sync health check failed");
            return StatusCode(503, new
            {
                status = "error",
                error = ex.Message,
                timestamp = DateTime.UtcNow
            });
        }
    }
```

**Note:** Uses existing `_context` (CambiumDbContext) and `_logger` fields from the controller.

---

## Rollback Plan

If the new sync script causes issues:

1. SSH to cambium-server: `ssh cambium-server-tunnel`
2. Restore original script:
   ```batch
   copy C:\tmp\sync-to-railway.cmd.backup C:\tmp\sync-to-railway.cmd
   ```
3. Trigger manual sync: `C:\tmp\sync-to-railway.cmd`

---

## Testing Plan

### Before Deployment

1. **Test new sync script locally** (on cambium-server):
   ```batch
   copy C:\tmp\sync-to-railway.cmd C:\tmp\sync-to-railway.cmd.backup
   REM ... apply new script ...
   C:\tmp\sync-to-railway.cmd
   type C:\tmp\sync-log.txt
   ```

2. **Verify FK constraints restored**:
   ```sql
   -- On Railway
   SELECT COUNT(*) FROM pg_constraint WHERE contype = 'f';
   -- Should match cambium-server count
   ```

3. **Verify data integrity**:
   ```sql
   -- Compare row counts
   SELECT 'projects' as tbl, COUNT(*) FROM projects
   UNION ALL
   SELECT 'organizations', COUNT(*) FROM organizations
   UNION ALL
   SELECT 'users', COUNT(*) FROM users;
   ```

### After Deployment

1. Wait for next scheduled sync (20 minutes)
2. Check sync log: `ssh cambium-server-tunnel "type C:\tmp\sync-log.txt"`
3. Verify no "FAILED" in recent entries
4. Test health endpoint: `curl https://cambium-production.up.railway.app/api/health/sync`

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Sync script breaks | Low | High | Backup original, test before deploy |
| pg_restore --section fails | Low | Medium | Falls back to current behavior |
| Program.cs grant fails | Low | Low | Wrapped in try/catch, logs warning |
| Health endpoint exposes data | None | N/A | Only returns timestamps, no PII |

---

## Success Criteria

1. Sync log shows "Sync completed" with no "FAILED" entries
2. Railway database has 0 missing FK constraints (vs. 32 currently)
3. Future migrations automatically grant shop_user access
4. `/api/health/sync` returns `healthy: true` when sync is current

---

**This plan is ready for external review before execution. Copy to Claude.ai for adversarial review.**