# Connection Strings

## Three Configuration Files

| File | Purpose | ConnectionString Value |
|------|---------|------------------------|
| `appsettings.json` | Base/fallback | `Host=localhost;Port=5432;Database=cambium;Username=shop_user;Password=shop_password` |
| `appsettings.Development.json` | Local dev with Railway SSOT | `Host=trolley.proxy.rlwy.net;Port=44567;Database=railway;Username=postgres;Password=...` |
| `appsettings.Production.json` | Railway deployment | **None** — expects `DATABASE_URL` env var |

## How Railway Production Works

Railway always runs in `ASPNETCORE_ENVIRONMENT=Production`. The production appsettings has **no connection string** — this is intentional.

The app reads `DATABASE_URL` from the environment via explicit code (not EF Core convention):

**Location:** `Program.cs` lines 43-55

```csharp
string GetConnectionString(IConfiguration config)
{
    var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
    if (!string.IsNullOrEmpty(databaseUrl))
    {
        var uri = new Uri(databaseUrl);
        var userInfo = uri.UserInfo.Split(':');
        var user = userInfo[0];
        var password = userInfo.Length > 1 ? userInfo[1] : "";
        return $"Host={uri.Host};Port={uri.Port};Database={uri.AbsolutePath.TrimStart('/')};Username={user};Password={password};SSL Mode=Require;Trust Server Certificate=true";
    }
    return config.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("No connection string found");
}
```

**What this does:**
1. Checks for `DATABASE_URL` env var
2. Parses PostgreSQL URI format: `postgresql://user:password@host:port/database`
3. Reconstructs as Npgsql-compatible string with `SSL Mode=Require;Trust Server Certificate=true`
4. Falls back to `DefaultConnection` from config if env var not set

## The Variable Reference Rule

**DATABASE_URL in Railway Cambium Variables must always be `${{Postgres.DATABASE_URL}}`**

This is a Variable Reference — Railway resolves it to the actual connection string at runtime. When the Postgres password is regenerated (manually or by Railway), the reference automatically updates.

**Never set DATABASE_URL to a hardcoded string like:**
```
postgresql://postgres:abc123@postgres.railway.internal:5432/railway
```

This will break silently when the password rotates. You'll see `28P01 password authentication failed` errors in the logs.

### Checking the Current Value

1. Railway dashboard → Cambium service → Variables
2. Look for `DATABASE_URL`
3. The **Raw Value** should show `${{Postgres.DATABASE_URL}}`
4. The **Resolved Value** shows the actual connection string

### Fixing a Hardcoded String

1. Delete the current `DATABASE_URL` variable
2. Add a new variable: `DATABASE_URL` = `${{Postgres.DATABASE_URL}}`
3. Redeploy

## Internal vs Public Address

Railway provides two addresses:

| Address | Format | When to Use |
|---------|--------|-------------|
| Internal | `postgres.railway.internal:5432` | App running on Railway (same network) |
| Public | `trolley.proxy.rlwy.net:44567` | External access (dev machine, migrations) |

The internal address is preferred for production:
- No public hop (stays within Railway's network)
- Lower latency
- No connection pooling proxy overhead

`${{Postgres.DATABASE_URL}}` resolves to the internal address by default.

## The `cambium_sync` Role

`cambium_sync` is a PostgreSQL role with a **fixed password** that survives superuser password rotation.

**Status:** NOT used by the Cambium API. It's for external backup scripts only.

| Property | Value |
|----------|-------|
| Purpose | External backup/sync scripts |
| Password | `WugWOsTpdDzUuS6Y4KuGCWTLFUuggOZH` (fixed) |
| Used by API | No |
| Created on | Railway PostgreSQL |

**Where it's used:**
- Pi backup script (`/mnt/data/backups/cambium/backup-from-railway.sh`)
- Scheduled sync tasks on cambium-server

**If Railway DB is recreated:**
```sql
CREATE ROLE cambium_sync WITH LOGIN PASSWORD 'WugWOsTpdDzUuS6Y4KuGCWTLFUuggOZH' SUPERUSER;
```

## Local Development

**Default:** `appsettings.json` points to localhost:5432 (shop server when on VPN)

**Recommended:** `appsettings.Development.json` overrides to Railway production database. This means local dev uses the **same SSOT** as production — no sync needed.

To run locally against Railway:
```bash
cd Cambium/src/Cambium.Api
dotnet run
```

The Development environment loads `appsettings.Development.json` automatically.

## Common Issues

### 28P01 password authentication failed

**Cause:** `DATABASE_URL` is hardcoded and password was rotated

**Fix:** Set `DATABASE_URL = ${{Postgres.DATABASE_URL}}` and redeploy

### No connection string found

**Cause:** `DATABASE_URL` not set and `DefaultConnection` not in config

**Fix:** Ensure Railway Variables has `DATABASE_URL = ${{Postgres.DATABASE_URL}}`

### SSL connection required

**Cause:** Railway requires SSL but connection string missing SSL options

**Fix:** The `GetConnectionString()` helper adds `SSL Mode=Require;Trust Server Certificate=true` automatically. If you're connecting manually, add these options.

### Connection timeout from local machine

**Cause:** Using internal address (`postgres.railway.internal`) from outside Railway

**Fix:** Use the public address (`trolley.proxy.rlwy.net:44567`) for external connections
