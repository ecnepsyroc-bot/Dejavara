# Railway Sync Hardening Plan

**Created:** 2026-03-11
**Status:** READY FOR EXTERNAL REVIEW
**Scope:** Address 4 critical + 4 medium issues found in nuclear audit
**Estimated effort:** 2-3 hours implementation + testing

---

## Executive Summary

The Railway sync script (`sync-to-railway.cmd`) successfully synchronizes data but has architectural weaknesses that could cause data loss, security breaches, or silent failures. This plan addresses issues in priority order with minimal disruption to the working sync.

---

## Issues Addressed

| Priority | Issue | Current State | Target State |
|----------|-------|---------------|--------------|
| P0 | Credentials in plaintext | Passwords in script, readable by all users | Credentials in restricted file or env |
| P0 | No concurrent run protection | Overlapping syncs corrupt data | Lock file prevents overlap |
| P0 | Line 33 non-atomic | Partial failure leaves Railway broken | Separate statements with rollback |
| P0 | No PK auto-discovery | Manual updates when schema changes | Dynamic PK query at runtime |
| P1 | Log file unbounded | 5.2M lines/year growth | Daily rotation, 7-day retention |
| P1 | No connection timeout | Hangs indefinitely on network issues | 60-second timeout |
| P1 | No error check on Phase 3b | PK failures silent | Explicit error handling |
| P1 | GRANT CONNECT unconditional | Broken state exposed to users | Only re-enable on success |

---

## Implementation Phases

### Phase 1: Lock File Protection (15 min)

**Goal:** Prevent concurrent sync runs from corrupting data.

**Implementation:**

Add at script start (after `setlocal`):
```batch
set LOCKFILE=C:\tmp\sync-railway.lock

REM Check for existing lock
if exist %LOCKFILE% (
    for /f %%A in (%LOCKFILE%) do set LOCKPID=%%A
    tasklist /FI "PID eq !LOCKPID!" 2>nul | find "!LOCKPID!" >nul
    if !ERRORLEVEL! EQU 0 (
        echo %date% %time% - Sync already running (PID !LOCKPID!), exiting >> %LOG%
        exit /b 0
    ) else (
        echo %date% %time% - Stale lock found, removing >> %LOG%
        del %LOCKFILE%
    )
)

REM Create lock with current PID
echo %~dp0 > %LOCKFILE%
for /f "tokens=2" %%A in ('tasklist /FI "IMAGENAME eq cmd.exe" /FO LIST ^| find "PID:"') do (
    echo %%A > %LOCKFILE%
    goto :gotpid
)
:gotpid
```

Add at script end (before `exit /b 0`):
```batch
REM Release lock
if exist %LOCKFILE% del %LOCKFILE%
```

**Testing:**
1. Start sync manually
2. While running, start second sync
3. Verify second sync exits immediately with log message

---

### Phase 2: Credential Isolation (20 min)

**Goal:** Remove plaintext passwords from script.

**Option A: Separate credentials file (RECOMMENDED)**

Create `C:\tmp\.sync-credentials` (restricted permissions):
```batch
set SHOP_PASSWORD=shop_password
set RAILWAY_PASS=WugWOsTpdDzUuS6Y4KuGCWTLFUuggOZH
```

Modify script:
```batch
REM Load credentials from restricted file
if not exist C:\tmp\.sync-credentials (
    echo %date% %time% - FATAL: Credentials file missing >> %LOG%
    exit /b 1
)
call C:\tmp\.sync-credentials
```

Set permissions:
```powershell
icacls "C:\tmp\.sync-credentials" /inheritance:r /grant:r "SYSTEM:(R)" "Administrators:(R)" "User:(R)"
```

**Option B: Windows Credential Manager**

More secure but requires PowerShell integration:
```powershell
# Store (one-time setup)
cmdkey /generic:CambiumShop /user:shop_user /pass:shop_password
cmdkey /generic:CambiumRailway /user:cambium_sync /pass:WugWOsTpdDzUuS6Y4KuGCWTLFUuggOZH

# Retrieve in script (requires PowerShell wrapper)
```

**Recommendation:** Option A for simplicity. Option B if security audit requires it.

---

### Phase 3: Atomic Schema Reset (30 min)

**Goal:** Ensure Railway is never left in a half-broken state.

**Current (broken):**
```batch
"%PG_BIN%\psql" ... -c "REVOKE CONNECT; SELECT pg_terminate_backend(...); DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

**Proposed (atomic with rollback):**

Split into separate steps with state tracking:
```batch
REM ============================================
REM PHASE 2: Prepare Railway (atomic schema reset)
REM ============================================
set RAILWAY_PREP_STATE=0

echo %date% %time% - Blocking new connections... >> %LOG%
"%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% ^
    -c "REVOKE CONNECT ON DATABASE railway FROM PUBLIC;" >> %LOG% 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %date% %time% - REVOKE CONNECT failed >> %LOG%
    goto :cleanup_railway
)
set RAILWAY_PREP_STATE=1

echo %date% %time% - Terminating existing connections... >> %LOG%
"%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% ^
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'railway' AND pid <> pg_backend_pid();" >> %LOG% 2>&1
REM Note: This can return 0 rows (no connections to kill) - not an error

echo %date% %time% - Dropping public schema... >> %LOG%
"%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% ^
    -c "DROP SCHEMA IF EXISTS public CASCADE;" >> %LOG% 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %date% %time% - DROP SCHEMA failed >> %LOG%
    goto :cleanup_railway
)
set RAILWAY_PREP_STATE=2

echo %date% %time% - Creating fresh public schema... >> %LOG%
"%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% ^
    -c "CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO PUBLIC;" >> %LOG% 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %date% %time% - CREATE SCHEMA failed >> %LOG%
    goto :cleanup_railway
)
set RAILWAY_PREP_STATE=3
```

Add cleanup handler:
```batch
:cleanup_railway
if !RAILWAY_PREP_STATE! GEQ 1 (
    echo %date% %time% - Attempting to restore Railway access... >> %LOG%
    "%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% ^
        -c "GRANT CONNECT ON DATABASE railway TO PUBLIC;" >> %LOG% 2>&1
)
if exist %LOCKFILE% del %LOCKFILE%
exit /b 1
```

---

### Phase 4: Dynamic PK Discovery (45 min)

**Goal:** Automatically detect FK-referenced tables instead of hardcoding 69 PKs.

**Current (brittle):**
```batch
echo ALTER TABLE organizations ADD CONSTRAINT "PK_organizations" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE users ADD CONSTRAINT "PK_users" PRIMARY KEY (user_id); >> %PKSQL%
REM ... 67 more hardcoded lines ...
```

**Proposed (dynamic):**

Query cambium-server for current FK-referenced tables and generate SQL:
```batch
REM ============================================
REM PHASE 3b: Create PKs dynamically
REM ============================================
echo %date% %time% - Discovering FK-referenced tables... >> %LOG%

set PKSQL=C:\tmp\create-pks.sql
if exist %PKSQL% del %PKSQL%

REM Query cambium-server for all PK definitions of FK-referenced tables
set PGPASSWORD=%SHOP_PASSWORD%
"%PG_BIN%\psql" -U shop_user -p 5432 -d cambium -t -A -F";" -c ^
"SELECT 'ALTER TABLE ' || CASE WHEN c.relname ~ '[A-Z]' THEN '\"' || c.relname || '\"' ELSE c.relname END || ' ADD CONSTRAINT \"' || con.conname || '\" PRIMARY KEY (' || CASE WHEN a.attname ~ '[A-Z]' THEN '\"' || a.attname || '\"' ELSE a.attname END || ');' FROM pg_constraint con JOIN pg_class c ON con.conrelid = c.oid JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = ANY(con.conkey) WHERE con.contype = 'p' AND c.relnamespace = 'public'::regnamespace AND c.relname IN (SELECT DISTINCT c2.relname FROM pg_constraint fk JOIN pg_class c2 ON fk.confrelid = c2.oid WHERE fk.contype = 'f') ORDER BY c.relname;" > %PKSQL% 2>> %LOG%

if !ERRORLEVEL! NEQ 0 (
    echo %date% %time% - PK discovery failed >> %LOG%
    goto :cleanup_railway
)

REM Count discovered PKs
for /f %%A in ('type %PKSQL% ^| find /c /v ""') do set PKCOUNT=%%A
echo %date% %time% - Discovered !PKCOUNT! FK-referenced tables >> %LOG%

if !PKCOUNT! LSS 60 (
    echo %date% %time% - WARNING: Expected 60+ PKs, found !PKCOUNT! - possible schema issue >> %LOG%
)

REM Execute on Railway
set PGPASSWORD=%RAILWAY_PASS%
echo %date% %time% - Creating primary keys... >> %LOG%
"%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% -f %PKSQL% >> %LOG% 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %date% %time% - WARNING: Some PKs may have failed (expected if already exists) >> %LOG%
)
echo %date% %time% - Primary keys created (!PKCOUNT! tables) >> %LOG%
```

**Caveats:**
- Query handles PascalCase table/column names with quoting
- Single-column PKs only (composite PKs would need `array_agg`)
- Assumes local PG client can connect to local server

**Testing:**
1. Add new FK-referenced table to schema
2. Run sync
3. Verify new table's PK is auto-discovered and created

---

### Phase 5: Connection Timeout (10 min)

**Goal:** Fail fast on network issues instead of hanging.

**Implementation:**

Add to psql/pg_restore calls:
```batch
set PGOPTIONS=-c statement_timeout=60000
```

Or use connection string with timeout:
```batch
"%PG_BIN%\psql" "host=%RAILWAY_HOST% port=%RAILWAY_PORT% user=%RAILWAY_USER% dbname=%RAILWAY_DB% connect_timeout=30" ...
```

**Recommendation:** Use `connect_timeout=30` in connection parameters for all Railway connections.

---

### Phase 6: Log Rotation (15 min)

**Goal:** Prevent log file from growing unbounded.

**Implementation:**

Add at script start:
```batch
REM ============================================
REM Log rotation (keep 7 days)
REM ============================================
set LOG=C:\tmp\sync-log.txt
set LOG_MAX_SIZE=10485760
set LOG_ARCHIVE=C:\tmp\sync-log-%date:~-4,4%%date:~-7,2%%date:~-10,2%.txt

REM Rotate if log exceeds 10MB
for %%A in (%LOG%) do if %%~zA GEQ %LOG_MAX_SIZE% (
    echo Rotating log file... >> %LOG%
    move /Y %LOG% %LOG_ARCHIVE%
    echo %date% %time% - Log rotated, previous: %LOG_ARCHIVE% > %LOG%
)

REM Clean up logs older than 7 days
forfiles /P C:\tmp /M sync-log-*.txt /D -7 /C "cmd /c del @path" 2>nul
```

**Alternative:** Use Windows Event Log or external log aggregation.

---

### Phase 7: Conditional GRANT CONNECT (5 min)

**Goal:** Only re-enable connections if sync succeeded.

**Implementation:**

Track success state and only GRANT on success:
```batch
set SYNC_SUCCESS=0

REM ... all restore phases ...

REM Only if we reach here, sync succeeded
set SYNC_SUCCESS=1

:finish
REM ============================================
REM PHASE 4: Re-enable connections (only on success)
REM ============================================
if !SYNC_SUCCESS! EQU 1 (
    echo %date% %time% - Re-enabling connections... >> %LOG%
    "%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% ^
        -c "GRANT CONNECT ON DATABASE railway TO PUBLIC;" >> %LOG% 2>&1
    echo %date% %time% - Sync completed successfully >> %LOG%
) else (
    echo %date% %time% - Sync FAILED - connections remain blocked >> %LOG%
    REM Alert mechanism here (email, Slack, etc.)
)

if exist %LOCKFILE% del %LOCKFILE%
exit /b !SYNC_SUCCESS!
```

---

## Full Refactored Script Structure

```
sync-to-railway.cmd (v2.0)
├── Header
│   ├── @echo off / setlocal enabledelayedexpansion
│   ├── Load credentials from .sync-credentials
│   ├── Set variables (LOG, DUMP, RAILWAY_*, PG_BIN)
│   └── Log rotation
├── Lock acquisition
│   ├── Check for existing lock
│   ├── Verify PID still running
│   └── Create new lock
├── PHASE 1: Dump from cambium-server
│   ├── Set PGPASSWORD for local
│   ├── pg_dump with error check
│   └── Verify dump file exists
├── PHASE 2: Prepare Railway (atomic)
│   ├── REVOKE CONNECT (track state=1)
│   ├── pg_terminate_backend
│   ├── DROP SCHEMA IF EXISTS (track state=2)
│   ├── CREATE SCHEMA + GRANT (track state=3)
│   └── On failure: goto cleanup
├── PHASE 3: Restore pre-data
│   └── pg_restore --section=pre-data
├── PHASE 3b: Dynamic PK creation
│   ├── Query local DB for FK-referenced PKs
│   ├── Generate SQL file
│   ├── Execute on Railway
│   └── Log count + warnings
├── PHASE 3c: Restore data
│   └── pg_restore --section=data
├── PHASE 3d: Restore post-data
│   └── pg_restore --section=post-data
├── PHASE 4: Finalize
│   ├── If success: GRANT CONNECT
│   └── If failure: keep connections blocked
├── Cleanup
│   ├── Remove lock file
│   └── Exit with appropriate code
└── Error handler (:cleanup_railway)
    ├── Attempt to restore GRANT CONNECT
    ├── Remove lock file
    └── Exit with error
```

---

## Testing Plan

### Unit Tests (per phase)

| Phase | Test | Expected |
|-------|------|----------|
| 1 | Start sync, start second sync | Second exits with "already running" |
| 1 | Kill sync mid-run, start new sync | Stale lock detected, sync proceeds |
| 2 | Credentials file missing | Sync fails with clear error |
| 2 | Credentials file wrong permissions | (verify restricted access) |
| 3 | Kill network mid-DROP | GRANT CONNECT restored, clean exit |
| 4 | Add new FK-referenced table | Auto-discovered in next sync |
| 5 | Block Railway port | Timeout after 30s, not hang |
| 6 | Run 100 syncs | Log rotates at 10MB |
| 7 | pg_restore fails | Connections stay blocked |

### Integration Test

1. Back up cambium-server database
2. Deploy new script
3. Run sync, verify 0 FK warnings
4. Add new table with FK to existing table
5. Run sync, verify new PK auto-created
6. Simulate failure (kill Railway connection)
7. Verify Railway connections blocked, cleanup runs
8. Run sync again, verify recovery

---

## Rollback Plan

Keep original script as backup:
```batch
copy C:\tmp\sync-to-railway.cmd C:\tmp\sync-to-railway.cmd.v1-backup
```

If new script causes issues:
```batch
copy C:\tmp\sync-to-railway.cmd.v1-backup C:\tmp\sync-to-railway.cmd
```

---

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|------------|
| Lock file | Low | Simple file-based, no external deps |
| Credential file | Low | Permissions strictly set |
| Atomic schema reset | Medium | More failure points, but each is recoverable |
| Dynamic PK discovery | Medium | SQL query complexity; validate count |
| Connection timeout | Low | Standard PostgreSQL feature |
| Log rotation | Low | forfiles is built-in Windows |
| Conditional GRANT | Low | Only changes success path |

---

## Future Considerations (Out of Scope)

1. **Alerting:** Send notification on sync failure (Slack/email)
2. **Monitoring:** Prometheus metrics for sync duration/success
3. **Incremental sync:** Use logical replication instead of full dump/restore
4. **Multi-region:** Replicate to additional regions beyond Railway
5. **Scheduled task hardening:** Change to "Stop If Still Running: Enabled"

---

## Dependencies

- No new software required
- All changes use existing Windows/PostgreSQL tools
- Credentials file requires one-time admin setup

---

## Approval Checklist

- [ ] External review completed
- [ ] Credentials file created with correct permissions
- [ ] Original script backed up
- [ ] Test environment validated (or production with monitoring)
- [ ] Rollback plan understood

---

**This plan is ready for external review before execution. Copy to Claude.ai for adversarial review.**