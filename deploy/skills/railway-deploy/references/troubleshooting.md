# Railway .NET Troubleshooting

## Build Failures

### Duplicate appsettings.json

**Symptom:**
```
error NETSDK1152: Found multiple publish output files with the same relative path
```

**Cause:** Multiple projects in solution have `appsettings.json` (e.g., main API + background worker).

**Fix:** Add to `.csproj` or use CLI flag:
```xml
<PropertyGroup>
  <ErrorOnDuplicatePublishOutputFiles>false</ErrorOnDuplicatePublishOutputFiles>
</PropertyGroup>
```

Or in build command:
```bash
dotnet publish -c Release /p:ErrorOnDuplicatePublishOutputFiles=false
```

### .gitignore Excludes Source Folder

**Symptom:** Build fails because source files are missing from repo.

**Cause:** Common patterns like `data/` in .gitignore can exclude `Data/` folder on case-insensitive systems (Windows/macOS).

**Fix:** Rename the folder to avoid conflict:
```bash
git mv Data Persistence
# Update namespaces and using statements
```

### Nixpacks Detection Fails

**Symptom:** Railway doesn't detect .NET project.

**Fix:** Ensure `.sln` or `.csproj` is in repo root, or specify start command:
```bash
# In Railway service settings
dotnet YourApp.Api.dll
```

## Runtime Failures

### 502 Bad Gateway

**Checklist:**
1. Verify `ASPNETCORE_URLS=http://0.0.0.0:8080`
2. Check Railway logs for startup errors
3. Verify database connection string uses internal host for runtime
4. Check if migrations have run (tables exist)

### Database Connection Refused

**Internal vs External hosts:**
- **Runtime (in Railway):** `Host=postgres.railway.internal;Port=5432`
- **External (dev machine):** `Host=<proxy>.proxy.rlwy.net;Port=<external-port>`

Get external port from Railway dashboard → PostgreSQL service → Connect tab.

### Missing Tables / Relation Does Not Exist

**Symptom:**
```
42P01: relation "table_name" does not exist
```

**Cause:** EF Core migrations haven't run.

**Fix:** Generate and apply SQL script (see main SKILL.md).

## Migration Issues

### Column Mismatch After Migration

**Symptom:** Index creation fails because column doesn't exist:
```
42703: column "column_name" does not exist
```

**Cause:** EF-generated script assumes clean database but ran against partially-migrated DB.

**Fix:** Run targeted ALTER statements:
```sql
-- Add missing column
ALTER TABLE table_name ADD COLUMN column_name TEXT;

-- Then retry migration or manually create index
CREATE INDEX IF NOT EXISTS "IX_..." ON table_name (column_name);
```

### Timeout During Migration

**Symptom:** Gateway timeout (10s) kills migration command.

**Cause:** Railway/OpenClaw timeout limits.

**Fix:** Use background job or ApplyMigration tool:
```powershell
# PowerShell background job
Start-Job -Name 'Migrate' -ScriptBlock {
    cd C:\Path\To\Project
    dotnet ef database update
} | Out-Null
```

Check results later:
```powershell
Get-Job -Name 'Migrate' | Receive-Job
```

## Verification Queries

### Count Tables
```sql
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public';
```

### List Tables
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### Check Migrations Applied
```sql
SELECT migration_id FROM "__EFMigrationsHistory" 
ORDER BY migration_id DESC LIMIT 5;
```
