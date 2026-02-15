---
name: railway-deploy
description: Deploy .NET applications to Railway with PostgreSQL. Use when deploying ASP.NET Core / .NET 8 APIs, setting up Railway PostgreSQL, running EF Core migrations, or troubleshooting Railway build failures.
---

# Railway Deploy

Deploy .NET 8 applications to Railway's always-on hosting with PostgreSQL.

## Prerequisites

- Railway account (railway.app)
- GitHub repo connected to Railway
- Railway CLI or API token for advanced operations

## Quick Start

### 1. Create Project

```bash
# Via CLI
railway login
railway init

# Or connect existing GitHub repo via Railway dashboard
```

### 2. Add PostgreSQL

Railway dashboard → New → Database → PostgreSQL

Connection string format:
```
Host=<service>.railway.internal;Port=5432;Database=railway;Username=postgres;Password=<password>
```

For external access (migrations from dev machine):
```
Host=<proxy>.proxy.rlwy.net;Port=<port>;Database=railway;Username=postgres;Password=<password>
```

### 3. Configure Environment Variables

Required for .NET:
```
ASPNETCORE_URLS=http://0.0.0.0:8080
ASPNETCORE_ENVIRONMENT=Production
ConnectionStrings__DefaultConnection=<postgres-connection-string>
```

Railway expects port 8080. Set via dashboard → Service → Variables.

### 4. Deploy

Push to connected branch. Railway auto-builds via Nixpacks.

## .NET-Specific Configuration

### Dockerfile (optional, for control)

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
ENTRYPOINT ["dotnet", "YourApp.Api.dll"]
```

### Common Build Fixes

See [references/troubleshooting.md](references/troubleshooting.md) for detailed solutions.

| Issue | Quick Fix |
|-------|-----------|
| Duplicate appsettings.json | Add `/p:ErrorOnDuplicatePublishOutputFiles=false` to publish |
| .gitignore excludes folder | Rename `Data/` → `Persistence/` (case-insensitive conflict) |
| Port mismatch | Set `ASPNETCORE_URLS=http://0.0.0.0:8080` |
| 502 Bad Gateway | Check logs, verify PORT config, check DB connection |

## EF Core Migrations

Railway's 10s timeout prevents running `dotnet ef database update` directly.

### Option A: SQL Script Generation (Recommended)

```bash
# Generate SQL script locally
dotnet ef migrations script -i -o schema.sql --project YourApp.Api

# Apply via psql or Npgsql tool
psql "host=<proxy>.proxy.rlwy.net port=<port> dbname=railway user=postgres password=<pw>" -f schema.sql
```

### Option B: ApplyMigration Tool

Create a simple console app with Npgsql:

```csharp
using Npgsql;

var conn = new NpgsqlConnection(connectionString);
await conn.OpenAsync();
var sql = File.ReadAllText("schema.sql");
await new NpgsqlCommand(sql, conn) { CommandTimeout = 600 }.ExecuteNonQueryAsync();
```

### Multiple DbContexts

Generate separate scripts for each context:
```bash
dotnet ef migrations script -i -o main_schema.sql --context MainDbContext
dotnet ef migrations script -i -o staging_schema.sql --context StagingDbContext
```

## Verifying Deployment

```bash
# Check health
curl -s -o /dev/null -w "%{http_code}" https://your-app.up.railway.app/swagger/index.html

# Check API
curl https://your-app.up.railway.app/api/health

# Check database tables
# Use psql or a quick Npgsql script to count tables
```

## Railway CLI Reference

```bash
railway login                    # Authenticate
railway init                     # Initialize project
railway up                       # Deploy current directory
railway logs                     # View logs
railway run <cmd>                # Run command in Railway env
railway variables                # List environment variables
railway variables set KEY=VALUE  # Set variable
```

## Database Sync & Verification

After syncing from external source (pg_dump/pg_restore):

### Post-Sync Verification

Always verify critical columns exist after restore:
```sql
-- Check expected columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'your_table';

-- Check table counts
SELECT schemaname, relname, n_live_tup 
FROM pg_stat_user_tables 
ORDER BY n_live_tup DESC;
```

### Column Drift (Common Issue)

**Symptom:** API returns 500 error, logs show "column X does not exist"

**Cause:** 
- Custom columns added after initial migration not in dump
- Restore from older backup
- EF Migration applied to source but not replica

**Fix:**
```sql
ALTER TABLE your_table ADD COLUMN IF NOT EXISTS column_name type;
```

**Prevention:**
1. Always sync from SSOT (source of truth) with ALL columns
2. Run `dotnet ef migrations script` to see expected schema
3. Create post-sync verification query for critical columns

### Direct SQL Without psql

See `postgres-remote-ops` skill for executing SQL when psql isn't installed.

## Cost Notes

- PostgreSQL: ~$5/month minimum
- Compute: Pay for usage, ~$5-20/month for light APIs
- Free tier: 500 hours/month (not always-on)

## Free Plan Limitations

- **No automated backups** — sync from external source required
- **Limited connections** — kill connections before bulk operations
- **Compute limits** — may sleep after inactivity
