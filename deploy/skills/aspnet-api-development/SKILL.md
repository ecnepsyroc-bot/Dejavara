---
name: aspnet-api-development
description: >
  ASP.NET Core API patterns for Cambium. Use this skill when working on:
  authentication (JWT/Cookie), EF Core column-drift failures, self-healing
  startup patterns, Railway connection string parsing, DataProtection key
  persistence, or any ASP.NET Core middleware/endpoint work in the Cambium API.
  Triggers include: 401 errors, cookie not set, JWT invalid, column not found
  (42703), schema drift, DATABASE_URL parsing, DataProtection, MigrateAsync,
  Program.cs startup block. Architecture uses hexagonal terms: modules,
  adapters, ports, middleware.
---

# ASP.NET Core API Development (Cambium)

Cambium uses ASP.NET Core 8.0 with hexagonal architecture (modules, adapters, ports, middleware). PostgreSQL via Npgsql. Initialize or append to AUDIT.log before starting any implementation session.

## Smart PolicyScheme (Dual Auth)

Cambium uses a "Smart" PolicyScheme that selects JWT or Cookie based on the request's Authorization header:

```csharp
// Smart PolicyScheme — selects JWT or Cookie based on Authorization header
builder.Services.AddAuthentication("Smart")
    .AddPolicyScheme("Smart", "Smart", options =>
    {
        options.ForwardDefaultSelector = context =>
        {
            var header = context.Request.Headers[HeaderNames.Authorization].ToString();
            return header.StartsWith("Bearer ")
                 ? JwtBearerDefaults.AuthenticationScheme
                 : CookieAuthenticationDefaults.AuthenticationScheme;
        };
    })
    .AddJwtBearer(...)
    .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
    {
        options.Cookie.Name = "Cambium.Auth";
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.ExpireTimeSpan = TimeSpan.FromDays(30);
        options.SlidingExpiration = true;
        options.Events.OnRedirectToLogin = ctx =>
        {
            ctx.Response.StatusCode = 401;
            return Task.CompletedTask;
        };
    });
```

**Critical:** The `OnRedirectToLogin` override returns 401 instead of 302 redirect. Without this, API calls from SPA clients get redirect responses instead of auth errors.

## EF Core Column-Drift Failure Pattern (CRITICAL)

This is the most important failure mode to understand:

```
CRITICAL: EF Core generates SELECT with ALL mapped columns.
One missing column = entire query fails with PostgreSQL error 42703.
This kills every endpoint that queries that entity — not just the
one that needs the column.
```

**Failure chain:**
1. Entity has 14 columns mapped
2. EF generates `SELECT col1, col2, ... col14 FROM users`
3. Railway DB missing 1 column
4. PostgreSQL error 42703: `column "x" does not exist`
5. Every query against that entity fails
6. All related endpoints return generic 500
7. Error message: "An error occurred during login" — no indication it's schema

## Self-Healing Startup Pattern

**CORRECT:** Individual try/catch per ALTER — one failure doesn't skip the rest:

```csharp
string[] alters = [
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER NOT NULL DEFAULT 0",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS lockout_until TIMESTAMP WITH TIME ZONE",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT FALSE",
    // ... more columns
];
foreach (var alter in alters)
{
    try { await dbContext.Database.ExecuteSqlRawAsync(alter); }
    catch (Exception ex) { Log.Warning(ex, "Self-heal failed: {Sql}", alter); }
}
```

**WRONG:** Shared try/catch silently skips remaining ALTERs on first failure:

```csharp
// WRONG — if first fails, second never runs
try
{
    await dbContext.Database.ExecuteSqlRawAsync("ALTER TABLE ...");
    await dbContext.Database.ExecuteSqlRawAsync("ALTER TABLE ...");
}
catch { }
```

## Post-Heal Schema Verification

After self-healing ALTERs, verify all expected columns exist before proceeding:

```csharp
var expected = new[] { "id", "username", "password_hash", "failed_login_attempts",
    "lockout_until", "must_change_password", "user_type", "last_login_at", "last_seen",
    /* ... all mapped columns */ };
var actual = await dbContext.Database
    .SqlQueryRaw<string>(
        "SELECT column_name FROM information_schema.columns WHERE table_name = 'users'")
    .ToListAsync();
var missing = expected.Except(actual).ToList();
if (missing.Any())
    Log.Fatal("SCHEMA DRIFT: {Table} missing columns: {Missing}",
        "users", string.Join(", ", missing));
```

**Location in Program.cs:** Lines 644-674, after the ALTER TABLE loop, before admin seed.

## Railway Connection String Parsing

Railway injects `DATABASE_URL` as a URI. Cambium parses it explicitly:

```csharp
private static string GetConnectionString(IConfiguration config)
{
    var url = Environment.GetEnvironmentVariable("DATABASE_URL");
    if (!string.IsNullOrEmpty(url))
    {
        var uri = new Uri(url);
        return $"Host={uri.Host};Port={uri.Port};" +
               $"Database={uri.AbsolutePath.TrimStart('/')};" +
               $"Username={uri.UserInfo.Split(':')[0]};" +
               $"Password={uri.UserInfo.Split(':')[1]};" +
               $"SSL Mode=Require;Trust Server Certificate=true";
    }
    return config.GetConnectionString("Default")!;
}
```

**Critical:** `DATABASE_URL` in Railway Variables must be `${{Postgres.DATABASE_URL}}` (a Variable Reference), never a hardcoded connection string.

## Migration Management

Cambium has 117 migrations (date range 2025-12-23 to 2026-03-04). Cambium does **NOT** use `MigrateAsync()`.

```
NEVER add MigrateAsync() to Program.cs.
Earlier versions used MigrateAsync() which caused destructive schema recreation
on Railway. Migrations are tracked in __EFMigrationsHistory but NEVER auto-applied.
```

Apply migrations manually via SQL scripts or ALTER TABLE self-healing. See the `cambium-database-migrations` skill for full details.

## DataProtection Key Persistence

DataProtection keys must be persisted to the database. If the `DataProtectionKeys` table is missing (e.g., fresh Railway deploy), all existing cookies become invalid after restart — silent login failure for all users.

```csharp
builder.Services.AddDataProtection()
    .PersistKeysToDbContext<CambiumDbContext>()
    .SetApplicationName("Cambium");
```

## Key Code Locations

| Component | File | Lines |
|-----------|------|-------|
| Connection string parsing | `Program.cs` | 43-55 |
| PolicyScheme (JWT/Cookie) | `Program.cs` | 201-214 |
| Self-healing ALTERs | `Program.cs` | 622-642 |
| Schema verification | `Program.cs` | 644-674 |
| Admin seeding | `Program.cs` | 676-690+ |
| Login flow | `AuthController.cs` | 40-190 |
| JWT generation | `AuthController.cs` | 1226-1256 |
| Frontend authFetch | `wwwroot/app.js` | 383-396 |
